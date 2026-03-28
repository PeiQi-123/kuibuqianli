# 跬步千里

> 一个面向久坐人群的微运动健康管理系统。项目以 Flutter 为用户端、Spring Boot 为核心业务后端、MySQL 为数据底座，围绕“久坐提醒 -> 个性化推荐 -> 视频跟练 -> 反馈学习”构建闭环。

## 项目定位

**跬步千里** 不是单纯的动作展示应用，而是一个带推荐闭环的微运动系统。当前代码已经具备以下主链路：

1. 用户登录并完善身体信息、运动偏好
2. 系统根据目标部位、历史偏好、近期反馈、特殊情况生成微运动推荐
3. 用户在视频页跟练并完成训练
4. 系统保存运动记录、推荐反馈和两阶段推荐明细
5. 后续推荐继续利用这些数据做个性化调整

## 当前核心能力

- **两阶段微运动推荐**
  - 第一阶段做候选动作召回、排序和多样性筛选
  - 第二阶段用 LLM 在候选池内重排并生成最终动作方案
- **推荐可解释性**
  - 返回命中偏好摘要
  - 保存候选召回分、LLM 重排分、最终融合分和选择理由
- **视频指导闭环**
  - 推荐结果可进入视频播放页
  - 完成训练后写入运动记录并触发反馈学习
- **用户偏好动态学习**
  - 基于近 30 天训练完成情况、反馈标签、时长和时间衰减更新画像
- **久坐提醒**
  - 前端本地进行久坐检测与分级提醒
  - 后端记录提醒状态和日志
- **多平台前端**
  - Flutter 支持 Android、iOS、Web、Windows 等平台
- **3D 身体部位选择**
  - 支持通过 3D 模型选择目标部位，进入 AI 推荐或视频指导

## 当前技术栈

### 前端 `frontend/`

- Flutter
- Dart
- go_router
- Provider
- video_player
- model_viewer_plus

### 后端 `backend/`

- Spring Boot 3.1.6
- Java 17
- MyBatis Plus
- Spring Security
- JWT
- MySQL 8
- SpringDoc OpenAPI

### AI 服务 `ai-service/`

- FastAPI
- Python

说明：

- 当前**核心推荐主链路在后端 `backend/`**，即 `POST /api/micro-motion/generate-prompt`
- `ai-service/` 目前更偏向实验/兼容层，不是当前最重要的生产主链路

## 推荐算法现状

项目当前已经从“单次 LLM 直接生成”升级为“两阶段推荐”：

1. **候选召回阶段**
   - 从本地视频动作库中召回动作候选
   - 使用目标部位、显式偏好、近期反馈、重复疲劳、特殊情况等信号排序
2. **LLM 重排阶段**
   - 将候选动作池注入提示词
   - 要求模型在候选池内选择最终动作，并返回重排分与选择理由
3. **结果落表**
   - 保存 `exercise_record`
   - 保存 `recommendation_trace`

推荐算法研究文档见：

- [推荐算法研究说明](docs/architecture/recommendation_algorithm_research.md)

## 主要模块

### 1. 微运动推荐

入口页面：

- `frontend/lib/screens/motion_recommendation_screen.dart`

核心后端：

- `backend/src/main/java/com/kuibuqianli/service/DeepSeekService.java`
- `backend/src/main/java/com/kuibuqianli/service/VideoService.java`
- `backend/src/main/java/com/kuibuqianli/service/impl/PreferenceLearningServiceImpl.java`

### 2. 视频跟练与记录

入口页面：

- `frontend/lib/screens/video_player_screen.dart`

核心后端：

- `backend/src/main/java/com/kuibuqianli/controller/MotionController.java`
- `backend/src/main/java/com/kuibuqianli/service/impl/ExerciseRecordServiceImpl.java`

### 3. 久坐提醒

前端核心：

- `frontend/lib/services/sedentary_reminder_service.dart`

后端接口：

- `backend/src/main/java/com/kuibuqianli/controller/ReminderController.java`
- `backend/src/main/java/com/kuibuqianli/service/impl/ReminderServiceImpl.java`

### 4. 3D 身体部位选择

- `frontend/lib/screens/choose_part_of_body_screen.dart`

### 5. 健康数据与偏好设置

- `frontend/lib/screens/health_data_screen.dart`
- `frontend/lib/screens/preference_screen.dart`
- `backend/src/main/java/com/kuibuqianli/service/impl/HealthDataServiceImpl.java`
- `backend/src/main/java/com/kuibuqianli/service/impl/UserServiceImpl.java`

## 本地开发前置要求

- JDK 17+
- Maven 3.6+
- Flutter SDK
- MySQL 8.0+
- Windows PowerShell 或 CMD

可选：

- Python 3.8+，仅在你需要运行 `ai-service/` 时使用

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd kuibuqianli
```

### 2. 创建数据库

```sql
CREATE DATABASE kuibuqianli CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3. 初始化数据库

新库建议按顺序执行以下脚本：

```text
database/init/01_create_tables.sql
database/init/02_alter_user_table_add_profile_columns.sql
database/init/03_alter_exercise_record_add_feedback.sql
database/init/04_alter_exercise_record_add_recommendation_explanation.sql
database/init/05_create_recommendation_trace_table.sql
```

如果是已有数据库，至少确认以下内容已经存在：

- `user` 表中的画像字段
- `exercise_record.feedback_*`
- `exercise_record.recommendation_*`
- `recommendation_trace` 表

你也可以先尝试：

```bash
scripts\init_database.bat
```

### 4. 启动后端

推荐方式：

```bash
scripts\start_backend.bat
```

手动方式：

```bash
cd backend
mvn spring-boot:run
```

默认地址：

- API: `http://localhost:8080/api`
- Swagger: `http://localhost:8080/api/swagger-ui.html`

### 5. 启动前端

推荐方式：

```bash
scripts\start_frontend.bat
```

手动方式：

```bash
cd frontend
flutter pub get
flutter run
```

### 6. 可选：启动 AI 服务

如果你需要验证 `ai-service/` 的实验接口：

```bash
cd ai-service
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

默认地址：

- AI 服务: `http://localhost:8000`
- 文档: `http://localhost:8000/docs`

## 推荐的验证顺序

启动完成后，建议按下面顺序验证：

1. 打开 `http://localhost:8080/api/swagger-ui.html`
2. 调用 `POST /api/user/register`
3. 调用 `POST /api/user/login`
4. 调用 `POST /api/micro-motion/generate-prompt`
5. 调用 `POST /api/motion/record`
6. 检查 `exercise_record` 与 `recommendation_trace` 是否写入

## 数据库说明

### 关键业务表

- `user`
- `user_preference`
- `exercise_record`
- `remind_log`
- `video`
- `video_attribute`
- `exercise_video`
- `video_statistics`
- `recommendation_trace`

### `recommendation_trace` 的作用

这张表用于保存两阶段推荐过程中的关键中间结果，便于：

- 排查为什么某个动作被推荐
- 分析候选召回与 LLM 重排之间的差异
- 做离线评估、A/B 对比和规则优化

## 项目结构

```text
kuibuqianli/
├── backend/                         # Spring Boot 核心后端
├── frontend/                        # Flutter 前端
├── ai-service/                      # FastAPI 实验/兼容服务
├── database/
│   └── init/                        # 数据库初始化与增量脚本
├── docs/
│   ├── api/
│   ├── architecture/
│   ├── database/
│   └── deployment/
├── scripts/                         # 启动与辅助脚本
├── 3dmod/                           # 3D 模型资源
└── README.md
```

## 当前实现边界

以下内容需要明确：

- 姿态检测主链路仍在持续完善中，当前更偏向传感器/模拟验证，不是完整视觉姿态产品
- `ai-service/` 中部分接口仍是占位或实验性质
- 当前推荐系统已经是两阶段结构，但召回阶段仍以规则打分为主，还不是完整学习排序系统
- 仓库中目前仍包含部分日志、构建产物和比赛材料，后续建议继续清理

## 常见问题

### 1. 后端启动失败

优先检查：

- MySQL 是否已启动
- `backend/src/main/resources/application-dev.yml` 中数据库配置是否正确
- 数据库表结构是否执行完整

### 2. 推荐接口返回 500

优先检查：

- DeepSeek 配置是否可用
- `exercise_record` 与 `recommendation_trace` 表结构是否存在
- 本地视频目录配置是否有效

### 3. 前端无法请求后端

优先检查：

- 后端是否启动在 `8080`
- Flutter 运行平台对应的地址是否正确
- Android 模拟器下是否走了 `10.0.2.2`

### 4. 数据能写 `exercise_record`，但不能写 `recommendation_trace`

通常是以下原因：

- 数据库未执行 `05_create_recommendation_trace_table.sql`
- 老库未补齐 `exercise_record` 推荐解释字段

## 相关文档

- [推荐算法研究说明](docs/architecture/recommendation_algorithm_research.md)
- [系统架构文档](docs/architecture/system_architecture.md)
- [数据库设计文档](docs/database/database_design.md)
- [后端 API 文档](docs/api/backend_api.md)
- [AI 服务 API 文档](docs/api/ai_service_api.md)

## 开发建议

如果你要继续迭代这个项目，建议优先关注：

1. 两阶段推荐链路的离线评估与报表
2. `recommendation_trace` 的可视化分析
3. 姿态检测主链路补齐
4. 数据库脚本兼容性和仓库清理
5. 推荐反馈与偏好学习的进一步模型化
