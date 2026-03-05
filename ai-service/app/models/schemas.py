"""
数据模型定义
"""
from pydantic import BaseModel
from typing import Optional, List


class MotionSchema(BaseModel):
    """微运动数据模型"""
    motion_id: str
    motion_name: str
    description: str
    duration: int
    steps: List[str]
    video_url: Optional[str] = None


class PostureSchema(BaseModel):
    """姿态数据模型"""
    posture_type: str
    confidence: float
    key_points: Optional[List[dict]] = None
