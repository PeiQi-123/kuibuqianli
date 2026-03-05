"""
微运动生成API端点
"""
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional

router = APIRouter()


class MotionRequest(BaseModel):
    """微运动生成请求"""
    activity_type: str  # 活动类型，如 "久坐"、"工作"、"休息"
    duration: int = 5  # 运动时长（分钟）
    intensity: str = "low"  # 强度：low, medium, high
    user_preference: Optional[str] = None  # 用户偏好


class MotionResponse(BaseModel):
    """微运动生成响应"""
    motion_id: str
    motion_name: str
    description: str
    duration: int
    steps: list[str]
    video_url: Optional[str] = None


@router.post("/generate", response_model=MotionResponse)
async def generate_motion(request: MotionRequest):
    """
    生成微运动方案
    
    - **activity_type**: 用户当前活动类型
    - **duration**: 运动时长（分钟）
    - **intensity**: 运动强度
    - **user_preference**: 用户偏好设置
    """
    try:
        # TODO: 实现实际的 AI 模型调用逻辑
        # 这里返回示例数据
        return MotionResponse(
            motion_id="motion_001",
            motion_name="办公室拉伸运动",
            description="适合久坐人群的5分钟拉伸运动",
            duration=request.duration,
            steps=[
                "1. 颈部左右转动，每个方向10次",
                "2. 肩部前后绕环，各10次",
                "3. 腰部左右扭转，各10次",
                "4. 腿部拉伸，每条腿30秒",
                "5. 深呼吸放松，持续1分钟"
            ],
            video_url=None
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"生成微运动失败: {str(e)}")


@router.get("/list")
async def list_motions(activity_type: Optional[str] = None):
    """
    获取微运动列表
    
    - **activity_type**: 可选，按活动类型筛选
    """
    # TODO: 实现从数据库或配置中获取微运动列表
    return {
        "motions": [
            {
                "id": "motion_001",
                "name": "办公室拉伸运动",
                "activity_type": "久坐",
                "duration": 5
            }
        ]
    }
