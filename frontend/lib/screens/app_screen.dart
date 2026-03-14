// lib/screens/app_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/sedentary_reminder_service.dart';
import 'user_center_screen.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    SedentaryReminderService.instance.initialize();
    SedentaryReminderService.instance.refreshConfig();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      // 功能首页
      Scaffold(
        appBar: AppBar(
          title: const Text('跬步千里'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: SedentaryReminderService.instance,
                builder: (context, _) => _buildReminderCard(context),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildMenuCard(
                      context,
                      icon: Icons.fitness_center,
                      title: '微运动推荐',
                      subtitle: 'AI 智能推荐运动方案',
                      color: Colors.blue,
                      onTap: () => context.push('/motion_recommendation'),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.videocam,
                      title: '视频指导',
                      subtitle: '观看运动教学视频',
                      color: Colors.orange,
                      onTap: () => context.push('/choose_part_of_body'),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.camera_alt,
                      title: '姿态检测',
                      subtitle: '实时检测运动姿态',
                      color: Colors.green,
                      onTap: () => context.push('/posture_detection'),
                    ),
                    _buildMenuCard(
                      context,
                      icon: Icons.bar_chart,
                      title: '健康数据',
                      subtitle: '查看运动统计数据',
                      color: Colors.purple,
                      onTap: () => context.push('/health_data'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      
      // 用户中心
      const UserCenterScreen(),
    ];

    return Scaffold(
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '用户中心',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(BuildContext context) {
    final reminderState = SedentaryReminderService.instance.state;
    return Card(
      elevation: 2,
      color: reminderState.enabled
          ? _reminderCardColor(reminderState.warningLevel)
          : const Color(0xFFF5F5F5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  reminderState.enabled ? Icons.notifications_active : Icons.notifications_off,
                  color: reminderState.enabled ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  reminderState.enabled ? '久坐提醒已开启' : '久坐提醒未开启',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(reminderState.statusText),
            const SizedBox(height: 8),
            Text('当前久坐时长：${reminderState.sedentaryMinutes} 分钟'),
            Text('提醒间隔：${reminderState.intervalMinutes} 分钟'),
            Text('今日已提醒：${reminderState.remindersSentToday}/${reminderState.maxRemindersPerDay} 次'),
            Text('当前预警等级：${_warningLevelLabel(reminderState.warningLevel)}'),
            Text('下一次提醒：${reminderState.nextReminderLabel}'),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: reminderState.enabled
                      ? SedentaryReminderService.instance.markManualBreak
                      : null,
                  icon: const Icon(Icons.directions_walk),
                  label: const Text('我已活动'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => context.push('/motion_recommendation'),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('立即开始'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _reminderCardColor(int warningLevel) {
    switch (warningLevel) {
      case 3:
        return const Color(0xFFFFEFEA);
      case 2:
        return const Color(0xFFFFF6E5);
      case 1:
        return const Color(0xFFF2F8FF);
      default:
        return const Color(0xFFF2F8FF);
    }
  }

  String _warningLevelLabel(int warningLevel) {
    switch (warningLevel) {
      case 3:
        return '高风险';
      case 2:
        return '中风险';
      case 1:
        return '轻提醒';
      default:
        return '正常监测';
    }
  }
}
