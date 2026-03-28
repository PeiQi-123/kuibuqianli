# 微运动推荐算法研究说明

## 1. 文档目的

本文档用于正式说明“跬步千里”当前版本的推荐算法设计、数学打分方式、两阶段推荐服务实现，以及它与 Twitter 开源推荐架构、ByteDance Monolith 公开思路之间的关系。

本文档强调两点：

1. 当前实现是结合本项目业务约束后的工程化改造，不是对 Twitter 或 Monolith 的直接复刻。
2. 当前实现已经从“单次 LLM 直接生成”升级为“候选召回 + LLM 重排 + 反馈学习 + 分数落表”的两阶段推荐服务。

## 2. 业务目标

本项目的推荐算法需要同时满足以下目标：

1. 针对用户当前目标部位生成安全、短时、可执行的微运动动作。
2. 将用户显式偏好、隐式行为、近期反馈和禁忌条件纳入推荐。
3. 优先使用项目已有视频动作库，保证推荐动作可播放、可解释、可复用。
4. 避免重复推荐近期反复出现、用户负反馈较多的动作。
5. 将推荐过程拆为可分析的阶段，并把阶段分数落表，支持后续评估与优化。

## 3. 算法演进

### 3.1 V1 版本

V1 版本的核心模式是：

`用户输入 -> LLM 直接生成动作 -> 前端展示 -> 用户反馈 -> 偏好学习`

这个版本的优点是上线快、可解释性强，但存在三个问题：

1. 候选动作空间过大，模型容易输出动作库外动作。
2. 无法显式区分“候选召回分”和“模型最终选择分”。
3. 无法稳定做离线分析、线上诊断和对照实验。

### 3.2 V2 版本

当前升级后的核心模式是：

`用户输入 -> 候选召回 -> 多样性筛选 -> LLM 重排 -> 最终动作方案 -> 训练记录与反馈 -> 用户偏好更新`

该版本已经具备典型工业推荐流水线的最小形态。

## 4. 两阶段推荐架构

### 4.1 阶段一：候选召回

候选召回阶段的输入包括：

1. 当前目标部位
2. 用户显式偏好
3. 用户近 30 天学习偏好画像
4. 用户特殊情况/禁忌
5. 用户近 30 天反馈
6. 用户近 3 天动作重复情况
7. 本地视频动作库

候选召回阶段的输出是一个候选动作池，每个动作带有：

1. `recall_score`
2. `category`
3. `reasons`
4. `candidate_rank`

### 4.2 阶段二：LLM 重排

LLM 重排阶段不再从无限动作空间直接生成，而是读取召回阶段给出的候选池，完成两件事：

1. 重新评估候选动作与当前上下文的匹配度
2. 在候选动作池中选择 2 到 3 个动作，输出最终训练方案

重排阶段的输出包括：

1. 最终动作列表 `actions`
2. 每个最终动作的 `rerank_score`
3. 每个最终动作的 `selection_reason`
4. 候选动作的 `candidate_ranking`

### 4.3 结果落表

最终写入数据库时，系统会保存：

1. `exercise_record`
2. `recommendation_trace`

其中 `recommendation_trace` 记录每个候选动作的：

1. 候选召回分 `recall_score`
2. 归一化召回分 `normalized_recall_score`
3. LLM 重排分 `llm_rerank_score`
4. 融合后的最终分 `final_score`
5. 候选位次 `candidate_rank`
6. 最终入选位次 `selected_rank`
7. 是否入选 `selected`
8. 召回原因 `recall_reasons`
9. LLM 选择理由 `llm_reason`

## 5. 当前实现中的数学打分公式

## 5.1 样本偏好学习权重

对最近 30 天每条训练样本，先计算样本权重：

```text
sample_weight = recency_weight
              * completion_weight
              * duration_weight
              * feedback_weight
```

其中：

```text
recency_weight =
  1.00,  最近 7 天
  0.80,  8 到 14 天
  0.65, 15 到 21 天
  0.50, 22 到 30 天
```

```text
completion_weight =
  1.00, 已完成
  0.35, 未完成
```

```text
duration_weight =
  1.15, duration >= 300s
  1.00, 180s <= duration < 300s
  0.85, duration < 180s
```

```text
feedback_weight =
  1.25, fit
  1.10, too_easy
  0.80, too_hard
  0.40, dislike
  1.00, 无反馈
```

如果存在 `feedback_score`，再乘以：

```text
feedback_score_factor = 0.7 + 0.15 * feedback_score
```

因此最终样本权重为：

```text
sample_weight = recency_weight
              * completion_weight
              * duration_weight
              * feedback_weight
              * feedback_score_factor
```

这个权重用于累积部位、动作类型、场景、时长、节奏和难度偏好的统计分。

## 5.2 候选召回分

对于动作库中的每个候选动作 `a`，当前实现的召回分可近似写为：

```text
recall_score(a) = base
                + target_body_bonus
                + preference_body_bonus
                + sport_type_bonus
                + difficulty_bonus
                + special_case_adjustment
                + feedback_adjustment
                - fatigue_penalty
                + freshness_bonus
```

其中：

```text
base = 1.0
```

目标部位命中：

```text
target_body_bonus =
  3.0, 动作命中当前目标部位
  0.0, 否则
```

历史偏好部位命中：

```text
preference_body_bonus =
  2.0, 动作命中学习到的偏好部位
  0.0, 否则
```

历史偏好类型命中：

```text
sport_type_bonus =
  1.8, 动作命中学习到的偏好运动类型
  0.0, 否则
```

难度匹配：

```text
difficulty_bonus =
  0.9, 低难度用户偏好与舒缓动作匹配
  0.9, 进阶用户偏好与动态/力量类动作匹配
  0.0, 否则
```

特殊情况修正：

```text
special_case_adjustment =
  +0.6, 禁忌存在时，舒缓动作
  -0.8, 禁忌存在时，高刺激动作
   0.0, 其他情况
```

用户反馈修正来自近 30 天动作反馈聚合：

```text
feedback_adjustment = Σ (feedback_weight_i * recency_i)
```

其中：

```text
feedback_weight_i =
  +2.5, fit
  +1.4, too_easy
  -0.8, too_hard
  -2.5, dislike
```

近期重复疲劳惩罚来自近 3 天动作使用频次：

```text
fatigue_penalty = min(0.7 * usage_count_3d, 2.1)
```

新鲜度奖励：

```text
freshness_bonus =
  +0.35, 最近 3 天未出现
   0.00, 否则
```

## 5.3 多样性选择

候选分排序后，系统不是直接取前 N，而是先做一轮类别去重：

1. 优先选高分动作
2. 尽量不让同一类别重复占满前列
3. 如果去重后不足，再补回高分动作

这一步的目标是避免输出“3 个动作都只是肩部拉伸”的单调组合。

## 5.4 召回分归一化

为了和第二阶段 LLM 重排分融合，需要对召回分做归一化：

```text
normalized_recall_score(a) =
  (recall_score(a) - min_recall) / (max_recall - min_recall)
```

若候选集中所有分数相同，则统一记为 `1.0`。

## 5.5 LLM 重排分

当前版本要求 LLM 在输出最终动作时返回：

```text
rerank_score ∈ [0, 1]
```

该分数反映候选动作在当前上下文下的综合适配度，包括：

1. 当前姿态上下文
2. 目标部位
3. 偏好约束
4. 特殊情况与安全约束
5. 动作组合的整体合理性

如果 LLM 没有按要求返回分数，系统会按照候选顺序进行保底赋值。

## 5.6 最终融合分

为了突出第二阶段重排的重要性，当前版本使用分段融合：

对于最终入选动作：

```text
final_score = 0.4 * normalized_recall_score + 0.6 * llm_rerank_score
```

对于未入选候选：

```text
final_score = 0.7 * normalized_recall_score + 0.3 * llm_rerank_score
```

其含义是：

1. 对最终入选动作，LLM 的上下文判断更重要
2. 对未入选候选，仍保留召回排序的主导地位，便于分析召回质量

## 6. 当前落地后的工程行为

## 6.1 候选池来源

当前候选池仍然来自本地视频动作库，而不是大规模内容库。这是因为当前业务目标更偏向“安全、可执行、可播放”的动作指导，而不是无限内容分发。

## 6.2 LLM 约束生成

当前版本不是让 LLM 自由发挥，而是要求：

1. 优先在候选动作池内选择动作
2. 返回结构化 JSON
3. 返回候选重排结果
4. 返回最终动作选择理由

这使得系统能够兼顾生成能力和工程可控性。

## 6.3 数据持久化

推荐完成后，分阶段分数会沿着前端运动完成链路回传，并在写入 `exercise_record` 时同步写入 `recommendation_trace`。

这意味着后续可以直接回答以下问题：

1. 哪些动作在召回阶段得分高，但被 LLM 否掉了
2. 哪些动作经常被 LLM 选中
3. 哪些动作的最终分高但用户反馈差
4. 用户“too_hard”后，召回和重排是否真的下降了刺激动作权重

## 7. 与 Twitter 开源推荐算法的对照

## 7.1 可对照的部分

Twitter 开源推荐系统公开体现了典型的多阶段推荐结构：

1. Candidate sourcing
2. Ranking
3. Heuristics / filtering
4. Negative feedback signals
5. Mixer / orchestration

本项目当前实现与之对应如下：

| Twitter 开源思路 | 本项目对应实现 |
| --- | --- |
| Candidate sourcing | `VideoService.recommendActionCandidates` 从动作库召回候选 |
| Ranking | `DeepSeekService` 基于候选池做 LLM 重排 |
| Negative feedback signals | `too_hard`、`dislike`、近期负反馈降权 |
| Heuristics / filtering | 特殊情况降权、重复疲劳惩罚、动作安全约束 |
| Mixer / diversity | 候选多样性筛选，避免同类动作垄断 |

## 7.2 本项目借鉴点

本项目借鉴 Twitter 公开算法的主要是架构思想，而不是参数细节：

1. 先召回，再排序，而不是一步生成
2. 把负反馈作为真实的排序信号
3. 在排序之外引入工程规则做安全与多样性控制
4. 把推荐过程拆成可解释、可落表的阶段

## 7.3 本项目与 Twitter 的本质差异

1. Twitter 面向海量内容分发，本项目面向小规模安全动作推荐
2. Twitter 的候选来源是多路大规模源，本项目主要是本地动作视频库
3. Twitter 排序主力是大规模学习排序模型，本项目当前第二阶段主力是 LLM 重排
4. Twitter 的目标函数是停留、互动、满意度等多目标，本项目核心目标是安全、可执行、长期匹配度

## 8. 与 ByteDance Monolith 的对照

## 8.1 可对照的部分

Monolith 公开强调的是实时推荐中的在线特征更新能力、特征新鲜度和线上学习闭环。

本项目目前可对照的部分主要体现在：

| Monolith 公开思路 | 本项目对应实现 |
| --- | --- |
| 强调行为数据快速进入推荐过程 | 近 30 天反馈和完成行为实时参与画像构建 |
| 强调特征新鲜度 | 行为权重带时间衰减，近 7 天权重最高 |
| 强调反馈闭环 | `too_easy / fit / too_hard / dislike` 会回写并影响后续排序 |
| 强调用户级个性化 | 每次推荐前都构建用户专属偏好画像 |

## 8.2 本项目借鉴点

本项目借鉴 Monolith 的不是底层分布式训练体系，而是以下思想：

1. 用户行为不能只做展示，必须进入推荐
2. 越新的行为应有更大的权重
3. 完成行为、反馈行为、时长行为都应统一进入个性化建模
4. 推荐系统需要把“训练闭环”看成实时更新过程，而不是离线静态画像

## 8.3 本项目与 Monolith 的本质差异

1. Monolith 解决的是超大规模线上训练与 Serving 一体化问题
2. 本项目当前还没有 embedding、在线参数更新和大规模样本流
3. 本项目目前使用的是规则召回 + LLM 重排，而不是 CTR/CVR 类大规模学习排序
4. 本项目更接近“面向垂直健康动作场景的轻量推荐系统”

## 9. 当前方案的优点

1. 明显提升了动作库内命中率
2. 推荐可解释性更强
3. 支持离线分析和后续模型迭代
4. 安全约束被显式加入推荐过程
5. 对用户近期负反馈和重复疲劳更敏感

## 10. 当前方案的局限

1. 候选召回仍是规则打分，不是学习召回
2. LLM 重排分仍依赖提示词约束，稳定性不如专门训练的排序模型
3. 动作库规模仍然较小，候选空间受限
4. 目前融合权重仍为人工设定，尚未做系统化校准
5. 特殊情况只是规则降权，还没有医疗风险知识图谱或禁忌库

## 11. 下一步研究方向

1. 将候选召回升级为向量召回或轻量两塔召回
2. 将 LLM 重排升级为“规则特征 + 小型排序模型 + LLM 解释”的混合重排
3. 引入真正的多目标优化，例如安全性、完成率、满意度、动作多样性
4. 对 `final_score` 的融合权重做离线回放和在线实验
5. 将 `recommendation_trace` 接入分析报表，形成推荐诊断面板

## 12. 参考资料

以下资料均为公开来源，仅作为架构思路参考：

1. ByteDance Monolith GitHub: [https://github.com/bytedance/monolith](https://github.com/bytedance/monolith)
2. Monolith 论文: [https://arxiv.org/abs/2209.07663](https://arxiv.org/abs/2209.07663)
3. Twitter 开源推荐代码仓库: [https://github.com/twitter/the-algorithm](https://github.com/twitter/the-algorithm)
4. Twitter 推荐信号文档: [https://github.com/twitter/the-algorithm/blob/main/RETREIVAL_SIGNALS.md](https://github.com/twitter/the-algorithm/blob/main/RETREIVAL_SIGNALS.md)
5. Twitter 官方开源说明: [https://blog.x.com/en_us/topics/open-source/2023/twitter-recommendation-algorithm](https://blog.x.com/en_us/topics/open-source/2023/twitter-recommendation-algorithm)
