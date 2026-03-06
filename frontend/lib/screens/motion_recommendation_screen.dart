// 微运动推荐页面
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../widgets/loading_indicator.dart';

class MotionRecommendationScreen extends StatefulWidget {
  const MotionRecommendationScreen({super.key});

  @override
  State<MotionRecommendationScreen> createState() => _MotionRecommendationScreenState();
}

class _MotionRecommendationScreenState extends State<MotionRecommendationScreen> {
  final ApiService _apiService = ApiService();
  
  String _selectedActivity = '久坐';
  int _selectedDuration = 5;
  String _selectedIntensity = 'low';
  
  Map<String, dynamic>? _motionResult;
  bool _isLoading = false;

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
      final response = await _apiService.post('/motion/generate', {
        'activity_type': _selectedActivity,
        'duration': _selectedDuration,
        'intensity': _selectedIntensity,
      });

      setState(() {
        if (response != null && response['code'] == 200) {
          _motionResult = response['data'];
        } else {
          _motionResult = null;
        }
        _isLoading = false;
      });
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
    final steps = motion['steps'] as List<dynamic>? ?? [];
    
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
                    motion['motion_name'] ?? '微运动',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              motion['description'] ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${motion['duration'] ?? 0} 分钟', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const Divider(height: 24),
            const Text(
              '运动步骤',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...steps.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    Expanded(child: Text(entry.value.toString())),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.push('/video_player', extra: motion);
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
}
