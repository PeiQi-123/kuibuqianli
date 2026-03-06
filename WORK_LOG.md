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
