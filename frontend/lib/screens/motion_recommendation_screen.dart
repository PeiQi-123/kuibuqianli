// 微运动推荐页面
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/body_part_catalog.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class MotionRecommendationScreen extends StatefulWidget {
  const MotionRecommendationScreen({super.key, this.initialBodyPart});

  final String? initialBodyPart;

  @override
  State<MotionRecommendationScreen> createState() => _MotionRecommendationScreenState();
}

class _MotionRecommendationScreenState extends State<MotionRecommendationScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  late String _selectedBodyPart;
  String _selectedActivity = '久坐';
  int _selectedDuration = 5;
  String _selectedIntensity = 'low';

  Map<String, dynamic>? _motionResult;
  Map<String, dynamic>? _learningInsights;
  bool _isLoading = false;

  final List<String> _bodyParts = BodyPartCatalog.recommendationBodyParts;

  final List<Map<String, dynamic>> _activityTypes = [
    {'value': '久坐', 'label': '久坐', 'icon': Icons.computer},
    {'value': '工作', 'label': '工作', 'icon': Icons.work},
    {'value': '休息', 'label': '休息', 'icon': Icons.self_improvement},
    {'value': '学习', 'label': '学习', 'icon': Icons.menu_book},
  ];

  final List<int> _durations = [3, 5, 10, 15];
  final List<Map<String, dynamic>> _intensities = [
    {'value': 'low', 'label': '低强度', 'icon': Icons.directions_walk},
    {'value': 'medium', 'label': '中强度', 'icon': Icons.directions_run},
    {'value': 'high', 'label': '高强度', 'icon': Icons.fitness_center},
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialBodyPart;
    _selectedBodyPart = _bodyParts.contains(initial) ? initial! : _bodyParts.first;
  }

  Future<void> _generateMotion() async {
    setState(() {
      _isLoading = true;
      _motionResult = null;
    });

    try {
      final currentUser = await _authService.getCurrentUser();
      if (currentUser?.id != null) {
        final insights = await _apiService.get(
          '/user/preferences/insights',
          params: {'userId': currentUser!.id!},
        );
        if (insights != null && insights['code'] == 200 && insights['data'] is Map<String, dynamic>) {
          _learningInsights = insights['data'] as Map<String, dynamic>;
        }
      }
      final response = await _apiService.post('/micro-motion/generate-prompt', {
        'body_part': _selectedBodyPart,
        'posture_info': _buildPostureInfo(),
        'user_info': _buildUserInfo(currentUser),
      });

      setState(() {
        if (response != null && response['status'] == 'success') {
          _motionResult = response;
        } else {
          _motionResult = null;
        }
        _isLoading = false;
      });

      if (response == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('生成失败，请检查后端 AI 服务配置')),
        );
      } else if (response != null && response['status'] != 'success' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error_message']?.toString() ?? '生成失败')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          '微运动推荐',
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
                        Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '根据您的选择，小跬将为您生成个性化的微运动方案',
                            style: TextStyle(color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 选择目标部位
                  _buildSectionTitle('选择目标部位', Icons.psychology_outlined),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _bodyParts.map((bodyPart) {
                      final isSelected = _selectedBodyPart == bodyPart;
                      return ChoiceChip(
                        label: Text(bodyPart),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedBodyPart = bodyPart);
                          }
                        },
                        selectedColor: Colors.blue.shade100,
                        backgroundColor: Colors.grey.shade50,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 选择活动类型
                  _buildSectionTitle('选择您的活动类型', Icons.accessibility_new_outlined),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activityTypes.map((activity) {
                      final isSelected = _selectedActivity == activity['value'];
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(activity['icon'], size: 18, color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(activity['label']),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedActivity = activity['value']);
                          }
                        },
                        selectedColor: Colors.blue.shade100,
                        backgroundColor: Colors.grey.shade50,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 选择运动时长
                  _buildSectionTitle('选择运动时长', Icons.timer_outlined),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _durations.map((duration) {
                      final isSelected = _selectedDuration == duration;
                      return ChoiceChip(
                        label: Text('$duration 分钟'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedDuration = duration);
                          }
                        },
                        selectedColor: Colors.blue.shade100,
                        backgroundColor: Colors.grey.shade50,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 选择运动强度
                  _buildSectionTitle('选择运动强度', Icons.speed_outlined),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _intensities.map((intensity) {
                      final isSelected = _selectedIntensity == intensity['value'];
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(intensity['icon'], size: 18, color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(intensity['label']),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedIntensity = intensity['value']);
                          }
                        },
                        selectedColor: Colors.blue.shade100,
                        backgroundColor: Colors.grey.shade50,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // 生成按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateMotion,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Text(
                        '生成微运动方案',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 生成结果
                  if (_motionResult != null) _buildMotionResult(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
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
    );
  }

  Widget _buildMotionResult() {
    final motion = _motionResult!;
    final actions = (motion['actions'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final duration = motion['suggested_duration'];
    final difficulty = motion['difficulty_level']?.toString() ?? '未提供';
    final motionData = {
      'motion_id': '$_selectedBodyPart-${DateTime.now().millisecondsSinceEpoch}',
      'motion_name': motion['title']?.toString() ?? '$_selectedBodyPart AI 微运动方案',
      'body_part': _selectedBodyPart,
      'description': motion['overview']?.toString() ?? '$_selectedActivity场景 · ${_intensityLabel(_selectedIntensity)} · ${duration ?? _selectedDuration}秒',
      'duration': duration ?? _selectedDuration * 60,
      'actions': actions,
      'steps': actions.map((action) => action['name']?.toString() ?? '').where((name) => name.isNotEmpty).toList(),
      'tip': motion['tip'],
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 方案标题
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    motion['title']?.toString() ?? '$_selectedBodyPart AI 微运动方案',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 方案概述
            Text(
              motion['overview']?.toString() ?? '基于真实 AI 接口生成的个性化建议',
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),

            const SizedBox(height: 12),

            // 方案标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildInfoChip(Icons.timer, '时长', '${duration ?? 0} 秒'),
                  Container(width: 1, height: 20, color: Colors.grey.shade300),
                  _buildInfoChip(Icons.tune, '强度', difficulty),
                ],
              ),
            ),

            const Divider(height: 24),

            // 推荐动作标题
            Row(
              children: [
                Icon(Icons.list_alt, size: 20, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  '推荐动作',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 动作列表
            ...actions.asMap().entries.map((entry) {
              final action = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action['name']?.toString() ?? '未命名动作',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${action['seconds'] ?? 20} 秒',
                              style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '做法：${action['instruction'] ?? '请跟随视频指导完成动作。'}',
                        style: const TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '注意：${action['warning'] ?? '如有不适请立即停止。'}',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            // 提示
            if ((motion['tip']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tips_and_updates, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '提示：${motion['tip']}',
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 学习洞察
            if (_learningInsights != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '动态学习：${_learningInsights!['summary'] ?? '已结合近期训练记录优化推荐结果'}',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/video_player', extra: motionData);
                    },
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text('查看视频指导'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.blue.shade200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/posture_detection');
                    },
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('开始检测'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _buildPostureInfo() {
    final activityDescriptions = {
      '久坐': '久坐办公，肩颈和腰背容易僵硬',
      '工作': '长时间工作中，姿势固定，局部肌肉紧张',
      '休息': '短暂休息阶段，希望快速放松身体',
      '学习': '长时间学习伏案，肩颈和背部压力较大',
    };

    return '${activityDescriptions[_selectedActivity] ?? _selectedActivity}；期望训练时长约$_selectedDuration分钟；强度偏好为${_intensityLabel(_selectedIntensity)}。';
  }

  Map<String, dynamic> _buildUserInfo(dynamic currentUser) {
    final Map<String, dynamic> userInfo = {};
    if (currentUser == null) {
      return userInfo;
    }

    if (currentUser.age != null) userInfo['age'] = currentUser.age;
    if (currentUser.id != null) userInfo['user_id'] = currentUser.id;
    if (currentUser.gender != null && currentUser.gender.toString().isNotEmpty) {
      userInfo['gender'] = currentUser.gender;
    }
    if (currentUser.height != null) userInfo['height'] = currentUser.height;
    if (currentUser.weight != null) userInfo['weight'] = currentUser.weight;
    if (currentUser.bmi != null) userInfo['bmi'] = currentUser.bmi;
    if (currentUser.bmiType != null && currentUser.bmiType.toString().isNotEmpty) {
      userInfo['bmi_type'] = currentUser.bmiType;
    }

    return userInfo;
  }

  String _intensityLabel(String intensity) {
    switch (intensity) {
      case 'high':
        return '高强度';
      case 'medium':
        return '中强度';
      default:
        return '低强度';
    }
  }
}