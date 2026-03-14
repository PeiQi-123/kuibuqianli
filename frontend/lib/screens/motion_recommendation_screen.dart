// 微运动推荐页面
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class MotionRecommendationScreen extends StatefulWidget {
  const MotionRecommendationScreen({super.key});

  @override
  State<MotionRecommendationScreen> createState() => _MotionRecommendationScreenState();
}

class _MotionRecommendationScreenState extends State<MotionRecommendationScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  String _selectedBodyPart = '颈部';
  String _selectedActivity = '久坐';
  int _selectedDuration = 5;
  String _selectedIntensity = 'low';
  
  Map<String, dynamic>? _motionResult;
  Map<String, dynamic>? _learningInsights;
  bool _isLoading = false;

  final List<String> _bodyParts = ['颈部', '肩部', '腰部', '背部', '腿部', '手腕'];

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
      appBar: AppBar(
        title: const Text('微运动推荐'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
              '选择目标部位',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              '选择您的活动类型',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                      Icon(activity['icon'], size: 18),
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
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              '选择运动时长',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              '选择运动强度',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _intensities.map((intensity) {
                final isSelected = _selectedIntensity == intensity['value'];
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(intensity['icon'], size: 18),
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
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _generateMotion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('生成微运动方案'),
              ),
            ),
            const SizedBox(height: 24),
            if (_motionResult != null) _buildMotionResult(),
          ],
        ),
      ),
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
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.blue, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    motion['title']?.toString() ?? '$_selectedBodyPart AI 微运动方案',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              motion['overview']?.toString() ?? '基于真实 AI 接口生成的个性化建议',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${duration ?? 0} 秒', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(width: 16),
                Icon(Icons.tune, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(difficulty, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const Divider(height: 24),
            const Text(
              '推荐动作',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...actions.asMap().entries.map((entry) {
              final action = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blue,
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              action['name']?.toString() ?? '未命名动作',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text('${action['seconds'] ?? 20} 秒'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('做法：${action['instruction'] ?? '请跟随视频指导完成动作。'}'),
                      const SizedBox(height: 6),
                      Text(
                        '注意：${action['warning'] ?? '如有不适请立即停止。'}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if ((motion['tip']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '提示：${motion['tip']}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
            if (_learningInsights != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '动态学习：${_learningInsights!['summary'] ?? '已结合近期训练记录优化推荐结果'}',
                  style: TextStyle(color: Colors.blue.shade900),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/video_player', extra: motionData);
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('查看视频指导'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/posture_detection');
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('开始检测'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
