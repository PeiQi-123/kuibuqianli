@echo off
setlocal enabledelayedexpansion

REM ===========================================
REM 微运动API测试脚本 (Windows版本)
REM 测试DeepSeek API集成是否正常工作
REM ===========================================

set API_BASE=http://localhost:8080/api/micro-motion
set TIMEOUT=30

echo ========== 微运动API测试脚本 ==========
echo.

REM 检查服务是否可用
echo [INFO] 检查服务健康状态...
curl -s -o nul -w "HTTP状态码: %%{http_code}\n" %API_BASE%/health

if %errorlevel% neq 0 (
    echo [ERROR] 服务不可用，请确保后端服务已启动
    echo [WARNING] 启动命令: cd backend ^&^& mvn spring-boot:run
    goto :end
)

echo [SUCCESS] 服务运行正常
echo.

REM 测试1: 颈部问题
echo ==========================================
echo [INFO] 测试1: 颈部问题 - 年轻人
echo ==========================================

curl -X POST %API_BASE%/generate-prompt ^
  -H "Content-Type: application/json" ^
  -d "{\"body_part\":\"颈部\",\"posture_info\":\"长时间低头看手机，坐姿不正确，感觉颈部僵硬\",\"user_info\":{\"age\":25,\"gender\":\"男\",\"height\":175,\"weight\":70,\"bmi\":22.9,\"bmi_type\":\"正常\"}}"

echo.
echo.
timeout /t 2 /nobreak > nul

REM 测试2: 腰部问题
echo ==========================================
echo [INFO] 测试2: 腰部问题 - 中年人偏胖
echo ==========================================

curl -X POST %API_BASE%/generate-prompt ^
  -H "Content-Type: application/json" ^
  -d "{\"body_part\":\"腰部\",\"posture_info\":\"久坐办公，腰部酸疼，起身时感觉僵硬\",\"user_info\":{\"age\":45,\"gender\":\"男\",\"height\":170,\"weight\":80,\"bmi\":27.7,\"bmi_type\":\"偏胖\"}}"

echo.
echo.
timeout /t 2 /nobreak > nul

REM 测试3: 肩部问题
echo ==========================================
echo [INFO] 测试3: 肩部问题 - 女性正常
echo ==========================================

curl -X POST %API_BASE%/generate-prompt ^
  -H "Content-Type: application/json" ^
  -d "{\"body_part\":\"肩部\",\"posture_info\":\"圆肩驼背，长时间用电脑，肩膀酸痛\",\"user_info\":{\"age\":32,\"gender\":\"女\",\"height\":165,\"weight\":55,\"bmi\":20.2,\"bmi_type\":\"正常\"}}"

echo.
echo.
timeout /t 2 /nobreak > nul

REM 测试4: 眼部问题
echo ==========================================
echo [INFO] 测试4: 眼部问题 - 老年人
echo ==========================================

curl -X POST %API_BASE%/generate-prompt ^
  -H "Content-Type: application/json" ^
  -d "{\"body_part\":\"眼睛\",\"posture_info\":\"长时间看屏幕，眼睛干涩疲劳\",\"user_info\":{\"age\":55,\"gender\":\"女\",\"height\":160,\"weight\":60,\"bmi\":23.4,\"bmi_type\":\"正常\"}}"

echo.
echo.
timeout /t 2 /nobreak > nul

REM 测试5: 手腕问题
echo ==========================================
echo [INFO] 测试5: 手腕问题 - 程序员
echo ==========================================

curl -X POST %API_BASE%/generate-prompt ^
  -H "Content-Type: application/json" ^
  -d "{\"body_part\":\"手腕\",\"posture_info\":\"长时间打字，手腕酸痛\",\"user_info\":{\"age\":28,\"gender\":\"男\",\"height\":180,\"weight\":75,\"bmi\":23.1,\"bmi_type\":\"正常\",\"occupation\":\"程序员\"}}"

echo.
echo.

:end
echo ==========================================
echo [INFO] 测试完成！
echo ==========================================

pause