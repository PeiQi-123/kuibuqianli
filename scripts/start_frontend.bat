@echo off
echo ========================================
echo 启动跬步千里前端应用
echo ========================================
cd /d %~dp0\..\frontend
echo 当前目录: %CD%
echo.
echo 检查 Flutter 环境...
flutter --version
if errorlevel 1 (
    echo [错误] 未找到 Flutter，请先安装 Flutter SDK
    pause
    exit /b 1
)
echo.
echo 安装依赖...
flutter pub get
if errorlevel 1 (
    echo [错误] 依赖安装失败
    pause
    exit /b 1
)
echo.
echo 开始启动前端应用...
echo 请选择运行设备（Android/iOS/Web/Windows）
echo.
flutter run
pause
