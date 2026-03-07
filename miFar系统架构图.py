import matplotlib.pyplot as plt
import matplotlib
from matplotlib.patches import BoxStyle, FancyBboxPatch, FancyArrowPatch
import matplotlib.patches as patches
from matplotlib.lines import Line2D

# 设置中文字体
matplotlib.rcParams['font.sans-serif'] = ['SimHei', 'Microsoft YaHei', 'DejaVu Sans']
matplotlib.rcParams['axes.unicode_minus'] = False

# 创建图形
fig, ax = plt.subplots(figsize=(14, 10))
ax.set_xlim(0, 10)
ax.set_ylim(0, 9)
ax.axis('off')

# 更活泼的马卡龙配色
colors = {
    'start': '#FF6B9D',  # 亮粉色 - 开始
    'detection': '#FF9E6D',  # 亮橙色 - 检测
    'ai_primary': '#4ECDC4',  # 青蓝色 - 魔搭AI
    'ai_video': '#45B7D1',  # 天蓝色 - 视频AI
    'ai_select': '#96CEB4',  # 嫩绿色 - 选择AI
    'storage': '#FFEAA7',  # 亮黄色 - 存储
    'display': '#A8E6CF',  # 薄荷绿 - 显示
    'text': '#FFAAA5',  # 珊瑚粉 - 文字
    'process': '#D4A5A5',  # 淡紫色 - 处理
    'decision': '#FFD3B6',  # 蜜桃色 - 决策
}

# 绘制主标题
ax.text(5, 8.6, '📹 智能视频生成流程 - 四级降级策略',
        fontsize=16, fontweight='bold', ha='center',
        bbox=dict(boxstyle='round,pad=0.3', facecolor='#FFD3B6', alpha=0.9, edgecolor='#FF6B9D'))

# 绘制流程节点 - 更小更紧凑
nodes = [
    # 检测与触发
    ((5, 7.8), '姿态检测\n触发推荐', 'detection', 1.6, 0.4),

    # AI推理层
    ((3, 7.1), '姿态+偏好\n发送', 'process', 1.2, 0.4),
    ((5, 7.1), '魔搭AI\n关键词生成', 'ai_primary', 1.4, 0.4),
    ((7, 7.1), '优化\n关键词', 'process', 1.0, 0.4),

    # 一级策略：实时生成
    ((5, 6.4), '即梦AI\n生成视频', 'ai_video', 1.4, 0.4),

    # 检查点
    ((5, 5.7), '检查', 'decision', 0.8, 0.4),

    # 二级策略：知识库匹配
    ((3, 5.0), '知识库\n模糊查询', 'process', 1.2, 0.4),
    ((5, 5.0), 'AI选择\n最佳', 'ai_select', 1.2, 0.4),
    ((7, 5.0), '确定\n视频', 'process', 1.0, 0.4),

    # 检查点2
    ((5, 4.3), '检查', 'decision', 0.8, 0.4),

    # 三级策略：全库搜索
    ((3, 3.6), '全库\n列表', 'process', 1.0, 0.4),
    ((5, 3.6), 'AI分析\n选择', 'ai_select', 1.2, 0.4),

    # 四级策略：文字生成
    ((5, 2.9), 'AI生成\n文字', 'text', 1.2, 0.4),

    # 显示层
    ((5, 2.2), '前端\n显示', 'display', 1.0, 0.4),

    # 知识库
    ((1, 5.3), '知识库', 'storage', 0.9, 0.35),
    ((1, 4.9), '上半身', 'storage', 0.8, 0.3),
    ((1, 4.6), '下半身', 'storage', 0.8, 0.3),
    ((1, 4.3), '全身', 'storage', 0.8, 0.3),
]

# 绘制所有节点 - 更小的边框
for (x, y), text, node_type, width, height in nodes:
    color = colors.get(node_type, colors['process'])

    # 绘制矩形节点 - 更小更紧凑
    rect = FancyBboxPatch((x - width / 2, y - height / 2), width, height,
                          boxstyle='round,pad=0.05,rounding_size=0.05',
                          facecolor=color,
                          edgecolor='#555555',
                          linewidth=1.0,
                          alpha=0.95)
    ax.add_patch(rect)

    # 添加节点文本
    ax.text(x, y, text,
            fontsize=7,
            ha='center', va='center',
            fontweight='bold' if 'AI' in text else 'normal',
            color='black',
            linespacing=1.1)

# 绘制连接线 - 精确连接
connections = [
    # 检测到AI推理（从左到右）
    ((5, 7.6), (3, 7.3), '', ''),  # 检测到发送
    ((3, 6.9), (5, 6.9), '', ''),  # 发送到魔搭AI
    ((5, 6.9), (7, 6.9), '', ''),  # 魔搭AI到优化
    ((7, 6.9), (5, 6.6), '', ''),  # 优化到生成视频

    # 一级策略：生成视频
    ((5, 6.2), (5, 5.9), '', ''),

    # 检查点分支
    ((5, 5.5), (5, 5.0), '成功', 'success'),  # 成功到二级
    ((5, 5.5), (5, 4.9), '', 'success_arrow'),  # 实际箭头

    # 失败进入二级策略
    ((5, 5.5), (3, 5.2), '失败', 'fail'),  # 失败标签

    # 二级策略：知识库匹配
    ((3, 4.8), (1, 5.1), '', ''),  # 知识库查询
    ((1, 4.8), (3, 4.6), '', ''),  # 返回到模糊查询
    ((3, 4.6), (5, 4.6), '候选', ''),  # 到AI选择
    ((5, 4.6), (7, 4.6), '', ''),  # 到确定视频
    ((7, 4.6), (5, 4.4), '', ''),  # 返回

    # 检查点2分支
    ((5, 4.1), (5, 3.7), '成功', 'success'),  # 成功到三级
    ((5, 4.1), (3, 3.8), '失败', 'fail'),  # 失败标签

    # 三级策略：全库搜索
    ((3, 3.4), (1, 4.0), '', ''),  # 到知识库
    ((1, 3.6), (5, 3.8), '全库', ''),  # 返回AI分析

    # 三级到四级
    ((5, 3.4), (5, 3.1), '失败', 'fail'),  # 失败到四级

    # 四级策略：文字生成
    ((5, 2.7), (5, 2.4), '', ''),  # 到显示

    # 知识库内部连接
    ((1, 5.15), (1, 4.75), '', ''),
    ((1, 4.75), (1, 4.45), '', ''),
    ((1, 4.45), (1, 4.15), '', ''),
]

# 绘制连接箭头 - 精确连接
for (x1, y1), (x2, y2), label, line_style in connections:
    # 跳过标签位置的虚拟连接
    if label == '成功' or label == '失败':
        # 只绘制标签，不绘制箭头
        mid_x = (x1 + x2) / 2
        mid_y = (y1 + y2) / 2
        color = '#4CAF50' if label == '成功' else '#FF5252'

        ax.text(mid_x, mid_y, label,
                fontsize=6.5, ha='center', va='center',
                bbox=dict(boxstyle='round,pad=0.1',
                          facecolor='white',
                          edgecolor=color,
                          alpha=0.9,
                          linewidth=0.5))
        continue

    # 设置线条样式
    if line_style == 'success_arrow':
        color = '#4CAF50'  # 绿色
        linewidth = 1.8
        alpha = 1.0
        linestyle = 'solid'
    elif 'success' in str(line_style):
        color = '#4CAF50'
        linewidth = 1.8
        alpha = 1.0
        linestyle = 'solid'
    elif 'fail' in str(line_style):
        color = '#FF5252'  # 红色
        linewidth = 1.3
        alpha = 0.9
        linestyle = 'dashed'
    else:
        color = '#666666'
        linewidth = 1.0
        alpha = 0.8
        linestyle = 'solid'

    # 绘制箭头 - 精确指向
    arrow = FancyArrowPatch((x1, y1), (x2, y2),
                            arrowstyle='->,head_length=4,head_width=3',
                            mutation_scale=12,
                            linewidth=linewidth,
                            color=color,
                            alpha=alpha,
                            linestyle=linestyle)
    ax.add_patch(arrow)

# 添加策略标签
strategies = [
    ("🎯 一级", "AI实时生成", "#45B7D1"),
    ("🔍 二级", "知识库匹配", "#96CEB4"),
    ("📚 三级", "全库搜索", "#C7CEEA"),
    ("✏️ 四级", "文字生成", "#FFAAA5"),
]

for i, (emoji, desc, color) in enumerate(strategies):
    x_pos = 1.0 + i * 2.0
    ax.text(x_pos, 1.5, f"{emoji}\n{desc}", fontsize=7.5,
            ha='center', va='center',
            bbox=dict(boxstyle='round,pad=0.15',
                      facecolor=color,
                      edgecolor='#666666',
                      alpha=0.9,
                      linewidth=0.8))

# 添加功能特色
features = [
    "✨ 智能降级",
    "🤖 多AI协作",
    "💾 本地知识库",
    "🎨 个性化推荐"
]

for i, feature in enumerate(features):
    x_pos = 1.0 + i * 2.0
    ax.text(x_pos, 8.0, feature, fontsize=7,
            ha='center', va='center',
            bbox=dict(boxstyle='round,pad=0.1',
                      facecolor='#FFF9C4',
                      edgecolor='#FFD54F',
                      alpha=0.9))

# 添加图例
legend_elements = [
    patches.Rectangle((0, 0), 1, 1, facecolor=colors['ai_primary'], label='魔搭AI'),
    patches.Rectangle((0, 0), 1, 1, facecolor=colors['ai_video'], label='即梦AI'),
    patches.Rectangle((0, 0), 1, 1, facecolor=colors['ai_select'], label='选择AI'),
    patches.Rectangle((0, 0), 1, 1, facecolor=colors['storage'], label='知识库'),
    Line2D([0], [0], color='#4CAF50', linewidth=1.8, label='成功路径'),
    Line2D([0], [0], color='#FF5252', linewidth=1.3, linestyle='dashed', label='降级路径'),
]

ax.legend(handles=legend_elements, loc='lower center',
          bbox_to_anchor=(0.5, -0.05), ncol=3, fontsize=7.5,
          framealpha=0.9, frameon=True)

plt.tight_layout()
plt.savefig('视频生成流程图_紧凑版.png', dpi=300, bbox_inches='tight',
            facecolor='white', edgecolor='none')
print("✅ 视频生成流程图已保存为 '视频生成流程图_紧凑版.png'")
plt.show()