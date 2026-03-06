"""
FastAPI 主应用
跬步千里 - AI 服务
"""
import uvicorn
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from app.api.endpoints import motion_generator, posture_detection

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# 创建 FastAPI 应用实例
app = FastAPI(
    title="跬步千里 AI 服务",
    description="微运动健康管理系统 AI 服务 API",
    version="1.0.0",
    default_response_class=JSONResponse
)

# 配置 CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(
    motion_generator.router,
    prefix="/api/motion",
    tags=["微运动生成"]
)

app.include_router(
    posture_detection.router,
    prefix="/api/posture",
    tags=["姿态检测"]
)


@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "跬步千里 AI 服务",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
