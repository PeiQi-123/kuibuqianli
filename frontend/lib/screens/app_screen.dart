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
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/background.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // 提醒卡片（保持原状）
                AnimatedBuilder(
                  animation: SedentaryReminderService.instance,
                  builder: (context, _) => Container(
                    width: double.infinity,
                    child: _buildReminderCard(context),
                  ),
                ),
                const SizedBox(height: 30),
                // 菜单网格（卡片已缩小）
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700), // 限制最大宽度
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 72,
                        crossAxisSpacing: 72,
                        childAspectRatio: 1.5,
                        shrinkWrap: true, // 添加这个属性
                        physics: const AlwaysScrollableScrollPhysics(), // 保持可滚动
                        padding: const EdgeInsets.only(bottom: 20),
                        children: [
                          _buildMenuCard(
                            context,
                            icon: Icons.fitness_center,
                            title: '微运动推荐',
                            subtitle: 'AI智能推荐',
                            color: Colors.blue,
                            onTap: () => context.push('/motion_recommendation'),
                          ),
                          _buildMenuCard(
                            context,
                            icon: Icons.videocam,
                            title: '选择身体部位',
                            subtitle: '3D人体选择',
                            color: Colors.orange,
                            onTap: () => context.push('/choose_part_of_body'),
                          ),
                          _buildMenuCard(
                            context,
                            icon: Icons.camera_alt,
                            title: '姿态检测',
                            subtitle: '实时运动姿态',
                            color: Colors.green,
                            onTap: () => context.push('/posture_detection'),
                          ),
                          _buildMenuCard(
                            context,
                            icon: Icons.bar_chart,
                            title: '健康数据',
                            subtitle: '运动统计',
                            color: Colors.purple,
                            onTap: () => context.push('/health_data'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // 用户中心
      const UserCenterScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '首页',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '用户中心',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  // 缩小后的菜单卡片
  Widget _buildMenuCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 22, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 提醒卡片（保持原状）
  Widget _buildReminderCard(BuildContext context) {
    final reminderState = SedentaryReminderService.instance.state;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: (reminderState.enabled ? Colors.blue : Colors.grey).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    reminderState.enabled ? Icons.notifications_active : Icons.notifications_off,
                    size: 16,
                    color: reminderState.enabled ? Colors.blue : Colors.grey,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  reminderState.enabled ? '久坐提醒已开启' : '久坐提醒未开启',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _warningLevelColor(reminderState.warningLevel).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _warningLevelLabel(reminderState.warningLevel),
                    style: TextStyle(
                      fontSize: 10,
                      color: _warningLevelColor(reminderState.warningLevel),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '久坐时长: ${reminderState.sedentaryMinutes}分钟',
                            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.notifications, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '提醒 ${reminderState.remindersSentToday}/${reminderState.maxRemindersPerDay}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.hourglass_empty, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '间隔: ${reminderState.intervalMinutes}分钟',
                            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '下次: ${reminderState.nextReminderLabel}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: reminderState.enabled
                        ? SedentaryReminderService.instance.markManualBreak
                        : null,
                    icon: const Icon(Icons.directions_walk, size: 14),
                    label: const Text('我已活动', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      side: BorderSide(color: Colors.blue.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/motion_recommendation'),
                    icon: const Icon(Icons.play_arrow, size: 14),
                    label: const Text('立即开始', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              reminderState.statusText,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Color _warningLevelColor(int warningLevel) {
    switch (warningLevel) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 1:
        return Colors.blue;
      default:
        return Colors.green;
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
