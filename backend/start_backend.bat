@echo off
echo 启动跬步千里后端服务...
echo 端口: 8081
echo.

cd /d "C:\Users\30698\Desktop\mifar\kuibuqianli\backend"

REM 检查Java是否安装
where java >nul 2>nul
if %errorlevel% neq 0 (
    echo 错误: Java未安装或未添加到PATH
    pause
    exit /b 1
)

REM 检查Maven是否安装
where mvn >nul 2>nul
if %errorlevel% neq 0 (
    echo 警告: Maven未安装，尝试直接运行...
    if exist target\classes\com\kuibuqianli\KuibuQianliApplication.class (
        echo 使用已编译的类文件启动...
        java -cp "target/classes;target/dependency/*" com.kuibuqianli.KuibuQianliApplication
    ) else (
        echo 错误: 没有找到已编译的类文件
        echo 请先运行: mvn clean compile
        pause
        exit /b 1
    )
) else (
    echo 使用Maven启动Spring Boot应用...
    mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8081
)

pause