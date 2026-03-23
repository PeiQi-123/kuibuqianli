// lib/screens/app_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/oppo_health_debug_service.dart';
import '../services/sedentary_reminder_service.dart';
import 'user_center_screen.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  int _selectedIndex = 0;
  bool _showReminderDebugPanel = false;
  bool _showOppoDebugPanel = false;

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
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: SedentaryReminderService.instance,
                        builder: (context, _) => SizedBox(
                          width: double.infinity,
                          child: _buildReminderCard(context),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: SedentaryReminderService.instance,
                        builder: (context, _) => SizedBox(
                          width: double.infinity,
                          child: _buildReminderDebugPanel(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      AnimatedBuilder(
                        animation: OppoHealthDebugService.instance,
                        builder: (context, _) => SizedBox(
                          width: double.infinity,
                          child: _buildOppoDebugPanel(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 72,
                        crossAxisSpacing: 72,
                        childAspectRatio: 1.5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
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
                    ],
                  ),
                ),
              ),
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
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showReminderDebugPanel = !_showReminderDebugPanel;
                    });
                  },
                  icon: Icon(
                    _showReminderDebugPanel
                        ? Icons.bug_report
                        : Icons.bug_report_outlined,
                    size: 18,
                    color: Colors.grey[700],
                  ),
                  tooltip: '提醒调试',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
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

  Widget _buildReminderDebugPanel() {
    if (!_showReminderDebugPanel) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              _showReminderDebugPanel = true;
            });
          },
          icon: const Icon(Icons.bug_report_outlined, size: 16),
          label: const Text('打开提醒调试'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      );
    }

    final service = SedentaryReminderService.instance;
    final debug = service.debugInfo;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.science_outlined, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                const Text(
                  '提醒调试面板',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showReminderDebugPanel = false;
                    });
                  },
                  child: const Text('收起'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDebugChip(
                  'activityScore',
                  '${debug.activityScore.toStringAsFixed(1)} / ${debug.activityThreshold.toStringAsFixed(0)}',
                ),
                _buildDebugChip(
                  '持续时间',
                  '${debug.activeDuration.inSeconds}s / ${debug.requiredDuration.inSeconds}s',
                ),
                _buildDebugChip(
                  '有效活动',
                  debug.activityQualified ? '是' : '否',
                  color: debug.activityQualified ? Colors.green : Colors.grey,
                ),
                _buildDebugChip(
                  '会不会提醒',
                  debug.willRemindNow ? '会' : '不会',
                  color: debug.willRemindNow ? Colors.red : Colors.blueGrey,
                ),
                _buildDebugChip('最近来源', debug.lastActivitySourceLabel),
                _buildDebugChip('最近信号', debug.lastActivityTypeLabel),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              debug.reminderDecision,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
            const SizedBox(height: 4),
            Text(
              debug.sensorActsAsFallbackOnly
                  ? '当前模式：手环优先，手机传感器仅作兜底记录'
                  : '当前模式：手机传感器可独立判定有效活动',
              style: TextStyle(
                fontSize: 11,
                color: debug.sensorActsAsFallbackOnly
                    ? Colors.teal[700]
                    : Colors.blueGrey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              debug.signalSummary,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
            if (debug.cooldownUntil != null) ...[
              const SizedBox(height: 4),
              Text(
                '自动活动冷却到: ${_formatTime(debug.cooldownUntil!)}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              '手机传感器模拟',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => service.debugSimulateActivity(scoreDelta: 1),
                  child: const Text('+1 活动'),
                ),
                OutlinedButton(
                  onPressed: () => service.debugSimulateActivity(
                    scoreDelta: 4,
                    activeDuration: const Duration(seconds: 8),
                  ),
                  child: const Text('+4 快速累计'),
                ),
                OutlinedButton(
                  onPressed: () => service.debugSimulateActivity(
                    scoreDelta: 0,
                    activeDuration: const Duration(seconds: 15),
                  ),
                  child: const Text('模拟15秒有效活动'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      service.debugIncreaseSedentaryMinutes(minutes: 10),
                  child: const Text('+10 分钟久坐'),
                ),
                OutlinedButton(
                  onPressed: () =>
                      service.debugIncreaseSedentaryMinutes(minutes: 30),
                  child: const Text('+30 分钟久坐'),
                ),
                OutlinedButton(
                  onPressed: () => service.debugDecayActivity(scoreDelta: 1),
                  child: const Text('-1 衰减'),
                ),
                OutlinedButton(
                  onPressed: service.debugResetActivity,
                  child: const Text('重置分数'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await service.debugSimulateReminderReady();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('模拟可提醒'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await service.debugTriggerReminderCheck();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('立即检查提醒'),
                ),
                ElevatedButton(
                  onPressed: service.debugSimulateSnooze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('模拟稍后提醒'),
                ),
                ElevatedButton(
                  onPressed: service.debugResetTodayReminderCount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('重置今日提醒次数'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOppoDebugPanel() {
    if (!_showOppoDebugPanel) {
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              _showOppoDebugPanel = true;
            });
          },
          icon: const Icon(Icons.watch_outlined, size: 16),
          label: const Text('打开 OPPO 调试'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.black.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      );
    }

    final service = OppoHealthDebugService.instance;
    final state = service.state;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.watch_outlined, size: 16, color: Colors.teal),
                const SizedBox(width: 6),
                const Text(
                  'OPPO 健康调试面板',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showOppoDebugPanel = false;
                    });
                  },
                  child: const Text('收起'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDebugChip(
                  '模式',
                  state.mode == OppoHealthMode.mock ? 'Mock' : 'SDK',
                  color: state.mode == OppoHealthMode.mock
                      ? Colors.orange
                      : Colors.teal,
                ),
                _buildDebugChip(
                  'SDK',
                  state.sdkReachable ? '可用' : '未验证',
                  color: state.sdkReachable ? Colors.teal : Colors.grey,
                ),
                _buildDebugChip(
                  '授权',
                  state.authorized ? '已授权' : '未授权',
                  color: state.authorized ? Colors.green : Colors.grey,
                ),
                _buildDebugChip(
                  '设备',
                  state.deviceConnected ? '已连接' : '未连接',
                  color: state.deviceConnected ? Colors.teal : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              state.statusText,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
            const SizedBox(height: 4),
            Text(
              state.latestDataSummary,
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
            if (state.scopes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '权限范围: ${state.scopes.join(', ')}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              '模式切换',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => service.setMode(OppoHealthMode.mock),
                  child: const Text('使用 Mock'),
                ),
                OutlinedButton(
                  onPressed: () => service.setMode(OppoHealthMode.sdk),
                  child: const Text('使用 SDK'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'SDK 调试',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: service.initializeSdk,
                  child: const Text('初始化 SDK'),
                ),
                OutlinedButton(
                  onPressed: service.requestAuthorization,
                  child: const Text('请求授权'),
                ),
                OutlinedButton(
                  onPressed: service.validateAuthorization,
                  child: const Text('校验授权'),
                ),
                OutlinedButton(
                  onPressed: service.queryBoundDevices,
                  child: const Text('查询设备'),
                ),
                ElevatedButton(
                  onPressed: service.readTodayData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('读取今日数据'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Mock 调试',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => service.mockConnectDevice(true),
                  child: const Text('Mock 连接'),
                ),
                OutlinedButton(
                  onPressed: () => service.mockConnectDevice(false),
                  child: const Text('Mock 断开'),
                ),
                OutlinedButton(
                  onPressed: () => service.mockStepDelta(10),
                  child: const Text('OPPO +10步'),
                ),
                OutlinedButton(
                  onPressed: () => service.mockStepDelta(20),
                  child: const Text('OPPO +20步'),
                ),
                OutlinedButton(
                  onPressed: () => service.mockMoveCount(1),
                  child: const Text('OPPO 活动+1'),
                ),
                OutlinedButton(
                  onPressed: () => service.mockActiveMinutes(3),
                  child: const Text('OPPO 活动+3m'),
                ),
                ElevatedButton(
                  onPressed: service.mockWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OPPO 运动记录'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDebugChip('步数信号', '${state.latestStepDelta}'),
                _buildDebugChip('活动次数', '${state.latestMoveCountDelta}'),
                _buildDebugChip('活动时长', '${state.latestActiveMinutesDelta}m'),
                _buildDebugChip(
                  '运动记录',
                  state.latestWorkoutDetected ? '有' : '无',
                  color: state.latestWorkoutDetected ? Colors.teal : Colors.grey,
                ),
                _buildDebugChip('设备数', '${state.devices.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugChip(String label, String value, {Color? color}) {
    final chipColor = color ?? Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: chipColor,
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
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
