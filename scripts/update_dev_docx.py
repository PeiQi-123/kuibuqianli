# -*- coding: utf-8 -*-
import os
import shutil
import tempfile
import zipfile
import xml.etree.ElementTree as ET


NS_URI = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
NS = {"w": NS_URI}
ET.register_namespace("w", NS_URI)


def find_target_docx(base_dir: str) -> str:
    for name in sorted(os.listdir(base_dir)):
        if name.endswith(".docx") and "项目开发文档" in name and not name.endswith(".bak"):
            return os.path.join(base_dir, name)
    raise FileNotFoundError("未找到目标项目开发文档 docx")


def paragraph_text(paragraph) -> str:
    return "".join(node.text or "" for node in paragraph.findall(".//w:t", NS)).strip()


REPLACEMENTS = {
    127: "本作品采用“Flutter 前端应用 + Spring Boot 核心后端 + FastAPI AI 接口层 + MySQL 数据库 + 本地视频资源库 + 演示版实时跟练指导页”的协同架构。",
    129: "（1）Flutter 前端负责多端界面呈现、用户交互、3D 身体部位选择、视频播放、摄像头姿态识别展示、实时跟练指导以及健康数据可视化展示。",
    130: "（2）Spring Boot 后端负责用户管理、偏好管理、两阶段 AI 推荐编排、推荐追踪落表、视频检索、运动记录、提醒管理与健康统计等核心业务处理。",
    131: "（3）FastAPI AI 服务负责提供 AI 调试入口和接口兼容层，并保留姿态相关接口原型；实际推荐主链路由后端统一组织与编排。",
    132: "（4）MySQL 数据库负责保存用户信息、用户偏好、运动记录、推荐追踪、提醒日志等结构化数据，并为设备数据、视频元数据和统计分析预留扩展表结构。",
    133: "（5）本地 video 目录提供动作演示视频，前端通过 guided motion 目录将 AI 推荐动作映射到可演示动作集合，后端通过文件名匹配与 FFmpeg 拼接支撑视频指导能力。",
    134: "在总体方案设计上，本作品遵循“先形成真实业务闭环，再逐步增强感知能力与智能能力”的实现路线。现阶段已优先完成用户登录、偏好配置、两阶段 AI 推荐、视频执行、训练记录、健康统计以及演示版实时跟练指导等核心链路，从而保证系统具备完整、可复现、可展示的业务流程。在此基础上，再继续增强任意动作姿态理解、久坐提醒联动、设备接入、视频元数据管理与推荐优化等能力，确保系统后续扩展能够建立在稳定架构之上。",
    138: "（1）实现用户注册、登录、用户信息维护、运动偏好维护与提醒配置维护等基础管理能力。",
    139: "（2）接入真实大模型链路，并采用“两阶段推荐（候选召回 + LLM 重排）”生成个性化微运动方案。",
    140: "（3）实现“推荐动作 - 视频指导 - 完成训练 - 写入记录 - 推荐追踪 - 健康统计”的完整业务闭环。",
    141: "（4）提供基于摄像头骨架识别的演示版实时跟练指导能力，并支持从 AI 推荐结果页直接进入指导流程。",
    142: "（5）实现动态偏好学习、推荐解释和推荐追踪落表，并为后续设备融合、任意动作识别和视频元数据接入预留结构基础。",
    176: "（5）视频指导页能够依据推荐动作匹配视频、顺序播放，并在训练完成后同时写入运动记录与推荐追踪数据。",
    178: "（7）姿态检测页能够基于摄像头骨架识别对若干演示动作提供实时跟练提示，并支持从推荐结果页直接进入。",
    188: "（1）实时跟练指导当前仅支持少量演示动作，尚不能直接覆盖 AI 任意生成动作的通用识别与纠错。",
    189: "（2）后端虽具备 JWT 生成能力，但当前未真正强制启用完整鉴权链路。",
    190: "（3）视频匹配仍主要依赖本地文件名规范，video 与 video_attribute 表尚未正式接入。",
    191: "（4）AI 生成视频链路仍在调试中，当前主要依赖本地视频和拼接方案完成演示。",
    192: "（5）Docker、Nginx、部署文档等目录已预留，但正式部署方案尚未补齐。",
    193: "除以上问题外，当前阶段还存在一些更细层面的工程性约束。第一，视频匹配准确率在较大程度上依赖视频文件命名规范，如果素材命名不统一，将直接影响推荐后的可播放性。第二，健康统计当前仍以结果汇总为主，尚未形成长期趋势分析、风险分层与行为干预机制。第三，提醒能力已经支持参数配置与日志记录，但与更复杂的感知条件联动仍有待加强。第四，AI 推荐虽然已经形成两阶段结构，但在边界场景下仍依赖后端兜底规则，因此后续仍需继续增强稳定性与一致性。",
    445: "（4）姿态检测当前采用“摄像头 + Google ML Kit Pose”的轻量实现，并在演示版中支持 4 个固定动作的实时跟练提示。",
    454: "当前数据库主要包含 10 张表，覆盖用户信息、用户偏好、运动记录、推荐追踪以及后续扩展能力。现阶段实际高频使用的表为 user、user_preference、exercise_record、recommendation_trace 与 remind_log。",
    460: "（4）user 与 remind_log：一对多（已接入）。",
    467: "exercise_record 表：保存训练记录。关键字段包括 id、user_id、motion_id、motion_name、duration、completed、recommendation_summary、recommendation_matched_items、feedback_tag、feedback_score、created_at。当前状态：已使用。",
    469: "remind_log 表：保存提醒日志。关键字段包括 log_id、user_id、actual_time、status。当前状态：已使用。",
    470: "video 表：视频主表。关键字段包括 id、title、file_path、file_url、duration、status。当前状态：已设计未正式接入。",
    471: "video_attribute 表：视频标签表。关键字段包括 id、video_id、attribute_type、attribute_value。当前状态：已设计未正式接入。",
    472: "exercise_video 表：训练记录与视频关联表。关键字段包括 id、exercise_record_id、video_id、video_type。当前状态：已设计未正式接入。",
    473: "video_statistics 表：视频统计表。关键字段包括 video_id、view_count、completed_count、avg_rating。当前状态：已设计未正式接入。",
    474: "recommendation_trace 表：保存两阶段推荐明细。关键字段包括 exercise_record_id、action_name、candidate_rank、selected_rank、recall_score、normalized_recall_score、llm_rerank_score、final_score、recall_reasons、llm_reason。当前状态：已投入使用。",
    475: "从表结构合理性角度看，当前数据库中的四张高频核心表已经能够支撑完整主链路。user 表承接身份与身体画像，user_preference 表承接长期偏好，exercise_record 表承接训练行为结果，recommendation_trace 表承接推荐中间过程与解释信息。四者共同构成“人 - 偏好 - 推荐 - 行为”的基础分析框架。即便在尚未引入更复杂设备数据和视频元数据的情况下，这一框架也足以支撑一个具备个性化输入、推荐可解释性和行为闭环能力的原型系统。",
    493: "（1）当前健康数据统计直接对 exercise_record 做聚合查询，并能反映最近训练结果。",
    494: "（2）当前推荐链路会在 exercise_record 之外额外写入 recommendation_trace，用于保存候选召回分、重排分与最终融合分。",
    495: "（3）当前视频管理实际仍依赖本地目录扫描，device_data 与 video 系列表属于“结构已设计、业务待继续接入”状态。",
    555: "（2）当前偏好不仅作为基础配置输入，也会通过偏好学习服务参与后续推荐结果的调整与个性化修正。",
    556: "运动偏好模块的意义在于把用户“长期习惯”引入系统，而不是让每次推荐都只依赖用户临时输入。现实中，同样是肩颈放松需求，不同用户对动作节奏、运动类型、可接受难度和特殊注意事项的偏好可能差异很大。如果完全忽略这些长期偏好，推荐结果就容易变成“对任何人都差不多”的通用方案。当前项目已经通过偏好存储、偏好画像构建和动态学习，把这些长期偏好逐步纳入推荐链路，为个性化深化打下基础。",
    559: "负责根据用户选择的目标部位、场景、训练时长、强度以及身体信息生成结构化微运动方案，并输出具备解释能力的两阶段推荐结果。",
    561: "模块性能主要受外部大模型响应影响，当前更关注候选召回的稳定性、返回结构的一致性以及动作可播放性。",
    570: "动作列表（名称、秒数、做法、注意事项、选择理由）。",
    571: "个性化提示语以及推荐追踪明细信息。",
    573: "（1）后端读取本地视频库中的动作名称，并结合用户画像和历史反馈构建候选动作池。",
    574: "（2）在候选召回阶段计算动作召回分，完成排序与多样性筛选。",
    575: "（3）构建系统提示词和用户提示词，将候选动作池、场景和身体信息一并注入。",
    576: "（4）调用 DeepSeek 并解析返回 JSON，提取最终动作、重排分与选择理由。",
    577: "（5）若动作名称不在候选范围内，使用归一化匹配、可演示动作映射或兜底动作替换为可用结果。",
    578: "（6）根据 BMI、年龄等信息修正建议时长与难度，并生成 recommendation_trace 数据。",
    581: "（2）推荐质量受视频库命名规范、候选动作覆盖度和外部模型响应质量影响。",
    582: "（3）尚未完成计划中的四级降级推荐策略与完整视频元数据检索体系。",
    583: "AI 微运动推荐模块是本作品最具“智能化”特征的部分，但其实现思路并不是简单调用大模型生成一段自由文案，而是强调“结构化、可约束、可执行、可追踪”。这也是本作品与许多仅做聊天式推荐原型的区别所在。当前后端已经形成“两阶段推荐”结构：先基于动作库完成候选召回与排序，再由大模型完成重排与解释，同时把召回分、重排分和最终融合分落入 recommendation_trace 表。这样一来，推荐结果不仅能够顺利进入后续播放和记录链路，也便于后续开展推荐分析、效果评估与持续优化。",
    586: "负责根据推荐动作筛选视频、顺序播放视频，并在训练完成后写入运动记录与推荐追踪结果。",
    588: "视频列表读取和匹配为本地操作，性能压力较小；视频播放性能主要取决于设备播放能力和视频资源质量；推荐追踪写入为轻量级数据库批量插入。",
    596: "运动记录与推荐追踪保存结果。",
    601: "（4）用户点击完成训练后调用记录接口写入 exercise_record，并同步写入 recommendation_trace。",
    602: "（5）后端也支持按步骤关键词拼接视频，并为 AI 视频生成链路预留调用位置。",
    607: "视频指导与训练执行模块是把“智能推荐”转化为“用户真实行动”的关键桥梁。如果系统只能给出文字建议而缺少执行承接，就难以形成真正的行为闭环。因此，当前版本特别强调视频资源检索、动作匹配、步骤说明展示和推荐追踪落表，使用户能够更直接地理解动作并开始跟练。该模块后续仍有较大提升空间，例如加入训练倒计时、语音提示、动作收藏和评分等能力，但在现阶段已经满足核心演示目标。",
    610: "提供基于摄像头骨架识别的演示版实时跟练指导能力，并支持从 AI 推荐页直接进入姿态检测流程。",
    612: "该模块当前采用本地轻量规则判断，响应速度较快，适合实时界面刷新与作品演示录制。",
    614: "摄像头采集到的连续视频帧。",
    615: "Google ML Kit Pose 返回的人体关键点。",
    616: "当前动作队列、动作时长和前端映射后的演示动作定义。",
    618: "当前跟练动作文本、实时提示语、剩余时间和关键点骨架叠加。",
    619: "动作队列与当前动作完成状态展示。",
    621: "（1）从推荐页透传 AI 推荐结果，并映射到可演示的固定动作集合。",
    622: "（2）初始化摄像头和 Pose 检测器，持续接收关键点识别结果。",
    623: "（3）根据当前动作应用不同的轻量规则，例如颈部侧屈识别头部偏移、耸肩识别肩部起伏、扩胸运动识别手臂展开幅度。",
    624: "（4）将实时提示、动作队列、剩余时间和骨架叠加同步显示到界面上。",
    626: "（1）当前仅支持少量演示动作的实时跟练提示，尚不能覆盖 AI 任意生成动作。",
    627: "（2）当前更强调演示稳定性和视频录制效果，尚未与久坐提醒和完整效果评估闭环打通。",
    628: "姿态检测模块当前已经从“设备姿态演示”升级为“面向作品展示的实时跟练指导页”，但其核心定位仍然是演示版能力，而非面向任意动作的通用识别引擎。这样的技术取舍是合理的：一方面，真实任意动作识别和标准化纠错在技术上更加复杂，需要更丰富的数据积累和更系统的模型支持；另一方面，竞赛原型更需要优先证明从推荐到执行的可演示闭环已经成立，再逐步增强自动感知能力。因此，当前模块虽以少量固定动作为主，但其技术方向与系统长期演进方向是一致的。",
}


def main():
    base_dir = os.path.join(os.getcwd(), "docs")
    docx_path = find_target_docx(base_dir)
    backup_path = docx_path + ".python.bak"
    if not os.path.exists(backup_path):
        shutil.copy2(docx_path, backup_path)

    with zipfile.ZipFile(docx_path) as zf:
        xml_bytes = zf.read("word/document.xml")
        other_entries = [(item, zf.read(item.filename)) for item in zf.infolist() if item.filename != "word/document.xml"]

    root = ET.fromstring(xml_bytes)
    paragraphs = root.findall(".//w:body/w:p", NS)

    for idx, new_text in REPLACEMENTS.items():
        paragraph = paragraphs[idx]
        text_nodes = paragraph.findall(".//w:t", NS)
        if not text_nodes:
            continue
        text_nodes[0].text = new_text
        for node in text_nodes[1:]:
            node.text = ""

    new_xml = ET.tostring(root, encoding="utf-8", xml_declaration=True)

    fd, tmp_path = tempfile.mkstemp(suffix=".docx")
    os.close(fd)
    with zipfile.ZipFile(tmp_path, "w", zipfile.ZIP_DEFLATED) as out_zip:
        for item, data in other_entries:
            out_zip.writestr(item, data)
        out_zip.writestr("word/document.xml", new_xml)

    shutil.move(tmp_path, docx_path)
    print(f"updated: {docx_path}")
    print(f"backup: {backup_path}")


if __name__ == "__main__":
    main()
