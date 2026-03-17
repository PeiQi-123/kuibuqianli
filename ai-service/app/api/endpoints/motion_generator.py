"""
微运动生成API端点
"""
from fastapi import APIRouter, HTTPException, Form
from pydantic import BaseModel, Field
from typing import Optional, List, Literal
import logging
import sys

from app.services.motion_service import MotionService

# 配置日志输出到 stdout
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)

logger = logging.getLogger()
logger.setLevel(logging.INFO)

router = APIRouter()
motion_service = MotionService()


class MotionRequest(BaseModel):
    """微运动生成请求"""
    activity_type: Literal["久坐", "工作", "学习", "休息"] = Field(
        default="久坐",
        description="你当前的场景。一般选最接近现在状态的即可。",
        examples=["久坐"],
    )
    duration: int = Field(
        default=5,
        ge=3,
        le=20,
        description="你希望这组微运动持续多久，单位是分钟。推荐 5。",
        examples=[5],
    )
    intensity: Literal["low", "medium", "high"] = Field(
        default="low",
        description="运动强度：low=轻松放松，medium=适中激活，high=更有挑战。",
        examples=["low"],
    )
    user_preference: Optional[str] = Field(
        default=None,
        description="可选。填你想重点缓解的部位或诉求，例如：颈部、肩部、腰部、肩颈放松。",
        examples=["颈部"],
    )
    age: Optional[int] = Field(
        default=None,
        ge=1,
        le=120,
        description="可选。年龄，填了以后 AI 会更准确地控制动作难度。",
        examples=[24],
    )
    gender: Optional[str] = Field(
        default=None,
        description="可选。性别，例如：男、女。",
        examples=["男"],
    )
    height: Optional[float] = Field(
        default=None,
        gt=0,
        description="可选。身高，单位厘米，例如 175。",
        examples=[175],
    )
    weight: Optional[float] = Field(
        default=None,
        gt=0,
        description="可选。体重，单位千克，例如 70。",
        examples=[70],
    )
    bmi: Optional[float] = Field(
        default=None,
        gt=0,
        description="可选。BMI 数值，例如 22.9。",
        examples=[22.9],
    )
    bmi_type: Optional[str] = Field(
        default=None,
        description="可选。BMI 分类，例如：正常、偏胖、偏瘦。",
        examples=["正常"],
    )

    model_config = {
        "json_schema_extra": {
            "description": (
                "怎么用：先点 `Try it out`，把下面的示例直接复制进去，再点 `Execute`。"
                "\n\n第一次使用时，只填前 4 个字段就够了：`activity_type`、`duration`、`intensity`、`user_preference`。"
                "\n如果你愿意，再补充年龄、身高、体重、BMI，AI 会给出更贴合身体情况的建议。"
            ),
            "examples": [
                {
                    "title": "新手最简示例",
                    "description": "第一次使用就填这几个，最容易成功。",
                    "activity_type": "久坐",
                    "duration": 5,
                    "intensity": "low",
                    "user_preference": "颈部"
                },
                {
                    "title": "更个性化示例",
                    "description": "补充身体信息后，AI 建议会更准确。",
                    "activity_type": "久坐",
                    "duration": 5,
                    "intensity": "low",
                    "user_preference": "颈部",
                    "age": 24,
                    "gender": "男",
                    "height": 175,
                    "weight": 70,
                    "bmi": 22.9,
                    "bmi_type": "正常"
                }
            ]
        }
    }


class MotionResponse(BaseModel):
    """微运动生成响应"""
    motion_id: str
    motion_name: str
    description: str
    duration: int
    steps: List[str]
    video_url: Optional[str] = None


@router.post(
    "/generate",
    response_model=MotionResponse,
    summary="先复制示例，再点执行",
    description=(
        "这是 JSON 版页面。最简单的用法："
        "\n\n1. 点 `Try it out`"
        "\n2. 把请求体改成下面这段："
        "\n```json"
        "\n{"
        "\n  \"activity_type\": \"久坐\","
        "\n  \"duration\": 5,"
        "\n  \"intensity\": \"low\","
        "\n  \"user_preference\": \"颈部\""
        "\n}"
        "\n```"
        "\n3. 点 `Execute`"
        "\n\n如果你想让 AI 更个性化，再补充 `age`、`height`、`weight`、`bmi` 等字段。"
        "\n如果你不想手写 JSON，请改用下面的 `POST /api/motion/generate-easy`。"
    ),
    responses={
        200: {"description": "生成成功，会返回动作名称、简介和步骤列表。"},
        500: {"description": "生成失败。通常是后端真实 AI 服务不可用，或请求内容异常。"}
    }
)
async def generate_motion(request: MotionRequest):
    """生成微运动方案。"""
    logger.info(
        "收到请求: activity_type=%s, duration=%s, intensity=%s",
        request.activity_type,
        request.duration,
        request.intensity,
    )
    try:
        result = MotionResponse(**motion_service.generate_motion(
            activity_type=request.activity_type,
            duration=request.duration,
            intensity=request.intensity,
            user_preference=request.user_preference,
            user_profile={
                "age": request.age,
                "gender": request.gender,
                "height": request.height,
                "weight": request.weight,
                "bmi": request.bmi,
                "bmi_type": request.bmi_type,
            },
        ))
        logger.info(f"返回结果: {result.dict()}")
        return result
    except Exception as e:
        logger.error(f"生成微运动失败: {str(e)}")
        raise HTTPException(status_code=500, detail=f"生成微运动失败: {str(e)}")


@router.post(
    "/generate-easy",
    response_model=MotionResponse,
    summary="新手填空版：生成真实 AI 微运动方案",
    description=(
        "这是给新手准备的填空版接口。你不需要手写 JSON，只要在 Swagger 页面里一格一格填写即可。"
        "\n\n最少只填这 4 项就能用："
        "\n1. 当前状态"
        "\n2. 运动时长"
        "\n3. 运动强度"
        "\n4. 想重点缓解哪里"
        "\n\n年龄、身高、体重、BMI 都是选填；填了会更个性化。"
    ),
)
async def generate_motion_easy(
    activity_type: Literal["久坐", "工作", "学习", "休息"] = Form(
        default="久坐",
        description="你当前的状态。不会选就用默认的 `久坐`。",
    ),
    duration: int = Form(
        default=5,
        description="这次想活动几分钟。新手推荐 5。",
    ),
    intensity: Literal["low", "medium", "high"] = Form(
        default="low",
        description="运动强度。新手推荐 `low`。",
    ),
    user_preference: Optional[str] = Form(
        default="颈部",
        description="你最想缓解的部位，比如：颈部、肩部、腰部。",
    ),
    age: Optional[int] = Form(default=None, description="可选。年龄。"),
    gender: Optional[str] = Form(default=None, description="可选。性别，比如：男、女。"),
    height: Optional[float] = Form(default=None, description="可选。身高，单位厘米，例如 175。"),
    weight: Optional[float] = Form(default=None, description="可选。体重，单位千克，例如 70。"),
    bmi: Optional[float] = Form(default=None, description="可选。BMI 数值，例如 22.9。"),
    bmi_type: Optional[str] = Form(default=None, description="可选。BMI 分类，例如：正常、偏胖、偏瘦。"),
):
    logger.info(
        "收到填空版请求: activity_type=%s, duration=%s, intensity=%s",
        activity_type,
        duration,
        intensity,
    )
    try:
        result = MotionResponse(**motion_service.generate_motion(
            activity_type=activity_type,
            duration=duration,
            intensity=intensity,
            user_preference=user_preference,
            user_profile={
                "age": age,
                "gender": gender,
                "height": height,
                "weight": weight,
                "bmi": bmi,
                "bmi_type": bmi_type,
            },
        ))
        logger.info(f"填空版返回结果: {result.dict()}")
        return result
    except Exception as e:
        logger.error(f"填空版生成微运动失败: {str(e)}")
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
