// 运动偏好设置页面（简化版）
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class PreferenceScreenSimple extends StatefulWidget {
  const PreferenceScreenSimple({super.key});

  @override
  State<PreferenceScreenSimple> createState() => _PreferenceScreenSimpleState();
}

class _PreferenceScreenSimpleState extends State<PreferenceScreenSimple> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  
  // 身体部位偏好
  final List<String> bodyParts = ['头部', '脖子','脊椎', '腰椎', '肩周', '手腕', '手指', '眼睛', '小臂','大臂','大腿', '小腿', '脚踝', '腰背', '腹部','全身'];
  List<String> selectedBodyParts = [];

  // 动作难度偏好（多选）
  final List<String> difficulties = ['零基础', '入门级', '有难度'];
  List<String> selectedDifficulties = [];

  // 偏好时长（分钟）（多选）
  final List<int> durations = [1, 2, 3,4, 5, 10];
  List<int> selectedDurations = [];

  // 节奏偏好（多选）
  final List<String> paceOptions = ['快', '中', '慢'];
  List<String> selectedPaces = [];

  // 运动类型偏好（多选）
  final List<String> sportTypes = ['静态拉伸', '动态拉伸', '有氧运动', '微力量锻炼', '关节活动', '眼部放松', '按摩放松', '体态矫正','深呼吸'];
  List<String> selectedSportTypes = [];

  // 运动场景偏好（多选）
  final List<String> scenes = ['办公久坐', '通勤间隙', '睡前放松', '起床唤醒', '用眼过度', '长时间用手', '饭后消食','运动后拉伸'];
  List<String> selectedScenes = [];

  // 特殊情况（多选）
  final List<String> specialConditions = ['颈椎病', '腰椎间盘突出', '膝关节损伤', '高血压', '孕妇', '肩周炎'];
  List<String> selectedConditions = [];
  String customCondition = '';

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('运动偏好设置'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('运动偏好设置'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _savePreferences,
            icon: _isSaving 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
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
            _buildMultiSelectChips(
              items: difficulties,
              selectedItems: selectedDifficulties,
              onChanged: (item, selected) {
                setState(() {
                  if (selected) {
                    if (!selectedDifficulties.contains(item)) {
                      selectedDifficulties = [...selectedDifficulties, item];
                    }
                  } else {
                    selectedDifficulties = selectedDifficulties.where((i) => i != item).toList();
                  }
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

            // 节奏偏好
            _buildSectionTitle('节奏偏好'),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '偏好动作的节奏速度',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaceSelector(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 特殊情况
            _buildSectionTitle('特殊情况'),
            _buildSpecialConditions(),

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



  Widget _buildDurationSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: durations.map((duration) {
        final isSelected = selectedDurations.contains(duration);
        return FilterChip(
          label: Text('$duration分钟'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                if (!selectedDurations.contains(duration)) {
                  selectedDurations = [...selectedDurations, duration];
                }
              } else {
                selectedDurations = selectedDurations.where((d) => d != duration).toList();
              }
            });
          },
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



  Widget _buildPaceSelector() {
    final List<String> paceOptions = ['快', '中', '慢'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: paceOptions.map((pace) {
        final isSelected = selectedPaces.contains(pace);
        return FilterChip(
          label: Text(pace),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                if (!selectedPaces.contains(pace)) {
                  selectedPaces = [...selectedPaces, pace];
                }
              } else {
                selectedPaces = selectedPaces.where((p) => p != pace).toList();
              }
            });
          },
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

  Widget _buildSpecialConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 预设特殊情况选项
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: specialConditions.map((condition) {
            final isSelected = selectedConditions.contains(condition);
            return FilterChip(
              label: Text(condition),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    if (!selectedConditions.contains(condition)) {
                      selectedConditions = [...selectedConditions, condition];
                    }
                  } else {
                    selectedConditions = selectedConditions.where((c) => c != condition).toList();
                  }
                });
              },
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue,
              backgroundColor: Colors.grey[100],
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 16),
        
        // 自定义特殊情况输入
        TextFormField(
          initialValue: customCondition,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: '其他特殊情况（可自行填写，用逗号分隔）',
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onChanged: (value) => customCondition = value,
        ),
        
        const SizedBox(height: 8),
        
        Text(
          '例如：糖尿病、心脏病、骨质疏松等',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
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

  // 从后端加载用户偏好
  Future<void> _loadUserPreferences() async {
    try {
      final userId = await StorageService.getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('用户未登录');
      }

      final response = await _apiService.get('/user/preferences', params: {'userId': userId});
      
      if (response != null && response['code'] == 200) {
        final List<dynamic> preferences = response['data'];
        
        // 清空当前选择
        setState(() {
          selectedBodyParts = [];
          selectedDifficulties = [];
          selectedDurations = [];
          selectedPaces = [];
          selectedSportTypes = [];
          selectedScenes = [];
          selectedConditions = [];
          customCondition = '';
        });

        // 解析偏好数据
        for (final pref in preferences) {
          final key = pref['preferenceKey'] as String;
          final value = pref['preferenceValue'] as List<dynamic>;
          final stringValues = value.map((v) => v.toString()).toList();

          switch (key) {
            case 'body_part':
              setState(() {
                selectedBodyParts = stringValues;
              });
              break;
            case 'difficulty':
              setState(() {
                selectedDifficulties = stringValues;
              });
              break;
            case 'sport_type':
              setState(() {
                selectedSportTypes = stringValues;
              });
              break;
            case 'scene':
              setState(() {
                selectedScenes = stringValues;
              });
              break;
            case 'duration':
              setState(() {
                selectedDurations = stringValues.map((v) {
                  // 处理"5分钟"格式，提取数字
                  final match = RegExp(r'(\d+)').firstMatch(v);
                  return match != null ? int.parse(match.group(1)!) : 5;
                }).toList();
              });
              break;
            case 'special_case':
              // 分离预设条件和自定义条件
              final presetConditions = stringValues.where((v) => specialConditions.contains(v)).toList();
              final customConditions = stringValues.where((v) => !specialConditions.contains(v)).toList();
              
              setState(() {
                selectedConditions = presetConditions;
                customCondition = customConditions.isNotEmpty ? customConditions.first : '';
              });
              break;
            case 'pace':
              setState(() {
                selectedPaces = stringValues;
              });
              break;
          }
        }
      }
    } catch (e) {
      print('加载用户偏好失败: $e');
      // 如果加载失败，使用默认值
      setState(() {
        selectedBodyParts = ['全身', '大臂'];
        selectedDifficulties = ['零基础'];
        selectedDurations = [2];
        selectedPaces = ['中'];
        selectedSportTypes = ['静态拉伸', '有氧运动'];
        selectedScenes = ['办公久坐', '通勤间隙'];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 保存偏好到后端
  Future<void> _savePreferences() async {
    try {
      setState(() {
        _isSaving = true;
      });

      final userId = await StorageService.getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('用户未登录');
      }

      // 构建偏好数据
      final List<Map<String, dynamic>> preferences = [];

      // 身体部位
      preferences.add({
        'preferenceKey': 'body_part',
        'preferenceValue': selectedBodyParts,
      });

      // 难度
      preferences.add({
        'preferenceKey': 'difficulty',
        'preferenceValue': selectedDifficulties,
      });

      // 运动类型
      preferences.add({
        'preferenceKey': 'sport_type',
        'preferenceValue': selectedSportTypes,
      });

      // 场景
      preferences.add({
        'preferenceKey': 'scene',
        'preferenceValue': selectedScenes,
      });

      // 时长（转换为"X分钟"格式）
      preferences.add({
        'preferenceKey': 'duration',
        'preferenceValue': selectedDurations.map((d) => '$d分钟').toList(),
      });

      // 特殊情况（合并预设和自定义）
      final List<String> allSpecialCases = [...selectedConditions];
      if (customCondition.isNotEmpty) {
        allSpecialCases.add(customCondition);
      }
      preferences.add({
        'preferenceKey': 'special_case',
        'preferenceValue': allSpecialCases,
      });

      // 节奏
      preferences.add({
        'preferenceKey': 'pace',
        'preferenceValue': selectedPaces,
      });

      // 发送到后端
      final response = await _apiService.post('/user/preferences?userId=$userId', {
        'preferences': preferences,
      });

      if (response != null && response['code'] == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('运动偏好已保存'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(response?['message'] ?? '保存失败');
      }
    } catch (e) {
      print('保存用户偏好失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}