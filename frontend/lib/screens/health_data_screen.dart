import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'package:go_router/go_router.dart';
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          '健康数据',
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _healthData == null
            ? _buildEmptyState()
            : RefreshIndicator(
          onRefresh: _loadHealthData,
          color: Colors.blue,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    _buildProfileSummary(),
                    const SizedBox(height: 16),
                    _buildStatGrid(),
                    const SizedBox(height: 16),
                    _buildBmiCard(),
                    const SizedBox(height: 16),
                    _buildRecentRecordsCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.insights_outlined,
                  size: 48,
                  color: Colors.blue.shade400,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '暂时还没有可展示的健康数据',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '先完善用户信息，或完成几次微运动后再回来查看。',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/user_info'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('完善用户信息'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSummary() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  '身体概览',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  '运动统计',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
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
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: item.$4.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.$3, color: item.$4, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.$2,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$1,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            Row(
              children: [
                Icon(Icons.monitor_weight_outlined, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  'BMI 状态',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _healthData!['bmi']?.toString() ?? '未生成',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _healthData!['bmiType']?.toString() ?? '请先补全身高体重',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _bmiColor((_healthData!['bmiType'] ?? '').toString()).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '完成率 ${_healthData!['completionRate'] ?? 0}%',
                    style: TextStyle(
                      color: _bmiColor((_healthData!['bmiType'] ?? '').toString()),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            // BMI 指示器
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: (_healthData!['bmi'] != null) ? 0.7 : 0, // 示例值，可根据实际BMI计算
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(_bmiColor((_healthData!['bmiType'] ?? '').toString())),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRecordsCard() {
    final records = (_healthData!['recentRecords'] as List<dynamic>? ?? []);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
            Row(
              children: [
                Icon(Icons.history_outlined, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                const Text(
                  '最近运动记录',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (records.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.sports_gymnastics, size: 40, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      '还没有运动记录',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '完成一次微运动后这里会自动出现',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: records.map((item) {
                  final record = item as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (record['completed'] == true ? Colors.green : Colors.orange).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          record['completed'] == true ? Icons.check : Icons.schedule,
                          color: record['completed'] == true ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        record['motionName']?.toString().isNotEmpty == true
                            ? record['motionName'].toString()
                            : '未命名微运动',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        '${record['createdAt'] ?? '--'} · ${record['duration'] ?? 0}秒',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (record['completed'] == true ? Colors.green : Colors.orange).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          record['completed'] == true ? '已完成' : '未完成',
                          style: TextStyle(
                            color: record['completed'] == true ? Colors.green : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
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