// 首次登录用户调查问卷
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../models/user_model.dart';
import '../../models/preference_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import '../../utils/validators.dart';

class OnboardingSurveyScreen extends StatefulWidget {
  const OnboardingSurveyScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  // 用户基本信息
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _gender = '男';
  final List<String> _genders = ['男', '女'];

  // 特殊健康状况
  final List<String> _specialConditions = [];
  final List<String> _availableConditions = [
    '脊椎病', '腰椎间盘突出', '膝关节损伤', '高血压', '孕妇', '肩周炎', '其他'
  ];
  String? _otherConditionText;
  bool _showOtherInput = false;
  final TextEditingController _otherConditionController = TextEditingController();

  // 提醒设置
  bool _remindEnabled = false;
  final TextEditingController _remindIntervalController = TextEditingController(text: '60');
  final TextEditingController _remindMaxTimesController = TextEditingController(text: '5');

  // 免打扰时段
  final List<Map<String, String>> _avoidTimes = [];

  // 运动偏好（可选）
  final List<String> _preferredBodyParts = [];
  final List<String> _availableBodyParts = [
    '头部', '颈部','左肩', '右肩', '胸背', '腰部', '胯部', '左手臂','右手臂','左手', '右手', '左腿', '右腿', '左膝盖','右膝盖','左脚踝','右脚踝'
  ];

  final List<String> _exerciseScenarios = [];
  final List<String> _availableScenarios = [
    '办公久坐', '通勤间隙', '睡前放松', '起床唤醒', '用眼过度', '长时间用手', '饭后消食','运动后拉伸'
  ];

  final List<String> _sportTypes = [];
  final List<String> _availableSportTypes = [
    '静态拉伸', '动态拉伸', '有氧运动', '微力量锻炼', '关节活动', '眼部放松', '按摩放松', '体态矫正','深呼吸'
  ];

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('欢迎使用跬步千里'),
        automaticallyImplyLeading: false, // 禁用返回按钮
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 欢迎信息
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  '为了给您提供个性化的运动建议，请先完成以下基本信息调查',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),

              // 基本信息部分
              _buildSectionTitle('基本信息'),
              _buildBasicInfoSection(),

              const SizedBox(height: 24),

              // 特殊健康状况部分
              _buildSectionTitle('特殊健康状况（可选）'),
              _buildSpecialConditionsSection(),

              const SizedBox(height: 24),

              // 提醒设置部分
              _buildSectionTitle('久坐提醒设置'),
              _buildReminderSection(),

              const SizedBox(height: 24),

              // 运动偏好部分（可选）
              _buildSectionTitle('运动偏好（可选）'),
              _buildPreferencesSection(),

              const SizedBox(height: 32),

              // 提交按钮
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                text: '完成并开始使用',
                onPressed: _submitSurvey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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

  Widget _buildBasicInfoSection() {
    return Column(
      children: [
        // 身高
        CustomTextField(
          controller: _heightController,
          labelText: '身高 (cm)',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入身高';
            }
            final height = double.tryParse(value);
            if (height == null || height < 50 || height > 250) {
              return '请输入有效的身高 (50-250cm)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // 体重
        CustomTextField(
          controller: _weightController,
          labelText: '体重 (kg)',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入体重';
            }
            final weight = double.tryParse(value);
            if (weight == null || weight < 20 || weight > 300) {
              return '请输入有效的体重 (20-300kg)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // 年龄
        CustomTextField(
          controller: _ageController,
          labelText: '年龄',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入年龄';
            }
            final age = int.tryParse(value);
            if (age == null || age < 1 || age > 120) {
              return '请输入有效的年龄 (1-120岁)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // 性别
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '性别',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              children: _genders.map((gender) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text(gender),
                      selected: _gender == gender,
                      onSelected: (selected) {
                        setState(() {
                          _gender = gender;
                        });
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpecialConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '请选择您已有的健康状况（可多选）',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableConditions.map((condition) {
            return FilterChip(
              label: Text(condition),
              selected: _specialConditions.contains(condition),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _specialConditions.add(condition);
                    // 如果选择的是"其他"，显示输入框
                    if (condition == '其他') {
                      _showOtherInput = true;
                    }
                  } else {
                    _specialConditions.remove(condition);
                    // 如果取消选择"其他"，隐藏输入框并清空内容
                    if (condition == '其他') {
                      _showOtherInput = false;
                      _otherConditionController.clear();
                      _otherConditionText = null;
                    }
                  }
                });
              },
            );
          }).toList(),
        ),

        // 其他条件输入框
        if (_showOtherInput) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '请输入其他健康状况:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _otherConditionController,
                    decoration: InputDecoration(
                      hintText: '例如: 糖尿病，哮喘等',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      _otherConditionText = value.trim();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '多个健康状况请用逗号分隔',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReminderSection() {
    return Column(
      children: [
        // 提醒开关
        SwitchListTile(
          title: const Text('启用久坐提醒'),
          value: _remindEnabled,
          onChanged: (value) {
            setState(() {
              _remindEnabled = value;
            });
          },
        ),

        if (_remindEnabled) ...[
          const SizedBox(height: 16),

          // 提醒间隔
          CustomTextField(
            controller: _remindIntervalController,
            labelText: '提醒间隔 (分钟)',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_remindEnabled && (value == null || value.isEmpty)) {
                return '请输入提醒间隔';
              }
              if (_remindEnabled) {
                final interval = int.tryParse(value!);
                if (interval == null || interval < 1 || interval > 480) {
                  return '请输入有效的间隔 (1-480分钟)';
                }
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 最大提醒次数
          CustomTextField(
            controller: _remindMaxTimesController,
            labelText: '每日最大提醒次数',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (_remindEnabled && (value == null || value.isEmpty)) {
                return '请输入最大提醒次数';
              }
              if (_remindEnabled) {
                final maxTimes = int.tryParse(value!);
                if (maxTimes == null || maxTimes < 1 || maxTimes > 50) {
                  return '请输入有效的次数 (1-50次)';
                }
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // 免打扰时段
          _buildAvoidTimesSection(),
        ],
      ],
    );
  }

  Widget _buildAvoidTimesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '免打扰时间段',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: _addAvoidTime,
              icon: const Icon(Icons.add),
              tooltip: '添加时间段',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._avoidTimes.asMap().entries.map((entry) {
          final index = entry.key;
          final time = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      label: '开始时间',
                      value: time['start']!,
                      onChanged: (value) => _updateAvoidTime(index, 'start', value),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('至'),
                  ),
                  Expanded(
                    child: _buildTimePicker(
                      label: '结束时间',
                      value: time['end']!,
                      onChanged: (value) => _updateAvoidTime(index, 'end', value),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeAvoidTime(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: '删除',
                  ),
                ],
              ),
            ),
          );
        }),
        if (_avoidTimes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '暂无免打扰时间段',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String value,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final time = value.split(':');
            final initialTime = TimeOfDay(
              hour: int.parse(time[0]),
              minute: int.parse(time[1]),
            );

            final selectedTime = await showTimePicker(
              context: context,
              initialTime: initialTime,
            );

            if (selectedTime != null) {
              final formattedTime =
                  '${selectedTime.hour.toString().padLeft(2, '0')}:'
                  '${selectedTime.minute.toString().padLeft(2, '0')}';
              onChanged(formattedTime);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.access_time, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _addAvoidTime() {
    setState(() {
      _avoidTimes.add({
        'start': '09:00',
        'end': '12:00',
      });
    });
  }

  void _updateAvoidTime(int index, String key, String value) {
    setState(() {
      _avoidTimes[index][key] = value;
    });
  }

  void _removeAvoidTime(int index) {
    setState(() {
      _avoidTimes.removeAt(index);
    });
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 偏好身体部位
        const Text(
          '偏好锻炼的身体部位（可多选）',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableBodyParts.map((part) {
            return FilterChip(
              label: Text(part),
              selected: _preferredBodyParts.contains(part),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _preferredBodyParts.add(part);
                  } else {
                    _preferredBodyParts.remove(part);
                  }
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 运动场景
        const Text(
          '主要运动场景（可多选）',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableScenarios.map((scenario) {
            return FilterChip(
              label: Text(scenario),
              selected: _exerciseScenarios.contains(scenario),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _exerciseScenarios.add(scenario);
                  } else {
                    _exerciseScenarios.remove(scenario);
                  }
                });
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 16),

        // 运动类型
        const Text(
          '偏好的运动类型（可多选）',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableSportTypes.map((sport) {
            return FilterChip(
              label: Text(sport),
              selected: _sportTypes.contains(sport),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _sportTypes.add(sport);
                  } else {
                    _sportTypes.remove(sport);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _submitSurvey() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 更新用户基本信息（使用现有的updateUserInfo方法）
      final userUpdateSuccess = await _authService.updateUserInfo(
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        age: int.tryParse(_ageController.text),
        gender: _gender,
        remindEnabled: _remindEnabled,
        remindInterval: _remindEnabled ? int.tryParse(_remindIntervalController.text) : null,
        remindMaxTimes: _remindEnabled ? int.tryParse(_remindMaxTimesController.text) : null,
        remindAvoidTime: _remindEnabled && _avoidTimes.isNotEmpty ? _avoidTimes : null,
      );

      if (!userUpdateSuccess) {
        throw Exception('用户信息更新失败');
      }

      // 2. 保存运动偏好（使用现有的/user/preferences API）
      final userId = await StorageService.getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('用户未登录');
      }

      // 构建偏好数据，格式与preference_screen.dart保持一致
      final List<Map<String, dynamic>> preferences = [];

      // 身体部位偏好
      if (_preferredBodyParts.isNotEmpty) {
        preferences.add({
          'preferenceKey': 'body_part',
          'preferenceValue': _preferredBodyParts,
        });
      }

      // 运动类型偏好
      if (_sportTypes.isNotEmpty) {
        preferences.add({
          'preferenceKey': 'sport_type',
          'preferenceValue': _sportTypes,
        });
      }

      // 运动场景偏好
      if (_exerciseScenarios.isNotEmpty) {
        preferences.add({
          'preferenceKey': 'scene',
          'preferenceValue': _exerciseScenarios,
        });
      }

      // 特殊情况（健康状况）
      if (_specialConditions.isNotEmpty) {
        List<String> finalConditions = List.from(_specialConditions);

        // 如果选择了"其他"并且有输入内容，处理其他条件
        if (_specialConditions.contains('其他') &&
            _otherConditionText != null &&
            _otherConditionText!.isNotEmpty) {
          // 移除"其他"选项
          finalConditions.remove('其他');

          // 分割用户输入的多个条件（按逗号分隔）
          final otherConditions = _otherConditionText!
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          // 添加用户输入的其他条件
          finalConditions.addAll(otherConditions);
        } else if (_specialConditions.contains('其他') &&
            (_otherConditionText == null || _otherConditionText!.isEmpty)) {
          // 如果选择了"其他"但没有输入内容，移除"其他"选项
          finalConditions.remove('其他');
        }

        // 只有当有实际条件时才添加
        if (finalConditions.isNotEmpty) {
          preferences.add({
            'preferenceKey': 'special_case',
            'preferenceValue': finalConditions,
          });
        }
      }

      // 如果有偏好数据，则保存
      if (preferences.isNotEmpty) {
        final preferenceResponse = await _apiService.post('/user/preferences?userId=$userId', {
          'preferences': preferences,
        });

        if (preferenceResponse == null || preferenceResponse['code'] != 200) {
          throw Exception('偏好设置保存失败: ${preferenceResponse?['message']}');
        }
      }

      // 3. 标记调查已完成（仅本地标记）
      await StorageService.markOnboardingCompleted();

      // 4. 跳转到主界面
      if (mounted) {
        context.go('/app_screen');
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _remindIntervalController.dispose();
    _remindMaxTimesController.dispose();
    _otherConditionController.dispose();
    super.dispose();
  }
}