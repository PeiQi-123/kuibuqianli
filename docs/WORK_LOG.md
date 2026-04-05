# 工作日志 - 跬步千里项目

## 2026-03-06

### 今日完成

#### 1. 微运动推荐功能
- 创建 `motion_recommendation_screen.dart`
- 实现活动类型（久坐/工作/休息/学习）选择
- 实现运动时长（3/5/10/15分钟）选择
- 实现运动强度（低/中/高）选择
- 调用 AI 服务生成个性化运动方案
- 显示运动步骤列表

#### 2. 姿态检测功能
- 创建 `sensor_service.dart` 传感器服务
- 创建 `posture_detection_screen.dart` 检测页面
- **手机模式**：使用 sensors_plus 读取加速度计和陀螺仪，实时检测手机姿态
- **电脑模拟模式**：提供 6 个预设姿势按钮 + 3 个滑块手动调整
- 支持姿态识别：直立、横屏、屏幕朝上/下、自由下落等

#### 3. 视频指导功能
- 创建 `video_player_screen.dart` 视频播放页面
- 对接后端 `/video/list` API 获取本地视频列表
- 实现视频选择功能
- 显示运动步骤，支持步骤切换演示

#### 4. 后端 API 开发
- 创建 `MotionController.java` - 微运动生成接口
- 创建 `VideoController.java` - 视频管理接口
- 创建 `VideoService.java` - 视频服务（支持 FFmpeg 拼接）
- 创建 `JacksonConfig.java` - JSON 编码配置

#### 5. AI 链路与编码修复
- 将 AI 服务 `/api/motion/generate` 接入后端 `MotionController`，统一返回 `Result` 结构
- 使用 `RestTemplate + ObjectMapper` 按 UTF-8 手动解析 AI 返回 JSON，避免编码错误
- 前端 `ApiService` 全部改为 `jsonDecode(utf8.decode(response.bodyBytes))`，修复前端中文乱码

#### 6. 多端适配与视频播放
- 在 `ApiService` 中根据运行环境自动选择 `baseUrl`：Web/桌面使用 `localhost`，Android 模拟器使用 `10.0.2.2`
- `VideoPlayerScreen` 支持双模式播放：
  - 移动端（Android/iOS）：使用 `video_player` 内嵌播放器播放后端 `/video/play` 视频流
  - Web/桌面：使用 `url_launcher` 打开视频 URL，由浏览器/系统播放器播放

#### 7. 依赖更新与环境配置
- 添加 `sensors_plus: ^4.0.2` - 手机传感器
- 添加 `video_player: ^2.8.2` - 视频播放（移动端使用）
- 添加 `url_launcher: ^6.3.0` - 打开浏览器/系统播放器
- 安装并配置 FFmpeg，确认 `ffmpeg -version` 可在命令行正常执行

#### 8. 按步骤自动拼接视频
- 在 `VideoService` 中实现 `concatenateVideosBySteps`：
  - 根据 AI 返回的中文步骤文本（如“坐姿脚尖点地”“左右转头拉伸颈部”等），按关键词（颈/肩/腰/腿/脚/手腕/手臂…）自动匹配本地视频片段
  - 支持命名约定匹配（如 `motion_001_step1_*.mp4`、`step1_*.mp4`）
  - 对匹配到的片段使用 FFmpeg 进行顺序拼接，生成完整动作视频（`motionId_combined.mp4`）
- 在 `MotionController.generateMotion` 中接入 VideoService：
  - 从 AI 返回的数据中提取 `steps` 和 `motion_id`
  - 自动调用 `concatenateVideosBySteps` 生成完整视频
  - 将生成的视频播放地址写入 `video_url` 字段（`/api/video/play?filename=...`），前端可直接使用

---

### 文件统计
- 新增文件：12 个（前后端配置、控制器、服务、前端页面等）
- 修改文件：20+ 个
- 代码行数：约 +1500 行

---

### 下一步计划
1. 为各类动作（腿/脚/颈肩腰/手腕手臂等）准备并命名对应的视频片段，放入 `video/` 目录，确保文件名能被当前关键词/命名规则匹配
2. 在前端微运动推荐页面中读取后端返回的 `video_url`，优先播放完整拼接视频（找不到时再退回到单段选择）
3. 接入真正的 AI 模型，替换硬编码示例数据，实现更智能的微运动方案生成
4. 在 Android/iOS 真机上实测视频播放和姿态检测，优化交互体验
5. 开发健康数据统计页面（使用 fl_chart 展示运动次数/时长趋势）

## 2026-03-14

### 今日完成

#### 1. 久坐自动预警与分级提醒闭环
- 新增 `SedentaryReminderService`，实现前台久坐计时、加速度活动检测、免打扰判断与分级提醒逻辑
- 支持轻提醒 / 中风险 / 高风险三级提醒，并在高风险时直接引导到视频指导或微运动推荐
- 在首页增加“久坐提醒状态卡片”，展示当前久坐时长、下一次提醒时间、今日提醒次数和当前预警等级
- 在用户信息页补充“每日最大提醒次数”配置，并与后端用户提醒配置同步
- 后端新增 `ReminderController` 和 `ReminderServiceImpl`，支持获取提醒状态、记录提醒日志并计算下一次建议提醒时间

#### 2. 推荐反馈学习闭环
- 将运动记录保存接口升级为返回 `recordId`，为一次训练绑定后续反馈提供依据
- 新增推荐反馈接口 `/motion/feedback`，支持“太简单 / 合适 / 太难 / 不喜欢”四类反馈写入 `exercise_record`
- 在视频指导页完成训练后自动弹出推荐评价对话框，并支持后续再次评价
- 为 `exercise_record` 增加 `feedback_tag`、`feedback_score`、`feedback_at` 字段，并补充数据库增量脚本 `03_alter_exercise_record_add_feedback.sql`

#### 3. 用户偏好动态学习算法
- 新增 `PreferenceLearningServiceImpl`，基于近 30 天训练记录构建动态学习画像
- 学习维度覆盖部位、运动类型、场景、时长、节奏和建议难度，并加入时间衰减、完成率和反馈权重
- 新增 `/user/preferences/insights` 接口，输出显式偏好、动态偏好、融合偏好、反馈分布和学习总结
- 将动态学习结果注入 `DeepSeekService` 提示词构造流程，使推荐时长、难度和动作选择直接受到学习画像影响

#### 4. 反馈分布可视化与视频排序联动
- 在偏好设置页新增“动态学习偏好画像”模块，展示学习总结、完成率、反馈分布、系统学习偏好和融合偏好
- 在微运动推荐页展示动态学习总结，提示当前推荐已经结合近期训练行为进行优化
- 后端 `VideoService` 新增按用户反馈偏好和目标部位对视频列表进行排序的能力
- 前端视频指导页请求 `/video/list` 时携带 `userId` 和 `bodyPart`，让视频排序与个人反馈习惯联动

### 本次核心改动文件
- 后端：`ReminderController.java`、`ReminderServiceImpl.java`、`PreferenceLearningServiceImpl.java`、`DeepSeekService.java`、`MotionController.java`、`ExerciseRecordServiceImpl.java`、`VideoService.java`
- 前端：`sedentary_reminder_service.dart`、`app_screen.dart`、`user_info_screen.dart`、`video_player_screen.dart`、`motion_recommendation_screen.dart`、`preference_screen.dart`
- 数据库：`01_create_tables.sql`、`03_alter_exercise_record_add_feedback.sql`

### 当前效果
- 系统已经具备“久坐检测 -> 分级提醒 -> 进入训练 -> 完成训练 -> 反馈评价 -> 动态学习 -> 优化下次推荐”的完整闭环
- 动态学习不再停留在静态偏好存储，而是已经真正参与推荐提示词、难度判断和视频排序

### 下一步建议
1. 增加推荐反馈历史页与趋势图，让学习过程对用户更可见
2. 把收藏、复看、跳过等行为继续纳入偏好学习权重模型
3. 增强冷启动策略和禁忌动作规避逻辑，提升新用户与特殊人群推荐稳定性

## 2026-03-15

### 今日完成

#### 1. 项目联调启动与环境核验
- 启动并验证 AI 服务、Spring Boot 后端和 Flutter Web 前端主链路
- 确认前端访问 `http://127.0.0.1:3000`、后端访问 `http://127.0.0.1:8080/api`、AI 服务访问 `http://127.0.0.1:8000`
- 检查本地 Java、Maven、Python、Flutter、MySQL 运行环境可用性

#### 2. 数据库基础表补齐
- 发现本地库仅包含 `user`、`user_preference`、`exercise_record`、`device_data` 四张表，提醒模块依赖的 `remind_log` 等表缺失
- 补跑 `database/init/01_create_tables.sql`，补齐提醒、视频及关联统计表，恢复提醒接口运行基础
- 识别出 `database/init/03_alter_exercise_record_add_feedback.sql` 在当前 MySQL 版本下存在 `ADD COLUMN IF NOT EXISTS` 兼容性问题，已记录为待修复项

#### 3. 3D 身体部位选择器体验微调
- 根据模型真实姿态，重新校准左右手臂热点位置，使其更贴合手臂向下约 45 度的姿势
- 将身体选择页切换到蓝色版本 3D 模型资源，并增加轻微冷色滤镜强化整体蓝色观感
- 保持热点点击、部位选择和后续推荐/视频跳转链路不变

### 本次涉及文件
- 文档：`WORK_LOG.md`、`TODO.md`
- 前端：`frontend/lib/constants/body_part_catalog.dart`、`frontend/lib/screens/choose_part_of_body_screen.dart`
- 数据库：`database/init/01_create_tables.sql`、`database/init/03_alter_exercise_record_add_feedback.sql`

### 当前效果
- 项目主链路已经可以在本地正常拉起并完成基础联调
- 身体部位选择页的模型风格更偏蓝，手臂热点与当前模型姿态更一致
- 提醒相关接口所需基础表已补齐，但训练反馈增量脚本仍需做一次 MySQL 兼容修正

### 下一步建议
1. 修复 `03_alter_exercise_record_add_feedback.sql` 的兼容语法，补齐反馈字段增量升级流程
2. 继续微调 3D 模型热点，按实际视觉效果校准手臂、肩部等边缘部位命中区域
3. 清理运行产生的日志、缓存和编译产物，避免影响仓库整洁度与后续提交
