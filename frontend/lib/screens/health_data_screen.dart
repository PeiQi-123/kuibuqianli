import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';

class HealthDataScreen extends StatefulWidget {
  const HealthDataScreen({super.key});

  @override
  State<HealthDataScreen> createState() => _HealthDataScreenState();
}

class _HealthDataScreenState extends State<HealthDataScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _healthData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    setState(() => _isLoading = true);
    try {
      final userId = await StorageService.getUserId();
      if (userId == null || userId.isEmpty) {
        setState(() {
          _healthData = null;
          _isLoading = false;
        });
        return;
      }

      final response = await _apiService.get('/user/health-data', params: {'userId': userId});
      setState(() {
        _healthData = response != null && response['code'] == 200 ? response['data'] : null;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _healthData = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('健康数据'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _healthData == null
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHealthData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildProfileSummary(),
                      const SizedBox(height: 16),
                      _buildStatGrid(),
                      const SizedBox(height: 16),
                      _buildBmiCard(),
                      const SizedBox(height: 16),
                      _buildRecentRecordsCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insights_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('暂时还没有可展示的健康数据', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('先完善用户信息，或完成几次微运动后再回来查看。', style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('身体概览', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildInfoChip('身高', _formatNumber(_healthData!['height'], 'cm')),
                _buildInfoChip('体重', _formatNumber(_healthData!['weight'], 'kg')),
                _buildInfoChip('年龄', _healthData!['age']?.toString() ?? '未填写'),
                _buildInfoChip('性别', _healthData!['gender']?.toString() ?? '未填写'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid() {
    final stats = [
      ('累计运动', '${_healthData!['totalSessions'] ?? 0}次', Icons.fitness_center, Colors.blue),
      ('完成次数', '${_healthData!['completedSessions'] ?? 0}次', Icons.check_circle, Colors.green),
      ('累计时长', '${_healthData!['totalDurationMinutes'] ?? 0}分钟', Icons.timer, Colors.orange),
      ('近7天活跃', '${_healthData!['last7DaysSessions'] ?? 0}次', Icons.calendar_today, Colors.purple),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (context, index) {
        final item = stats[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.$3, color: item.$4),
                const SizedBox(height: 10),
                Text(item.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(item.$1, style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBmiCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BMI 状态', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _healthData!['bmi']?.toString() ?? '未生成',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(_healthData!['bmiType']?.toString() ?? '请先补全身高体重', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _bmiColor((_healthData!['bmiType'] ?? '').toString()).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '完成率 ${_healthData!['completionRate'] ?? 0}%',
                    style: TextStyle(color: _bmiColor((_healthData!['bmiType'] ?? '').toString()), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecordsCard() {
    final records = (_healthData!['recentRecords'] as List<dynamic>? ?? []);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('最近运动记录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (records.isEmpty)
              Text('还没有运动记录，完成一次微运动后这里会自动出现。', style: TextStyle(color: Colors.grey[600]))
            else
              ...records.map((item) {
                final record = item as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: (record['completed'] == true ? Colors.green : Colors.orange).withValues(alpha: 0.15),
                    child: Icon(record['completed'] == true ? Icons.check : Icons.schedule, color: record['completed'] == true ? Colors.green : Colors.orange),
                  ),
                  title: Text(record['motionName']?.toString().isNotEmpty == true ? record['motionName'].toString() : '未命名微运动'),
                  subtitle: Text('${record['createdAt'] ?? '--'} · ${record['duration'] ?? 0}秒'),
                  trailing: Text(record['completed'] == true ? '已完成' : '未完成'),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatNumber(dynamic value, String unit) {
    if (value == null) {
      return '未填写';
    }
    return '$value $unit';
  }

  Color _bmiColor(String bmiType) {
    switch (bmiType) {
      case '正常':
        return Colors.green;
      case '偏胖':
        return Colors.orange;
      case '肥胖':
        return Colors.red;
      case '偏瘦':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
