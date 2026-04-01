# 跬步千里文档总览

本目录用于统一存放“跬步千里”项目的架构文档、测试文档、数据库脚本说明和竞赛/答辩材料。

## 一、建议阅读顺序

### 1. 项目总览

- [README.md](../README.md)

用于快速了解项目定位、主链路、技术栈和启动方式。

### 2. 竞赛/材料文档

以下 5 份文档可直接作为作品材料基础稿使用：

1. [1_软件硬件说明.md](./1_软件硬件说明.md)
   - 作品使用的软件、硬件及运行环境说明
2. [2_高层设计文档.md](./2_高层设计文档.md)
   - 作品主要功能的程序高层设计
3. [3_共享数据样例.md](./3_共享数据样例.md)
   - 作品中涉及的共享数据、视频、生产数据样例
4. [4_数据流转及展示方式.md](./4_数据流转及展示方式.md)
   - 数据在系统中的流转、存储和展示方式说明
5. [5_测试文档.md](./5_测试文档.md)
   - 功能测试、性能测试、数据流量与运行分析

### 3. 架构与算法文档

- [architecture/recommendation_algorithm_research.md](./architecture/recommendation_algorithm_research.md)
  - 两阶段推荐算法说明、数学公式、与 Twitter / Monolith 对照
- [architecture/system_architecture.md](./architecture/system_architecture.md)
  - 系统架构占位文档，可继续扩展为答辩版架构图说明

### 4. 数据库与部署文档

- [database/database_design.md](./database/database_design.md)
- [deployment/deployment_guide.md](./deployment/deployment_guide.md)

### 5. API 文档

- [api/backend_api.md](./api/backend_api.md)
- [api/ai_service_api.md](./api/ai_service_api.md)

## 二、当前文档分层

```text
docs/
├── README.md                         # 文档总览
├── 1_软件硬件说明.md
├── 2_高层设计文档.md
├── 3_共享数据样例.md
├── 4_数据流转及展示方式.md
├── 5_测试文档.md
├── api/
├── architecture/
├── database/
└── deployment/
```

## 三、文档用途建议

### 1. 用于比赛提交

优先使用：

- `1_软件硬件说明.md`
- `2_高层设计文档.md`
- `3_共享数据样例.md`
- `4_数据流转及展示方式.md`
- `5_测试文档.md`

### 2. 用于答辩讲解

建议配合：

- `README.md`
- `architecture/recommendation_algorithm_research.md`
- `4_数据流转及展示方式.md`

### 3. 用于团队接手开发

建议配合：

- 项目根目录 `README.md`
- 本目录 `README.md`
- `2_高层设计文档.md`
- `5_测试文档.md`

## 四、维护建议

后续如果项目继续迭代，建议同步更新以下文档：

1. 结构或模块有大改动时，更新 `2_高层设计文档.md`
2. 数据库结构变化时，更新 `3_共享数据样例.md` 和 `4_数据流转及展示方式.md`
3. 新增测试结果或性能指标时，更新 `5_测试文档.md`
4. 推荐算法变化时，更新 `architecture/recommendation_algorithm_research.md`
