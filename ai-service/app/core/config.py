"""
应用配置
"""
from pydantic_settings import BaseSettings
from typing import Optional


class Settings(BaseSettings):
    """应用配置"""
    
    # 应用配置
    app_name: str = "跬步千里 AI 服务"
    app_version: str = "1.0.0"
    debug: bool = True
    
    # 服务器配置
    host: str = "0.0.0.0"
    port: int = 8000
    
    # CORS 配置
    cors_origins: list[str] = ["*"]
    
    # AI 模型配置
    ai_model_url: Optional[str] = None
    ai_api_key: Optional[str] = None

    # 后端服务配置
    backend_api_base_url: str = "http://127.0.0.1:8080/api"
    
    # 数据库配置（如需要）
    database_url: Optional[str] = None
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


# 全局配置实例
settings = Settings()
