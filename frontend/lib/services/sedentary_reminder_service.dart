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

class SedentaryReminderDebugInfo {
  final double activityScore;
  final double activityThreshold;
  final Duration activeDuration;
  final Duration requiredDuration;
  final bool activityQualified;
  final bool willRemindNow;
  final String reminderDecision;
  final DateTime? cooldownUntil;
  final String lastActivitySourceLabel;
  final String lastActivityTypeLabel;
  final bool wearableMockConnected;
  final int wearableMockSteps;
  final int wearableMockMoveCount;
  final int wearableMockActiveMinutes;
  final bool wearableMockWorkoutDetected;
  final String signalSummary;
  final bool sensorActsAsFallbackOnly;

  const SedentaryReminderDebugInfo({
    required this.activityScore,
    required this.activityThreshold,
    required this.activeDuration,
    required this.requiredDuration,
    required this.activityQualified,
    required this.willRemindNow,
    required this.reminderDecision,
    required this.cooldownUntil,
    required this.lastActivitySourceLabel,
    required this.lastActivityTypeLabel,
    required this.wearableMockConnected,
    required this.wearableMockSteps,
    required this.wearableMockMoveCount,
    required this.wearableMockActiveMinutes,
    required this.wearableMockWorkoutDetected,
    required this.signalSummary,
    required this.sensorActsAsFallbackOnly,
  });
}

enum ActivitySignalSource {
  sensor,
  wearableMock,
  oppoSdk,
  manual,
  exercise,
  debug,
}

enum ActivitySignalType {
  effectiveMotion,
  wearableSteps,
  wearableMove,
  wearableActiveMinutes,
  wearableWorkout,
  manualBreak,
  exerciseCompleted,
}

class ActivitySignal {
  final ActivitySignalSource source;
  final ActivitySignalType type;
  final DateTime timestamp;
  final int stepDelta;
  final int moveCountDelta;
  final int activeMinutesDelta;
  final bool shouldResetSedentary;
  final String statusText;

  const ActivitySignal({
    required this.source,
    required this.type,
    required this.timestamp,
    this.stepDelta = 0,
    this.moveCountDelta = 0,
    this.activeMinutesDelta = 0,
    required this.shouldResetSedentary,
    required this.statusText,
  });
}

class SedentaryReminderService extends ChangeNotifier
    with WidgetsBindingObserver {
  SedentaryReminderService._();

  static const double _effectiveActivityScoreThreshold = 8;
  static const double _obviousMotionDeltaThreshold = 2.0;
  static const double _obviousMotionAxisThreshold = 2.6;
  static const Duration _effectiveActivityMinDuration = Duration(seconds: 15);
  static const Duration _activityScoreStepInterval = Duration(seconds: 2);
  static const Duration _activityScoreDecayGap = Duration(seconds: 3);
  static const Duration _reminderCheckInterval = Duration(seconds: 10);
  static const Duration _autoMovementCooldown = Duration(minutes: 5);
  static const int _wearableStepResetThreshold = 20;
  static const int _wearableMoveResetThreshold = 1;
  static const int _wearableActiveMinutesResetThreshold = 3;

  static final SedentaryReminderService instance =
      SedentaryReminderService._();

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  SedentaryReminderState _state = SedentaryReminderState.initial();
  SedentaryReminderState get state => _state;

  SedentaryReminderDebugInfo get debugInfo {
    final now = DateTime.now();
    final activeDuration = _activityStartedAt == null
        ? Duration.zero
        : now.difference(_activityStartedAt!);
    final activityQualified =
        _activityScore >= _effectiveActivityScoreThreshold &&
        activeDuration >= _effectiveActivityMinDuration;
    final reminderDecision = _buildReminderDecision(now);

    return SedentaryReminderDebugInfo(
      activityScore: _activityScore,
      activityThreshold: _effectiveActivityScoreThreshold,
      activeDuration: activeDuration.isNegative ? Duration.zero : activeDuration,
      requiredDuration: _effectiveActivityMinDuration,
      activityQualified: activityQualified,
      willRemindNow: reminderDecision.startsWith('会提醒'),
      reminderDecision: reminderDecision,
      cooldownUntil: _autoMovementCooldownUntil,
      lastActivitySourceLabel: _activitySourceLabel(_lastSignal?.source),
      lastActivityTypeLabel: _activityTypeLabel(_lastSignal?.type),
      wearableMockConnected: _wearableMockConnected || _oppoWearableConnected,
      wearableMockSteps: _wearableMockStepDelta,
      wearableMockMoveCount: _wearableMockMoveCountDelta,
      wearableMockActiveMinutes: _wearableMockActiveMinutesDelta,
      wearableMockWorkoutDetected: _wearableMockWorkoutDetected,
      signalSummary: _buildSignalSummary(),
      sensorActsAsFallbackOnly: _hasWearablePriority,
    );
  }

  Timer? _checkTimer;
  Timer? _debugDecayTimer;
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
  double _activityScore = 0;
  DateTime? _activityStartedAt;
  DateTime? _lastScoredMotionAt;
  DateTime? _lastMotionObservedAt;
  DateTime? _autoMovementCooldownUntil;
  ActivitySignal? _lastSignal;
  bool _wearableMockConnected = false;
  bool _oppoWearableConnected = false;
  int _wearableMockStepDelta = 0;
  int _wearableMockMoveCountDelta = 0;
  int _wearableMockActiveMinutesDelta = 0;
  bool _wearableMockWorkoutDetected = false;

  bool get _hasWearablePriority => _wearableMockConnected || _oppoWearableConnected;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    await refreshConfig();
    _startMonitoring();
  }

  Future<void> refreshConfig() async {
    final now = DateTime.now();
    final user = await _authService.getCurrentUser();
    if (user == null || user.remindEnabled == false) {
      _avoidTimes = const [];
      _snoozeUntil = null;
      _nextReminderAt = null;
      _resetActivityDetection();
      _state = SedentaryReminderState.initial().copyWith(
        statusText: user == null ? '未登录，提醒未启动' : '久坐提醒已关闭',
      );
      notifyListeners();
      return;
    }

    _avoidTimes = user.remindAvoidTime ?? const [];
    _resetActivityDetection();

    final statusData = await _loadReminderStatus();
    final intervalMinutes = _safeInt(user.remindInterval, fallback: 30, min: 5, max: 240);
    final maxReminders = _safeInt(user.remindMaxTimes, fallback: 3, min: 1, max: 10);
    final remindersSentToday = _safeInt(statusData?['remindersSentToday'], fallback: 0, min: 0, max: 99);
    final inAvoidPeriod = statusData?['inAvoidPeriod'] == true || _isInAvoidPeriod(now);

    final parsedNext = _parseDateTime(statusData?['nextSuggestedReminderTime']);
    final lastExerciseTime = _parseDateTime(statusData?['lastExerciseTime']);

    DateTime resolvedLastMovementAt = now;
    if (parsedNext != null) {
      resolvedLastMovementAt = parsedNext.subtract(
        Duration(minutes: intervalMinutes),
      );
    }
    if (lastExerciseTime != null && lastExerciseTime.isAfter(resolvedLastMovementAt)) {
      resolvedLastMovementAt = lastExerciseTime;
    }

    if (resolvedLastMovementAt.isAfter(now)) {
      resolvedLastMovementAt = now;
    }

    _lastMovementAt = resolvedLastMovementAt;
    _nextReminderAt = parsedNext ??
        _lastMovementAt.add(Duration(minutes: intervalMinutes));

    final sedentaryMinutes = _calculateSedentaryMinutes(now);
    final warningLevel = _calculateWarningLevel(sedentaryMinutes, intervalMinutes);

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
    _reportActivitySignal(
      ActivitySignal(
        source: ActivitySignalSource.exercise,
        type: ActivitySignalType.exerciseCompleted,
        timestamp: DateTime.now(),
        shouldResetSedentary: true,
        statusText: '已完成运动，重新开始计时',
      ),
    );
    await refreshConfig();
  }

  void markManualBreak() {
    _reportActivitySignal(
      ActivitySignal(
        source: ActivitySignalSource.manual,
        type: ActivitySignalType.manualBreak,
        timestamp: DateTime.now(),
        shouldResetSedentary: true,
        statusText: '已手动确认活动，重新开始计时',
      ),
    );
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
    _debugDecayTimer?.cancel();
    _accelerometerSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
  }

  void debugSimulateActivity({int scoreDelta = 1, Duration? activeDuration}) {
    final now = DateTime.now();
    _activityStartedAt ??= now;
    if (activeDuration != null) {
      _activityStartedAt = now.subtract(activeDuration);
      if (activeDuration >= _effectiveActivityMinDuration) {
        scoreDelta = math.max(
          scoreDelta,
          _effectiveActivityScoreThreshold.toInt(),
        );
      } else {
        final simulatedSteps =
            activeDuration.inSeconds ~/ _activityScoreStepInterval.inSeconds;
        if (simulatedSteps > 0) {
          scoreDelta = math.max(scoreDelta, simulatedSteps);
        }
      }
    }
    _lastMotionObservedAt = now;
    _lastScoredMotionAt = now;
    _activityScore = math.max(0, _activityScore + scoreDelta).toDouble();

    final currentActiveDuration = _activityStartedAt == null
        ? Duration.zero
        : now.difference(_activityStartedAt!);
    if (_activityScore >= _effectiveActivityScoreThreshold &&
        currentActiveDuration >= _effectiveActivityMinDuration) {
      _stopDebugDecayTimer();
      _reportActivitySignal(
        ActivitySignal(
          source: ActivitySignalSource.sensor,
          type: ActivitySignalType.effectiveMotion,
          timestamp: now,
          shouldResetSedentary: !_hasWearablePriority,
          statusText: _hasWearablePriority
              ? '已记录手机活动信号，当前由手环数据优先判定'
              : '检测到持续活动，重新开始计时',
        ),
      );
      if (!_hasWearablePriority) {
        _autoMovementCooldownUntil = now.add(_autoMovementCooldown);
      } else {
        _resetActivityDetection();
      }
      return;
    }

    _scheduleDebugDecayTimer();
    notifyListeners();
  }

  void debugDecayActivity({int scoreDelta = 1}) {
    _stopDebugDecayTimer();
    _activityScore = math.max(0, _activityScore - scoreDelta).toDouble();
    if (_activityScore == 0) {
      _activityStartedAt = null;
      _lastScoredMotionAt = null;
      _lastMotionObservedAt = null;
    }
    notifyListeners();
  }

  void debugResetActivity() {
    _stopDebugDecayTimer();
    _resetActivityDetection();
    notifyListeners();
  }

  void debugResetTodayReminderCount() {
    _sessionReminderCount = 0;
    _today = DateTime.now();
    _updateState(
      remindersSentToday: 0,
      statusText: '调试：已重置今日提醒次数',
    );
  }

  void debugSetWearableConnection(bool connected) {
    _wearableMockConnected = connected;
    if (!connected) {
      _wearableMockStepDelta = 0;
      _wearableMockMoveCountDelta = 0;
      _wearableMockActiveMinutesDelta = 0;
      _wearableMockWorkoutDetected = false;
    }
    notifyListeners();
  }

  void setOppoWearableConnection(bool connected) {
    _oppoWearableConnected = connected;
    notifyListeners();
  }

  void ingestOppoActivityData({
    int stepDelta = 0,
    int moveCountDelta = 0,
    int activeMinutesDelta = 0,
    bool workoutDetected = false,
  }) {
    _oppoWearableConnected = true;

    if (workoutDetected) {
      _reportActivitySignal(
        ActivitySignal(
          source: ActivitySignalSource.oppoSdk,
          type: ActivitySignalType.wearableWorkout,
          timestamp: DateTime.now(),
          shouldResetSedentary: true,
          statusText: '检测到 OPPO 健康运动记录，重新开始计时',
        ),
      );
      return;
    }

    if (stepDelta > 0) {
      _reportActivitySignal(
        ActivitySignal(
          source: ActivitySignalSource.oppoSdk,
          type: ActivitySignalType.wearableSteps,
          timestamp: DateTime.now(),
          stepDelta: stepDelta,
          shouldResetSedentary: stepDelta >= _wearableStepResetThreshold,
          statusText: stepDelta >= _wearableStepResetThreshold
              ? '检测到 OPPO 步数增长，重新开始计时'
              : '已记录 OPPO 步数变化，等待更多活动证据',
        ),
      );
    }

    if (moveCountDelta > 0) {
      _reportActivitySignal(
        ActivitySignal(
          source: ActivitySignalSource.oppoSdk,
          type: ActivitySignalType.wearableMove,
          timestamp: DateTime.now(),
          moveCountDelta: moveCountDelta,
          shouldResetSedentary: moveCountDelta >= _wearableMoveResetThreshold,
          statusText: '检测到 OPPO 活动次数变化，重新开始计时',
        ),
      );
    }

    if (activeMinutesDelta > 0) {
      _reportActivitySignal(
        ActivitySignal(
          source: ActivitySignalSource.oppoSdk,
          type: ActivitySignalType.wearableActiveMinutes,
          timestamp: DateTime.now(),
          activeMinutesDelta: activeMinutesDelta,
          shouldResetSedentary:
              activeMinutesDelta >= _wearableActiveMinutesResetThreshold,
          statusText: activeMinutesDelta >= _wearableActiveMinutesResetThreshold
              ? '检测到 OPPO 活动时长增长，重新开始计时'
              : '已记录 OPPO 活动时长变化，等待更多活动证据',
        ),
      );
    }

    notifyListeners();
  }

  void debugMockWearableSteps(int stepDelta) {
    _wearableMockConnected = true;
    _wearableMockStepDelta += stepDelta;
    _reportActivitySignal(
      ActivitySignal(
        source: ActivitySignalSource.wearableMock,
        type: ActivitySignalType.wearableSteps,
        timestamp: DateTime.now(),
        stepDelta: stepDelta,
        shouldResetSedentary: stepDelta >= _wearableStepResetThreshold,
        statusText: stepDelta >= _wearableStepResetThreshold
            ? '检测到手环步数增长，重新开始计时'
            : '已记录手环步数变化，等待更多活动证据',
      ),
    );
  }

  void debugMockWearableMoveCount(int moveCountDelta) {
    _wearableMockConnected = true;
    _wearableMockMoveCountDelta += moveCountDelta;
    _reportActivitySignal(
      ActivitySignal(
        source: ActivitySignalSource.wearableMock,
        type: ActivitySignalType.wearableMove,
        timestamp: DateTime.now(),
        moveCountDelta: moveCountDelta,
        shouldResetSedentary: moveCountDelta >= _wearableMoveResetThreshold,
        statusText: '检测到手环活动次数变化，重新开始计时',
      ),
    );
  }

  void debugMockWearableActiveMinutes(int activeMinutesDelta) {
    _wearableMockConnected = true;
    _wearableMockActiveMinutesDelta += activeMinutesDelta;
    _reportActivitySignal(
      ActivitySignal(
        source: ActivitySignalSource.wearableMock,
        type: ActivitySignalType.wearableActiveMinutes,
        timestamp: DateTime.now(),
        activeMinutesDelta: activeMinutesDelta,
        shouldResetSedentary:
            activeMinutesDelta >= _wearableActiveMinutesResetThreshold,
        statusText: activeMinutesDelta >= _wearableActiveMinutesResetThreshold
            ? '检测到手环活动时长增长，重新开始计时'
            : '已记录手环活动时长变化，等待更多活动证据',
      ),
    );
  }

  void debugMockWearableWorkout() {
    _wearableMockConnected = true;
    _wearableMockWorkoutDetected = true;
    _reportActivitySignal(
      ActivitySignal(
        source: ActivitySignalSource.wearableMock,
        type: ActivitySignalType.wearableWorkout,
        timestamp: DateTime.now(),
        shouldResetSedentary: true,
        statusText: '检测到手环运动记录，重新开始计时',
      ),
    );
  }

  Future<void> debugSimulateReminderReady() async {
    _lastMovementAt = DateTime.now().subtract(
      Duration(minutes: _state.intervalMinutes + 1),
    );
    _nextReminderAt = DateTime.now().subtract(const Duration(minutes: 1));
    _snoozeUntil = null;
    _updateState(
      nextReminderAt: _nextReminderAt,
      sedentaryMinutes: _calculateSedentaryMinutes(DateTime.now()),
      warningLevel: _calculateWarningLevel(
        _calculateSedentaryMinutes(DateTime.now()),
        _state.intervalMinutes,
      ),
      statusText: '调试：已模拟到可提醒状态',
    );
    await debugTriggerReminderCheck();
  }

  void debugSimulateSnooze() {
    _snoozeUntil = DateTime.now().add(const Duration(minutes: 10));
    _updateState(
      nextReminderAt: _snoozeUntil,
      statusText: '调试：已模拟稍后提醒',
    );
  }

  void debugIncreaseSedentaryMinutes({int minutes = 10}) {
    final now = DateTime.now();
    _lastMovementAt = _lastMovementAt.subtract(Duration(minutes: minutes));
    if (_snoozeUntil == null) {
      _nextReminderAt = _lastMovementAt.add(
        Duration(minutes: _state.intervalMinutes),
      );
    }
    _updateState(
      nextReminderAt: _nextReminderAt,
      sedentaryMinutes: _calculateSedentaryMinutes(now),
      warningLevel: _calculateWarningLevel(
        _calculateSedentaryMinutes(now),
        _state.intervalMinutes,
      ),
      statusText: '调试：已增加 $minutes 分钟久坐时长',
    );
  }

  Future<void> debugTriggerReminderCheck() async {
    await _tick();
  }

  void _startMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(_reminderCheckInterval, (_) {
      _tick();
    });

    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }

    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      _handleAccelerometerEvent(event);
    });
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    final now = DateTime.now();
    if (_autoMovementCooldownUntil != null && now.isBefore(_autoMovementCooldownUntil!)) {
      _decayActivityScore(now);
      return;
    }

    final magnitude = math.sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );
    final delta = (magnitude - 9.8).abs();
    final obviousMotion =
        delta >= _obviousMotionDeltaThreshold ||
        event.x.abs() >= _obviousMotionAxisThreshold ||
        event.y.abs() >= _obviousMotionAxisThreshold;

    if (!obviousMotion) {
      _decayActivityScore(now);
      return;
    }

    _activityStartedAt ??= now;
    _lastMotionObservedAt = now;

    if (_lastScoredMotionAt == null ||
        now.difference(_lastScoredMotionAt!) >= _activityScoreStepInterval) {
      _activityScore += 1;
      _lastScoredMotionAt = now;
    }

    final activeDuration = now.difference(_activityStartedAt!);
    if (_activityScore >= _effectiveActivityScoreThreshold &&
        activeDuration >= _effectiveActivityMinDuration) {
      _reportActivitySignal(
        ActivitySignal(
          source: ActivitySignalSource.sensor,
          type: ActivitySignalType.effectiveMotion,
          timestamp: now,
          shouldResetSedentary: !_hasWearablePriority,
          statusText: _hasWearablePriority
              ? '已记录手机活动信号，当前由手环数据优先判定'
              : '检测到持续活动，重新开始计时',
        ),
      );
      if (!_hasWearablePriority) {
        _autoMovementCooldownUntil = now.add(_autoMovementCooldown);
      } else {
        _resetActivityDetection();
      }
    }
  }

  void _decayActivityScore(DateTime now) {
    if (_activityScore <= 0) return;
    if (_lastMotionObservedAt == null) {
      _resetActivityDetection();
      return;
    }

    final idleDuration = now.difference(_lastMotionObservedAt!);
    if (idleDuration < _activityScoreDecayGap) {
      return;
    }

    final decaySteps = idleDuration.inSeconds ~/ _activityScoreDecayGap.inSeconds;
    if (decaySteps <= 0) {
      return;
    }

    _activityScore = math.max(0, _activityScore - decaySteps).toDouble();
    _lastMotionObservedAt = now;
    if (_activityScore == 0) {
      _activityStartedAt = null;
      _lastScoredMotionAt = null;
    }
  }

  void _resetActivityDetection() {
    _activityScore = 0;
    _activityStartedAt = null;
    _lastScoredMotionAt = null;
    _lastMotionObservedAt = null;
  }

  void _scheduleDebugDecayTimer() {
    _debugDecayTimer?.cancel();
    _debugDecayTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activityScore <= 0) {
        _stopDebugDecayTimer();
        return;
      }

      final now = DateTime.now();
      final beforeScore = _activityScore;
      _decayActivityScore(now);
      if (_activityScore != beforeScore) {
        notifyListeners();
      }
      if (_activityScore <= 0) {
        _stopDebugDecayTimer();
      }
    });
  }

  void _stopDebugDecayTimer() {
    _debugDecayTimer?.cancel();
    _debugDecayTimer = null;
  }

  void _reportActivitySignal(ActivitySignal signal) {
    _lastSignal = signal;
    if (signal.shouldResetSedentary) {
      _markMovementDetected(
        detectedAt: signal.timestamp,
        statusText: signal.statusText,
      );
      if (signal.type == ActivitySignalType.wearableWorkout) {
        _wearableMockWorkoutDetected = false;
      }
      return;
    }

    final now = DateTime.now();
    final sedentaryMinutes = _calculateSedentaryMinutes(now);
    _updateState(
      sedentaryMinutes: sedentaryMinutes,
      warningLevel: _calculateWarningLevel(sedentaryMinutes, _state.intervalMinutes),
      statusText: signal.statusText,
    );
  }

  String _buildSignalSummary() {
    final signal = _lastSignal;
    if (signal == null) {
      return '暂无活动信号';
    }
    final parts = <String>[
      _activitySourceLabel(signal.source),
      _activityTypeLabel(signal.type),
    ];
    if (signal.stepDelta > 0) {
      parts.add('步数+${signal.stepDelta}');
    }
    if (signal.moveCountDelta > 0) {
      parts.add('活动次数+${signal.moveCountDelta}');
    }
    if (signal.activeMinutesDelta > 0) {
      parts.add('活动时长+${signal.activeMinutesDelta}m');
    }
    parts.add(signal.shouldResetSedentary ? '已判定有效活动' : '仅记录信号');
    return parts.join(' / ');
  }

  String _activitySourceLabel(ActivitySignalSource? source) {
    switch (source) {
      case ActivitySignalSource.sensor:
        return '手机传感器';
      case ActivitySignalSource.wearableMock:
        return '手环Mock';
      case ActivitySignalSource.oppoSdk:
        return 'OPPO 健康';
      case ActivitySignalSource.manual:
        return '手动确认';
      case ActivitySignalSource.exercise:
        return '完成运动';
      case ActivitySignalSource.debug:
        return '调试';
      case null:
        return '暂无';
    }
  }

  String _activityTypeLabel(ActivitySignalType? type) {
    switch (type) {
      case ActivitySignalType.effectiveMotion:
        return '持续活动';
      case ActivitySignalType.wearableSteps:
        return '步数变化';
      case ActivitySignalType.wearableMove:
        return '活动次数变化';
      case ActivitySignalType.wearableActiveMinutes:
        return '活动时长变化';
      case ActivitySignalType.wearableWorkout:
        return '运动记录';
      case ActivitySignalType.manualBreak:
        return '手动活动';
      case ActivitySignalType.exerciseCompleted:
        return '训练完成';
      case null:
        return '暂无';
    }
  }

  String _buildReminderDecision(DateTime now) {
    if (!_state.enabled) {
      return '不会提醒：提醒已关闭';
    }
    if (!_isAppResumed) {
      return '不会提醒：应用不在前台';
    }
    if (_dialogVisible) {
      return '不会提醒：提醒弹窗显示中';
    }
    if (_state.remindersSentToday >= _state.maxRemindersPerDay) {
      return '不会提醒：今日提醒次数已达上限';
    }
    if (_snoozeUntil != null && now.isBefore(_snoozeUntil!)) {
      return '不会提醒：当前处于稍后提醒阶段';
    }
    if (_isInAvoidPeriod(now)) {
      return '不会提醒：当前处于免打扰时段';
    }

    final nextTime = _nextReminderAt ??
        _lastMovementAt.add(Duration(minutes: _state.intervalMinutes));
    if (now.isBefore(nextTime)) {
      final remaining = nextTime.difference(now);
      return '不会提醒：还需等待 ${remaining.inMinutes} 分钟';
    }
    return '会提醒：已满足提醒条件';
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

  void _markMovementDetected({DateTime? detectedAt, String? statusText}) {
    _lastMovementAt = detectedAt ?? DateTime.now();
    _snoozeUntil = null;
    _sessionReminderCount = 0;
    _resetActivityDetection();
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
    int? remindersSentToday,
    int? sedentaryMinutes,
    int? warningLevel,
    String? statusText,
  }) {
    _state = _state.copyWith(
      nextReminderAt: nextReminderAt,
      inAvoidPeriod: inAvoidPeriod,
      remindersSentToday: remindersSentToday,
      sedentaryMinutes: sedentaryMinutes,
      warningLevel: warningLevel,
      statusText: statusText,
    );
    notifyListeners();
  }
}
