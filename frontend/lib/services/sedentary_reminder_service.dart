import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../app/routes/app_routes.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'storage_service.dart';

class SedentaryReminderState {
  final bool enabled;
  final int intervalMinutes;
  final int maxRemindersPerDay;
  final int remindersSentToday;
  final int sedentaryMinutes;
  final int warningLevel;
  final DateTime? nextReminderAt;
  final bool inAvoidPeriod;
  final String statusText;

  const SedentaryReminderState({
    required this.enabled,
    required this.intervalMinutes,
    required this.maxRemindersPerDay,
    required this.remindersSentToday,
    required this.sedentaryMinutes,
    required this.warningLevel,
    required this.nextReminderAt,
    required this.inAvoidPeriod,
    required this.statusText,
  });

  int get remainingRemindersToday =>
      math.max(maxRemindersPerDay - remindersSentToday, 0);

  String get nextReminderLabel {
    if (!enabled) return '已关闭';
    if (inAvoidPeriod) return '免打扰时段中';
    if (nextReminderAt == null) return '等待初始化';
    final hour = nextReminderAt!.hour.toString().padLeft(2, '0');
    final minute = nextReminderAt!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  SedentaryReminderState copyWith({
    bool? enabled,
    int? intervalMinutes,
    int? maxRemindersPerDay,
    int? remindersSentToday,
    int? sedentaryMinutes,
    int? warningLevel,
    DateTime? nextReminderAt,
    bool? inAvoidPeriod,
    String? statusText,
  }) {
    return SedentaryReminderState(
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      maxRemindersPerDay: maxRemindersPerDay ?? this.maxRemindersPerDay,
      remindersSentToday: remindersSentToday ?? this.remindersSentToday,
      sedentaryMinutes: sedentaryMinutes ?? this.sedentaryMinutes,
      warningLevel: warningLevel ?? this.warningLevel,
      nextReminderAt: nextReminderAt ?? this.nextReminderAt,
      inAvoidPeriod: inAvoidPeriod ?? this.inAvoidPeriod,
      statusText: statusText ?? this.statusText,
    );
  }

  static SedentaryReminderState initial() {
    return SedentaryReminderState(
      enabled: false,
      intervalMinutes: 30,
      maxRemindersPerDay: 3,
      remindersSentToday: 0,
      sedentaryMinutes: 0,
      warningLevel: 0,
      nextReminderAt: null,
      inAvoidPeriod: false,
      statusText: '提醒未启动',
    );
  }
}

class SedentaryReminderService extends ChangeNotifier
    with WidgetsBindingObserver {
  SedentaryReminderService._();

  static final SedentaryReminderService instance =
      SedentaryReminderService._();

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  SedentaryReminderState _state = SedentaryReminderState.initial();
  SedentaryReminderState get state => _state;

  Timer? _checkTimer;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  bool _initialized = false;
  bool _dialogVisible = false;
  bool _isAppResumed = true;
  List<Map<String, String>> _avoidTimes = const [];
  DateTime _lastMovementAt = DateTime.now();
  DateTime? _nextReminderAt;
  DateTime? _snoozeUntil;
  DateTime _today = DateTime.now();
  int _sessionReminderCount = 0;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    await refreshConfig();
    _startMonitoring();
  }

  Future<void> refreshConfig() async {
    final user = await _authService.getCurrentUser();
    if (user == null || user.remindEnabled == false) {
      _avoidTimes = const [];
      _snoozeUntil = null;
      _nextReminderAt = null;
      _state = SedentaryReminderState.initial().copyWith(
        statusText: user == null ? '未登录，提醒未启动' : '久坐提醒已关闭',
      );
      notifyListeners();
      return;
    }

    _avoidTimes = user.remindAvoidTime ?? const [];
    _lastMovementAt = DateTime.now();

    final statusData = await _loadReminderStatus();
    final intervalMinutes = _safeInt(user.remindInterval, fallback: 30, min: 5, max: 240);
    final maxReminders = _safeInt(user.remindMaxTimes, fallback: 3, min: 1, max: 10);
    final remindersSentToday = _safeInt(statusData?['remindersSentToday'], fallback: 0, min: 0, max: 99);
    final inAvoidPeriod = statusData?['inAvoidPeriod'] == true || _isInAvoidPeriod(DateTime.now());
    final sedentaryMinutes = _calculateSedentaryMinutes(DateTime.now());
    final warningLevel = _calculateWarningLevel(sedentaryMinutes, intervalMinutes);

    final parsedNext = _parseDateTime(statusData?['nextSuggestedReminderTime']);
    _nextReminderAt = parsedNext ?? DateTime.now().add(Duration(minutes: intervalMinutes));

    final lastExerciseTime = _parseDateTime(statusData?['lastExerciseTime']);
    if (lastExerciseTime != null && lastExerciseTime.isAfter(_lastMovementAt)) {
      _lastMovementAt = lastExerciseTime;
    }

    _state = SedentaryReminderState(
      enabled: true,
      intervalMinutes: intervalMinutes,
      maxRemindersPerDay: maxReminders,
      remindersSentToday: remindersSentToday,
      sedentaryMinutes: sedentaryMinutes,
      warningLevel: warningLevel,
      nextReminderAt: _nextReminderAt,
      inAvoidPeriod: inAvoidPeriod,
      statusText: _buildStatusText(sedentaryMinutes, warningLevel, inAvoidPeriod),
    );
    notifyListeners();
  }

  Future<void> markExerciseCompleted() async {
    _markMovementDetected(statusText: '已完成运动，重新开始计时');
    await refreshConfig();
  }

  void markManualBreak() {
    _markMovementDetected(statusText: '已手动确认活动，重新开始计时');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppResumed = state == AppLifecycleState.resumed;
    if (_isAppResumed) {
      refreshConfig();
    }
  }

  void disposeService() {
    _checkTimer?.cancel();
    _accelerometerSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }

  void _startMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _tick();
    });

    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }

    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      final delta = (magnitude - 9.8).abs();
      if (delta > 1.4 || event.x.abs() > 2.2 || event.y.abs() > 2.2) {
        _markMovementDetected();
      }
    });
  }

  Future<void> _tick() async {
    if (!_state.enabled || !_isAppResumed || _dialogVisible) return;

    final now = DateTime.now();
    if (!_isSameDay(_today, now)) {
      _today = now;
      _sessionReminderCount = 0;
      await refreshConfig();
    }

    if (_state.remindersSentToday >= _state.maxRemindersPerDay) {
      _updateState(
        sedentaryMinutes: _calculateSedentaryMinutes(now),
        statusText: '今日提醒次数已达上限',
      );
      return;
    }

    if (_snoozeUntil != null && now.isBefore(_snoozeUntil!)) {
      _updateState(
        nextReminderAt: _snoozeUntil,
        sedentaryMinutes: _calculateSedentaryMinutes(now),
        statusText: '已稍后提醒',
      );
      return;
    }

    final inAvoidPeriod = _isInAvoidPeriod(now);
    final sedentaryMinutes = _calculateSedentaryMinutes(now);
    final warningLevel = _calculateWarningLevel(sedentaryMinutes, _state.intervalMinutes);
    if (inAvoidPeriod) {
      final avoidEnd = _currentAvoidPeriodEnd(now);
      if (_nextReminderAt == null || now.isAfter(_nextReminderAt!)) {
        await _logReminder(status: 'skipped', inAvoidPeriod: true);
      }
      _nextReminderAt = avoidEnd;
      _updateState(
        inAvoidPeriod: true,
        nextReminderAt: avoidEnd,
        sedentaryMinutes: sedentaryMinutes,
        warningLevel: warningLevel,
        statusText: '当前处于免打扰时段',
      );
      return;
    }

    final fallbackNext = _lastMovementAt.add(
      Duration(minutes: _state.intervalMinutes),
    );
    _nextReminderAt ??= fallbackNext;

    if (now.isBefore(_nextReminderAt!)) {
      _updateState(
        inAvoidPeriod: false,
        nextReminderAt: _nextReminderAt,
        sedentaryMinutes: sedentaryMinutes,
        warningLevel: warningLevel,
        statusText: _buildStatusText(sedentaryMinutes, warningLevel, false),
      );
      return;
    }

    await _showReminderDialog(warningLevel: warningLevel, sedentaryMinutes: sedentaryMinutes);
  }

  Future<Map<String, dynamic>?> _loadReminderStatus() async {
    final userId = await StorageService.getUserId();
    if (userId == null || userId.isEmpty) return null;
    final response = await _apiService.get(
      '/reminder/status',
      params: {'userId': userId},
    );
    if (response != null && response['code'] == 200 && response['data'] is Map) {
      return Map<String, dynamic>.from(response['data']);
    }
    return null;
  }

  Future<void> _logReminder({
    required String status,
    required bool inAvoidPeriod,
  }) async {
    final userId = await StorageService.getUserId();
    if (userId == null || userId.isEmpty) return;
    await _apiService.post('/reminder/log?userId=$userId', {
      'status': status,
      'inAvoidPeriod': inAvoidPeriod,
    });
  }

  Future<void> _showReminderDialog({
    required int warningLevel,
    required int sedentaryMinutes,
  }) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    _dialogVisible = true;
    _sessionReminderCount += 1;
    await _logReminder(status: 'success', inAvoidPeriod: false);

    final now = DateTime.now();
    _state = _state.copyWith(
      remindersSentToday: _state.remindersSentToday + 1,
      sedentaryMinutes: sedentaryMinutes,
      warningLevel: warningLevel,
    );

    final title = _warningTitle(warningLevel);
    final content = _buildReminderMessage(
      warningLevel,
      sedentaryMinutes,
      _state.intervalMinutes,
    );

    if (!context.mounted) {
      _dialogVisible = false;
      return;
    }

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('snooze'),
              child: const Text('稍后10分钟'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('break'),
              child: const Text('我已活动'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(
                warningLevel >= 3 ? 'video' : 'start',
              ),
              child: Text(warningLevel >= 3 ? '去视频指导' : '立即开始'),
            ),
          ],
        );
      },
    );

    _dialogVisible = false;

    switch (result) {
      case 'snooze':
        _snoozeUntil = now.add(const Duration(minutes: 10));
        _nextReminderAt = _snoozeUntil;
        _updateState(nextReminderAt: _snoozeUntil, statusText: '已稍后10分钟提醒');
        break;
      case 'break':
        markManualBreak();
        break;
      case 'start':
        _markMovementDetected(statusText: '已前往微运动推荐页');
        router.push('/motion_recommendation');
        break;
      case 'video':
        _markMovementDetected(statusText: '已前往视频指导页');
        router.push('/choose_part_of_body');
        break;
      default:
        _nextReminderAt = now.add(Duration(minutes: _state.intervalMinutes));
        _updateState(
          nextReminderAt: _nextReminderAt,
          sedentaryMinutes: sedentaryMinutes,
          warningLevel: warningLevel,
        );
    }
  }

  String _buildReminderMessage(
    int warningLevel,
    int sedentaryMinutes,
    int intervalMinutes,
  ) {
    if (warningLevel >= 3) {
      return '你已经连续久坐约 $sedentaryMinutes 分钟，当前属于高风险久坐状态。建议立即开始一组肩颈、腰背或下肢微运动，并跟随视频完成 3~5 分钟活动。';
    }
    if (warningLevel == 2) {
      return '你已经连续久坐约 $sedentaryMinutes 分钟，疲劳正在累积。建议现在起身活动、舒展肩颈或短暂走动，避免进一步进入高风险久坐状态。';
    }
    return '你已连续静坐约 $sedentaryMinutes 分钟，建议站起来活动一下，先做轻量伸展，放松肩颈和腰背。';
  }

  String _warningTitle(int warningLevel) {
    switch (warningLevel) {
      case 3:
        return '高风险久坐提醒';
      case 2:
        return '中度久坐预警';
      default:
        return '轻度久坐提醒';
    }
  }

  void _markMovementDetected({String? statusText}) {
    _lastMovementAt = DateTime.now();
    _snoozeUntil = null;
    _sessionReminderCount = 0;
    _nextReminderAt = _lastMovementAt.add(Duration(minutes: _state.intervalMinutes));
    _updateState(
      inAvoidPeriod: false,
      nextReminderAt: _nextReminderAt,
      sedentaryMinutes: 0,
      warningLevel: 0,
      statusText: statusText ?? '检测到活动，重新开始计时',
    );
  }

  int _calculateSedentaryMinutes(DateTime now) {
    final diff = now.difference(_lastMovementAt).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  int _calculateWarningLevel(int sedentaryMinutes, int intervalMinutes) {
    final level1 = intervalMinutes;
    final level2 = intervalMinutes + 15;
    final level3 = intervalMinutes + 30;
    if (sedentaryMinutes >= level3 || _sessionReminderCount >= 3) {
      return 3;
    }
    if (sedentaryMinutes >= level2 || _sessionReminderCount >= 2) {
      return 2;
    }
    if (sedentaryMinutes >= level1) {
      return 1;
    }
    return 0;
  }

  String _buildStatusText(int sedentaryMinutes, int warningLevel, bool inAvoidPeriod) {
    if (!_state.enabled) {
      return '提醒未启动';
    }
    if (inAvoidPeriod) {
      return '当前处于免打扰时段';
    }
    if (warningLevel >= 3) {
      return '已连续久坐 $sedentaryMinutes 分钟，建议立即跟练一组视频微运动';
    }
    if (warningLevel == 2) {
      return '已连续久坐 $sedentaryMinutes 分钟，建议尽快起身活动';
    }
    if (warningLevel == 1) {
      return '已连续久坐 $sedentaryMinutes 分钟，建议开始轻量活动';
    }
    return '当前已连续久坐 $sedentaryMinutes 分钟，正在监测久坐状态';
  }

  bool _isInAvoidPeriod(DateTime now) {
    for (final period in _avoidTimes) {
      final start = _parseClock(period['start']);
      final end = _parseClock(period['end']);
      if (start == null || end == null) continue;
      if (_covers(start, end, now)) {
        return true;
      }
    }
    return false;
  }

  DateTime? _currentAvoidPeriodEnd(DateTime now) {
    for (final period in _avoidTimes) {
      final start = _parseClock(period['start']);
      final end = _parseClock(period['end']);
      if (start == null || end == null) continue;
      if (_covers(start, end, now)) {
        final endToday = DateTime(now.year, now.month, now.day, end.hour, end.minute);
        if (!_crossesMidnight(start, end)) {
          return endToday;
        }
        if (now.hour > start.hour || (now.hour == start.hour && now.minute >= start.minute)) {
          return endToday.add(const Duration(days: 1));
        }
        return endToday;
      }
    }
    return null;
  }

  bool _covers(TimeOfDay start, TimeOfDay end, DateTime now) {
    final minute = now.hour * 60 + now.minute;
    final startMinute = start.hour * 60 + start.minute;
    final endMinute = end.hour * 60 + end.minute;
    if (startMinute == endMinute) return true;
    if (startMinute < endMinute) {
      return minute >= startMinute && minute < endMinute;
    }
    return minute >= startMinute || minute < endMinute;
  }

  bool _crossesMidnight(TimeOfDay start, TimeOfDay end) {
    final startMinute = start.hour * 60 + start.minute;
    final endMinute = end.hour * 60 + end.minute;
    return startMinute > endMinute;
  }

  TimeOfDay? _parseClock(String? value) {
    if (value == null || !value.contains(':')) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _safeInt(dynamic value, {required int fallback, required int min, required int max}) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (parsed == null) return fallback;
    return parsed.clamp(min, max);
  }

  void _updateState({
    DateTime? nextReminderAt,
    bool? inAvoidPeriod,
    int? sedentaryMinutes,
    int? warningLevel,
    String? statusText,
  }) {
    _state = _state.copyWith(
      nextReminderAt: nextReminderAt,
      inAvoidPeriod: inAvoidPeriod,
      sedentaryMinutes: sedentaryMinutes,
      warningLevel: warningLevel,
      statusText: statusText,
    );
    notifyListeners();
  }
}
