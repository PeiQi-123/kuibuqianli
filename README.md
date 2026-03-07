# 跬步千里 - 微运动健康管理系统

> 一个基于 AI 的个性化微运动健康管理平台，帮助用户在工作间隙进行科学有效的微运动。

## ✨ 项目简介

**跬步千里** 是一个全栈微运动健康管理系统，通过 AI 技术为用户提供个性化的微运动方案和实时姿态检测，帮助久坐人群在工作间隙进行科学有效的运动。

### 核心功能

- 🏃 **个性化微运动生成** - 基于用户活动类型和偏好生成定制化运动方案
- 📹 **AI 视频指导** - 自动生成运动指导视频
- 🎯 **实时姿态检测** - 检测用户运动姿态并提供改进建议
- 📊 **健康数据管理** - 记录和分析用户的运动数据
- 🔐 **用户系统** - 完整的注册、登录和用户信息管理
- 📱 **多平台支持** - 支持 iOS、Android、Web 和 Windows

## 🏗️ 技术架构

### 后端服务 (`backend/`)
- **框架**: Spring Boot 3.1.6
- **语言**: Java 17
- **数据库**: MySQL 8.0+
- **ORM**: MyBatis Plus
- **安全**: Spring Security + JWT
- **API 文档**: SpringDoc OpenAPI (Swagger)

### 前端应用 (`frontend/`)
- **框架**: Flutter 3.0+
- **语言**: Dart
- **状态管理**: Provider
- **路由**: go_router
- **图表**: fl_chart

### AI 服务 (`ai-service/`)
- **框架**: FastAPI
- **语言**: Python 3.8+
- **功能**: 微运动生成、姿态检测、视频生成

## 🚀 快速开始

### 前置要求

- JDK 17+
- Maven 3.6+
- Python 3.8+
- Flutter 3.0+
- MySQL 8.0+

### 快速启动

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd kuibuqianli
   ```

2. **配置数据库**
   ```sql
   CREATE DATABASE kuibuqianli CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   ```

3. **启动服务**

   **Windows 用户**（推荐）:
   ```bash
   # 启动 AI 服务
   scripts\start_ai_service.bat
   
   # 启动后端服务
   scripts\start_backend.bat
   
   # 启动前端应用
   scripts\start_frontend.bat
   ```

   **手动启动**:
   ```bash
   # AI 服务
   cd ai-service
   python -m venv venv
   venv\Scripts\activate  # Windows
   pip install -r requirements.txt
   uvicorn app.main:app --reload --port 8000
   
   # 后端服务
   cd backend
   mvn spring-boot:run
   
   # 前端应用
   cd frontend
   flutter pub get
   flutter run
   ```

### 访问地址

- **前端应用**: 根据 Flutter 运行平台而定
- **后端 API**: http://localhost:8080/api
- **后端 API 文档**: http://localhost:8080/api/swagger-ui.html
- **AI 服务**: http://localhost:8000
- **AI 服务文档**: http://localhost:8000/docs

## 📚 文档

- [快速开始指南](QUICKSTART.md) - 5 分钟快速启动项目
- [开发指南](DEVELOPMENT.md) - 详细的开发环境搭建和开发流程

## 📁 项目结构

```
kuibuqianli/
├── backend/              # Spring Boot 后端服务
│   ├── src/
│   │   └── main/
│   │       ├── java/     # Java 源代码
│   │       └── resources/ # 配置文件
│   └── pom.xml           # Maven 配置
├── frontend/             # Flutter 前端应用
│   ├── lib/              # Dart 源代码
│   └── pubspec.yaml      # Flutter 依赖配置
├── ai-service/           # Python FastAPI AI 服务
│   ├── app/              # Python 源代码
│   └── requirements.txt  # Python 依赖
├── database/             # 数据库脚本
│   └── init/             # 初始化脚本
├── docker/               # Docker 配置
├── scripts/              # 启动脚本
├── DEVELOPMENT.md        # 开发指南
└── QUICKSTART.md         # 快速开始指南
```

## 🔧 开发

### 环境配置

详细的环境配置和开发流程请参考 [开发指南](DEVELOPMENT.md)。

### 代码规范

- **Java**: 遵循 Google Java Style Guide
- **Dart**: 遵循 Dart Style Guide  
- **Python**: 遵循 PEP 8

### Git 提交规范

```
feat: 新功能
fix: 修复 bug
docs: 文档更新
style: 代码格式调整
refactor: 代码重构
test: 测试相关
chore: 构建/工具相关
```

## 🐛 常见问题

### 端口被占用
修改配置文件中的端口号或停止占用端口的进程。

### 数据库连接失败
1. 检查 MySQL 服务是否启动
2. 验证数据库配置是否正确
3. 确认数据库已创建

### 依赖安装失败
- **Maven**: 检查网络连接，配置镜像源
- **Flutter**: 运行 `flutter clean && flutter pub get`
- **Python**: 使用国内镜像源 `pip install -i https://pypi.tuna.tsinghua.edu.cn/simple`

更多问题请查看 [开发指南](DEVELOPMENT.md) 中的常见问题部分。

## 📝 许可证

[待添加]

## 👥 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 联系方式

[待添加]

---

**祝开发愉快！** 🎉
