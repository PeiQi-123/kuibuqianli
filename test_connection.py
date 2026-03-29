#!/usr/bin/env python3
import requests
import time
import sys

def test_backend():
    """测试后端服务连接"""
    urls = [
        "http://localhost:8081/api/health",
        "http://localhost:8081/api/user/info",
        "http://10.27.246.204:8081/api/health",
        "http://10.27.246.204:8081/api/user/info"
    ]
    
    print("=== 测试后端服务连接 ===")
    print(f"当前时间: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    for url in urls:
        try:
            print(f"测试: {url}")
            response = requests.get(url, timeout=5)
            print(f"  状态码: {response.status_code}")
            print(f"  响应: {response.text[:100]}...")
        except requests.exceptions.ConnectionError:
            print(f"  错误: 连接失败 - 服务未启动或网络问题")
        except requests.exceptions.Timeout:
            print(f"  错误: 请求超时")
        except Exception as e:
            print(f"  错误: {type(e).__name__}: {e}")
        print()

def test_frontend_api():
    """测试前端API配置"""
    print("=== 测试前端API配置 ===")
    
    # 模拟前端API调用
    test_data = {
        "username": "test",
        "password": "test123"
    }
    
    base_urls = [
        "http://localhost:8081/api",
        "http://10.27.246.204:8081/api"
    ]
    
    for base_url in base_urls:
        try:
            url = f"{base_url}/auth/login"
            print(f"测试登录API: {url}")
            response = requests.post(url, json=test_data, timeout=5)
            print(f"  状态码: {response.status_code}")
            if response.status_code != 200:
                print(f"  响应: {response.text[:200]}")
        except Exception as e:
            print(f"  错误: {type(e).__name__}: {e}")
        print()

if __name__ == "__main__":
    print("开始测试...")
    print("=" * 50)
    
    test_backend()
    print("=" * 50)
    test_frontend_api()
    
    print("测试完成！")
    print("建议:")
    print("1. 确保后端服务已启动 (端口8081)")
    print("2. 检查防火墙设置")
    print("3. 确认IP地址正确: 10.27.246.204")
    print("4. 前端使用正确的API地址: http://10.27.246.204:8081/api")