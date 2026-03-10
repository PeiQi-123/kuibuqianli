// 运动偏好设置页面（简化版）
import 'package:flutter/material.dart';

class PreferenceScreenSimple extends StatefulWidget {
  const PreferenceScreenSimple({super.key});

  @override
  State<PreferenceScreenSimple> createState() => _PreferenceScreenSimpleState();
}

class _PreferenceScreenSimpleState extends State<PreferenceScreenSimple> {
  // 身体部位偏好
  final List<String> bodyParts = ['全身', '上肢', '下肢', '核心', '背部', '肩部', '颈部', '腰部'];
  List<String> selectedBodyParts = ['全身', '上肢', '核心', '肩部'];

  // 动作难度偏好
  final List<String> difficulties = ['入门', '初级', '中级', '高级', '专业'];
  String selectedDifficulty = '中级';

  // 偏好时长（分钟）
  final List<int> durations = [5, 10, 15, 20, 25, 30, 45, 60];
  int selectedDuration = 20;

  // 运动类型偏好
  final List<String> sportTypes = ['拉伸', '力量', '有氧', '平衡', '柔韧', '协调', '耐力', '爆发力'];
  List<String> selectedSportTypes = ['拉伸', '有氧', '平衡', '协调'];

  // 运动场景偏好
  final List<String> scenes = ['居家', '办公室', '健身房', '户外', '旅行', '学校', '公园'];
  List<String> selectedScenes = ['居家', '办公室', '户外', '学校'];

  // 其他偏好
  bool silentMotion = false;
  bool slowPace = true;
  bool withMusic = true;
  bool withCoach = true;
  bool withWarmUp = true;
  bool withCoolDown = true;

  // 其他特点
  String otherFeatures = '偏好有明确计数和节奏的动作，喜欢有进度条显示，需要动作分解演示';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('运动偏好设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: _savePreferences,
            icon: const Icon(Icons.save),
            tooltip: '保存偏好',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 身体部位偏好
            _buildSectionTitle('偏好的身体部位'),
            _buildMultiSelectChips(
              items: bodyParts,
              selectedItems: selectedBodyParts,
              onChanged: (item, selected) {
                setState(() {
                  if (selected) {
                    if (!selectedBodyParts.contains(item)) {
                      selectedBodyParts = [...selectedBodyParts, item];
                    }
                  } else {
                    selectedBodyParts = selectedBodyParts.where((i) => i != item).toList();
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // 动作难度偏好
            _buildSectionTitle('偏好的动作难度'),
            _buildSingleSelectChips(
              items: difficulties,
              selectedItem: selectedDifficulty,
              onChanged: (item) {
                setState(() {
                  selectedDifficulty = item;
                });
              },
            ),

            const SizedBox(height: 24),

            // 偏好时长
            _buildSectionTitle('偏好的运动时长（分钟）'),
            _buildDurationSelector(),

            const SizedBox(height: 24),

            // 运动类型偏好
            _buildSectionTitle('偏好的运动类型'),
            _buildMultiSelectChips(
              items: sportTypes,
              selectedItems: selectedSportTypes,
              onChanged: (item, selected) {
                setState(() {
                  if (selected) {
                    if (!selectedSportTypes.contains(item)) {
                      selectedSportTypes = [...selectedSportTypes, item];
                    }
                  } else {
                    selectedSportTypes = selectedSportTypes.where((i) => i != item).toList();
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // 运动场景偏好
            _buildSectionTitle('偏好的运动场景'),
            _buildMultiSelectChips(
              items: scenes,
              selectedItems: selectedScenes,
              onChanged: (item, selected) {
                setState(() {
                  if (selected) {
                    if (!selectedScenes.contains(item)) {
                      selectedScenes = [...selectedScenes, item];
                    }
                  } else {
                    selectedScenes = selectedScenes.where((i) => i != item).toList();
                  }
                });
              },
            ),

            const SizedBox(height: 24),

            // 其他偏好设置
            _buildSectionTitle('其他偏好设置'),
            _buildOtherPreferences(),

            const SizedBox(height: 24),

            // 其他特点
            _buildSectionTitle('其他特点'),
            _buildOtherFeatures(),

            const SizedBox(height: 32),

            // 保存按钮
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildMultiSelectChips({
    required List<String> items,
    required List<String> selectedItems,
    required Function(String, bool) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);
        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (value) => onChanged(item, value),
          selectedColor: Colors.blue.shade100,
          checkmarkColor: Colors.blue,
          backgroundColor: Colors.grey[100],
          labelStyle: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSingleSelectChips({
    required List<String> items,
    required String selectedItem,
    required Function(String) onChanged,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItem == item;
        return ChoiceChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              onChanged(item);
            }
          },
          selectedColor: Colors.blue.shade100,
          backgroundColor: Colors.grey[100],
          labelStyle: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDurationSelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: durations.length,
        itemBuilder: (context, index) {
          final duration = durations[index];
          final isSelected = selectedDuration == duration;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$duration分钟'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    selectedDuration = duration;
                  });
                }
              },
              selectedColor: Colors.blue.shade100,
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtherPreferences() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('静音动作'),
          subtitle: const Text('偏好没有语音指导的静音动作'),
          value: silentMotion,
          onChanged: (value) => setState(() => silentMotion = value),
        ),
        SwitchListTile(
          title: const Text('慢节奏'),
          subtitle: const Text('偏好节奏较慢、讲解详细的动作'),
          value: slowPace,
          onChanged: (value) => setState(() => slowPace = value),
        ),
        SwitchListTile(
          title: const Text('背景音乐'),
          subtitle: const Text('偏好有背景音乐的运动视频'),
          value: withMusic,
          onChanged: (value) => setState(() => withMusic = value),
        ),
        SwitchListTile(
          title: const Text('教练指导'),
          subtitle: const Text('偏好有真人教练示范和指导'),
          value: withCoach,
          onChanged: (value) => setState(() => withCoach = value),
        ),
        SwitchListTile(
          title: const Text('包含热身'),
          subtitle: const Text('偏好包含热身环节的运动方案'),
          value: withWarmUp,
          onChanged: (value) => setState(() => withWarmUp = value),
        ),
        SwitchListTile(
          title: const Text('包含放松'),
          subtitle: const Text('偏好包含放松环节的运动方案'),
          value: withCoolDown,
          onChanged: (value) => setState(() => withCoolDown = value),
        ),
      ],
    );
  }

  Widget _buildOtherFeatures() {
    return TextFormField(
      initialValue: otherFeatures,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: '请输入您的其他运动偏好特点...',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (value) => otherFeatures = value,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _savePreferences,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
        ),
        icon: const Icon(Icons.save, color: Colors.white),
        label: const Text(
          '保存运动偏好',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  void _savePreferences() {
    // 这里只是界面展示，实际保存逻辑后续添加
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('运动偏好已保存（演示模式）'),
        duration: Duration(seconds: 2),
      ),
    );
    
    // 打印当前选择的偏好（用于调试）
    print('=== 运动偏好设置 ===');
    print('身体部位偏好: ${selectedBodyParts.join(', ')}');
    print('动作难度: $selectedDifficulty');
    print('偏好时长: $selectedDuration分钟');
    print('运动类型: ${selectedSportTypes.join(', ')}');
    print('运动场景: ${selectedScenes.join(', ')}');
    print('静音动作: $silentMotion');
    print('慢节奏: $slowPace');
    print('背景音乐: $withMusic');
    print('教练指导: $withCoach');
    print('包含热身: $withWarmUp');
    print('包含放松: $withCoolDown');
    print('其他特点: $otherFeatures');
    print('==================');
  }
}