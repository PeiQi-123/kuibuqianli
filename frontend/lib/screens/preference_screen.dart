// 运动偏好设置页面（简化版）
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 添加这行导入
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
  final List<String> bodyParts = ['头部', '颈部','左肩', '右肩', '胸背', '腰部', '胯部', '左手臂','右手臂','左手', '右手', '左腿', '右腿', '左膝盖','右膝盖','左脚踝','右脚踝'];
  List<String> selectedBodyParts = [];

  // 动作难度偏好（多选）
  final List<String> difficulties = ['零基础', '入门级', '有难度'];
  List<String> selectedDifficulties = [];

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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            '运动偏好设置',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              letterSpacing: 1,
            ),
          ),
          backgroundColor: Colors.white.withOpacity(0.8),
          elevation: 0,
          foregroundColor: Colors.black87,
          centerTitle: true,
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          '运动偏好设置',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 1,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _isSaving ? null : _savePreferences,
              icon: _isSaving
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
              tooltip: '保存偏好',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 页面说明
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '设置您的运动偏好，小跬将为您提供更个性化的运动推荐',
                            style: TextStyle(color: Colors.blue.shade700, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 身体部位偏好
                  _buildSectionTitle('偏好的身体部位', Icons.accessibility_new_outlined),
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
                  _buildSectionTitle('偏好的动作难度', Icons.trending_up_outlined),
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

                  // 运动类型偏好
                  _buildSectionTitle('偏好的运动类型', Icons.fitness_center_outlined),
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
                  _buildSectionTitle('偏好的运动场景', Icons.location_city_outlined),
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

                  // 特殊情况
                  _buildSectionTitle('特殊情况', Icons.health_and_safety_outlined),
                  _buildSpecialConditions(),

                  const SizedBox(height: 32),

                  // 保存按钮
                  _buildSaveButton(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
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
          backgroundColor: Colors.grey.shade50,
          side: BorderSide(
            color: isSelected ? Colors.blue.shade200 : Colors.grey.shade300,
            width: 1,
          ),
          labelStyle: TextStyle(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            fontSize: 13,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              backgroundColor: Colors.grey.shade50,
              side: BorderSide(
                color: isSelected ? Colors.blue.shade200 : Colors.grey.shade300,
                width: 1,
              ),
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 自定义特殊情况输入
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            initialValue: customCondition,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: '其他特殊情况（可自行填写，用逗号分隔）',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
              hintStyle: TextStyle(color: Colors.grey.shade500),
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: (value) => customCondition = value,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
              const SizedBox(width: 4),
              Text(
                '例如：糖尿病、心脏病、骨质疏松等',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _savePreferences,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: _isSaving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.save),
        label: Text(
          _isSaving ? '保存中...' : '保存运动偏好',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
            case 'special_case':
            // 分离预设条件和自定义条件
              final presetConditions = stringValues.where((v) => specialConditions.contains(v)).toList();
              final customConditions = stringValues.where((v) => !specialConditions.contains(v)).toList();

              setState(() {
                selectedConditions = presetConditions;
                customCondition = customConditions.isNotEmpty ? customConditions.first : '';
              });
              break;
          }
        }
      }
    } catch (e) {
      print('加载用户偏好失败: $e');
      // 如果加载失败，使用默认值
      setState(() {
        selectedBodyParts = [];
        selectedDifficulties = [];
        selectedSportTypes = [];
        selectedScenes = [];
        selectedConditions = [];
        customCondition = '';
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
      if (selectedBodyParts.isNotEmpty) {
        preferences.add({
          'preferenceKey': 'body_part',
          'preferenceValue': selectedBodyParts,
        });
      }

      // 难度
      if (selectedDifficulties.isNotEmpty) {
        preferences.add({
          'preferenceKey': 'difficulty',
          'preferenceValue': selectedDifficulties,
        });
      }

      // 运动类型
      if (selectedSportTypes.isNotEmpty) {
        preferences.add({
          'preferenceKey': 'sport_type',
          'preferenceValue': selectedSportTypes,
        });
      }

      // 场景
      if (selectedScenes.isNotEmpty) {
        preferences.add({
          'preferenceKey': 'scene',
          'preferenceValue': selectedScenes,
        });
      }

      // 特殊情况（合并预设和自定义）
      final List<String> allSpecialCases = [...selectedConditions];
      if (customCondition.trim().isNotEmpty) {
        allSpecialCases.add(customCondition.trim());
      }
      if (allSpecialCases.isNotEmpty) {
        preferences.add({
          'preferenceKey': 'special_case',
          'preferenceValue': allSpecialCases,
        });
      }

      // 发送到后端
      final response = await _apiService.post('/user/preferences?userId=$userId', {
        'preferences': preferences,
      });

      if (response != null && response['code'] == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('运动偏好已保存'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('保存失败: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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