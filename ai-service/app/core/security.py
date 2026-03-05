"""
安全相关功能
"""
from typing import Optional
from fastapi import Security, HTTPException, status
from fastapi.security import APIKeyHeader

# API Key 认证（如需要）
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


async def verify_api_key(api_key: Optional[str] = Security(api_key_header)):
    """
    验证 API Key
    
    在生产环境中，应该从数据库或配置中验证 API Key
    """
    if not api_key:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="缺少 API Key"
        )
    
    # TODO: 实现实际的 API Key 验证逻辑
    # 这里只是示例
    valid_keys = ["your_api_key_here"]
    if api_key not in valid_keys:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="无效的 API Key"
        )
    
    return api_key
