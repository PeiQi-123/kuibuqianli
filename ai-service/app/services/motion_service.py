"""
微运动生成服务
"""
from typing import Optional

import httpx

from app.core.config import settings


class MotionService:
    """微运动生成服务类"""
    
    def __init__(self):
        self.backend_api_base_url = settings.backend_api_base_url.rstrip("/")
    
    def generate_motion(
        self,
        activity_type: str,
        duration: int = 5,
        intensity: str = "low",
        user_preference: Optional[str] = None,
        user_profile: Optional[dict] = None,
    ) -> dict:
        """
        生成微运动方案
        
        Args:
            activity_type: 活动类型
            duration: 运动时长（分钟）
            intensity: 运动强度
            user_preference: 用户偏好
            
        Returns:
            微运动方案字典
        """
        body_part = self._infer_body_part(activity_type, user_preference)
        posture_info = self._build_posture_info(activity_type, duration, intensity, user_preference)
        profile = {
            key: value
            for key, value in (user_profile or {}).items()
            if value is not None and value != ""
        }
        payload = {
            "body_part": body_part,
            "posture_info": posture_info,
            "user_info": {
                "preferred_activity_type": activity_type,
                "preferred_intensity": intensity,
                "preferred_duration_minutes": duration,
                **profile,
            },
        }

        try:
            with httpx.Client(timeout=60.0) as client:
                response = client.post(
                    f"{self.backend_api_base_url}/micro-motion/generate-prompt",
                    json=payload,
                )
                response.raise_for_status()
                data = response.json()
        except httpx.HTTPError as exc:
            raise RuntimeError(f"调用后端 AI 接口失败: {exc}") from exc

        if data.get("status") != "success":
            message = data.get("error_message") or "后端 AI 接口未返回成功结果"
            raise RuntimeError(message)

        prompt_text = data.get("prompt_text", "")
        return {
            "motion_id": f"ai_{body_part}_{activity_type}",
            "motion_name": f"{body_part}微运动方案",
            "description": f"基于真实 AI 生成的{activity_type}场景{duration}分钟{self._map_intensity_label(intensity)}建议",
            "duration": duration,
            "steps": self._extract_steps(prompt_text),
            "video_url": None,
        }

    def _infer_body_part(self, activity_type: str, user_preference: Optional[str]) -> str:
        if user_preference:
            preference = user_preference.strip()
            if preference:
                return preference

        mapping = {
            "久坐": "颈部",
            "工作": "肩部",
            "休息": "腰部",
            "学习": "背部",
        }
        return mapping.get(activity_type, "颈部")

    def _build_posture_info(
        self,
        activity_type: str,
        duration: int,
        intensity: str,
        user_preference: Optional[str],
    ) -> str:
        preference_text = f"，用户偏好关注{user_preference}" if user_preference else ""
        return (
            f"当前场景为{activity_type}，预计进行{duration}分钟微运动，"
            f"强度偏好为{self._map_intensity_label(intensity)}{preference_text}。"
        )

    def _map_intensity_label(self, intensity: str) -> str:
        mapping = {
            "low": "低强度",
            "medium": "中强度",
            "high": "高强度",
        }
        return mapping.get(intensity, intensity)

    def _extract_steps(self, prompt_text: str) -> list[str]:
        lines = [line.strip() for line in prompt_text.splitlines() if line.strip()]
        return lines[:12] if lines else ["AI 未返回可展示的步骤内容"]
