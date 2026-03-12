@echo off
chcp 65001 >nul
set "JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8 %JAVA_TOOL_OPTIONS%"
set "MAVEN_OPTS=-Dfile.encoding=UTF-8 %MAVEN_OPTS%"
echo ========================================
echo 启动跬步千里后端服务
echo ========================================
cd /d %~dp0\..\backend
echo 当前目录: %CD%
echo.
echo 检查 Java 环境...
java -version
if errorlevel 1 (
    echo [错误] 未找到 Java，请先安装 JDK 17
    pause
    exit /b 1
)
echo.
echo 检查 Maven 环境...
mvn -version
if errorlevel 1 (
    echo [错误] 未找到 Maven，请先安装 Maven
    pause
    exit /b 1
)
echo.
echo 开始启动后端服务...
echo 服务将在 http://localhost:8080/api 启动
echo API 文档: http://localhost:8080/api/swagger-ui.html
echo 控制台编码: UTF-8
echo.
mvn spring-boot:run
pause
