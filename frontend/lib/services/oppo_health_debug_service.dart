import 'package:flutter/foundation.dart';

import 'oppo_health_service.dart';
import 'sedentary_reminder_service.dart';

enum OppoHealthMode { mock, sdk }

class OppoHealthDebugState {
  final OppoHealthMode mode;
  final bool initialized;
  final bool authorized;
  final bool sdkReachable;
  final bool deviceConnected;
  final String statusText;
  final List<String> scopes;
  final List<OppoHealthDevice> devices;
  final int latestStepDelta;
  final int latestMoveCountDelta;
  final int latestActiveMinutesDelta;
  final bool latestWorkoutDetected;
  final String latestDataSummary;

  const OppoHealthDebugState({
    required this.mode,
    required this.initialized,
    required this.authorized,
    required this.sdkReachable,
    required this.deviceConnected,
    required this.statusText,
    required this.scopes,
    required this.devices,
    required this.latestStepDelta,
    required this.latestMoveCountDelta,
    required this.latestActiveMinutesDelta,
    required this.latestWorkoutDetected,
    required this.latestDataSummary,
  });

  factory OppoHealthDebugState.initial() {
    return const OppoHealthDebugState(
      mode: OppoHealthMode.mock,
      initialized: false,
      authorized: false,
      sdkReachable: false,
      deviceConnected: false,
      statusText: '默认使用 Mock 模式，可在有 OPPO 设备时切到 SDK 模式',
      scopes: <String>[],
      devices: <OppoHealthDevice>[],
      latestStepDelta: 0,
      latestMoveCountDelta: 0,
      latestActiveMinutesDelta: 0,
      latestWorkoutDetected: false,
      latestDataSummary: '暂无 OPPO 数据',
    );
  }

  OppoHealthDebugState copyWith({
    OppoHealthMode? mode,
    bool? initialized,
    bool? authorized,
    bool? sdkReachable,
    bool? deviceConnected,
    String? statusText,
    List<String>? scopes,
    List<OppoHealthDevice>? devices,
    int? latestStepDelta,
    int? latestMoveCountDelta,
    int? latestActiveMinutesDelta,
    bool? latestWorkoutDetected,
    String? latestDataSummary,
  }) {
    return OppoHealthDebugState(
      mode: mode ?? this.mode,
      initialized: initialized ?? this.initialized,
      authorized: authorized ?? this.authorized,
      sdkReachable: sdkReachable ?? this.sdkReachable,
      deviceConnected: deviceConnected ?? this.deviceConnected,
      statusText: statusText ?? this.statusText,
      scopes: scopes ?? this.scopes,
      devices: devices ?? this.devices,
      latestStepDelta: latestStepDelta ?? this.latestStepDelta,
      latestMoveCountDelta: latestMoveCountDelta ?? this.latestMoveCountDelta,
      latestActiveMinutesDelta:
          latestActiveMinutesDelta ?? this.latestActiveMinutesDelta,
      latestWorkoutDetected: latestWorkoutDetected ?? this.latestWorkoutDetected,
      latestDataSummary: latestDataSummary ?? this.latestDataSummary,
    );
  }
}

class OppoHealthDebugService extends ChangeNotifier {
  OppoHealthDebugService._();

  static final OppoHealthDebugService instance = OppoHealthDebugService._();

  final OppoHealthService _service = OppoHealthService.instance;

  OppoHealthDebugState _state = OppoHealthDebugState.initial();
  OppoHealthDebugState get state => _state;

  void setMode(OppoHealthMode mode) {
    _state = _state.copyWith(
      mode: mode,
      statusText: mode == OppoHealthMode.mock
          ? '已切换到 Mock 模式，可直接模拟 OPPO 活动数据'
          : '已切换到 SDK 模式，请在 OPPO 手机上完成授权并读取数据',
    );
    notifyListeners();
  }

  Future<void> initializeSdk() async {
    try {
      await _service.initialize();
      _state = _state.copyWith(
        initialized: true,
        sdkReachable: true,
        statusText: 'OPPO 健康 SDK 初始化成功',
      );
    } catch (error) {
      _state = _state.copyWith(
        sdkReachable: false,
        statusText: _friendlyError('initialize', error),
      );
    }
    notifyListeners();
  }

  Future<void> requestAuthorization() async {
    try {
      await _service.requestAuthorization();
      _state = _state.copyWith(statusText: '已发起 OPPO 健康授权请求');
    } catch (error) {
      _state = _state.copyWith(statusText: _friendlyError('requestAuth', error));
    }
    notifyListeners();
  }

  Future<void> validateAuthorization() async {
    try {
      final auth = await _service.validateAuthorization();
      _state = _state.copyWith(
        authorized: auth.authorized,
        scopes: auth.scopes,
        sdkReachable: true,
        statusText: auth.authorized
            ? '已获取授权，可继续查询设备和健康数据'
            : '当前未授权或无可用权限范围',
      );
    } catch (error) {
      _state = _state.copyWith(statusText: _friendlyError('validateAuth', error));
    }
    notifyListeners();
  }

  Future<void> queryBoundDevices() async {
    try {
      final devices = await _service.queryBoundDevices();
      final connected = devices.any((device) => (device.connectionState ?? 0) > 0);
      _state = _state.copyWith(
        devices: devices,
        deviceConnected: connected,
        statusText: devices.isEmpty ? '未查询到绑定设备' : '已读取绑定设备列表',
      );
      SedentaryReminderService.instance.setOppoWearableConnection(connected);
    } catch (error) {
      _state = _state.copyWith(statusText: _friendlyError('queryDevices', error));
    }
    notifyListeners();
  }

  Future<void> readTodayData() async {
    try {
      final activity = await _service.readTodayDailyActivity();
      final activityCount = await _service.readTodayDailyActivityCount();
      final sport = await _service.readTodaySportMetadata();

      final summary = _extractSummary(
        activity: activity,
        activityCount: activityCount,
        sport: sport,
      );

      _state = _state.copyWith(
        latestStepDelta: summary.stepDelta,
        latestMoveCountDelta: summary.moveCountDelta,
        latestActiveMinutesDelta: summary.activeMinutesDelta,
        latestWorkoutDetected: summary.workoutDetected,
        latestDataSummary: summary.label,
        statusText: '已读取今日 OPPO 健康数据',
      );

      SedentaryReminderService.instance.setOppoWearableConnection(
        _state.deviceConnected || summary.hasAnySignal,
      );
      SedentaryReminderService.instance.ingestOppoActivityData(
        stepDelta: summary.stepDelta,
        moveCountDelta: summary.moveCountDelta,
        activeMinutesDelta: summary.activeMinutesDelta,
        workoutDetected: summary.workoutDetected,
      );
    } catch (error) {
      _state = _state.copyWith(statusText: _friendlyError('readData', error));
    }
    notifyListeners();
  }

  void mockConnectDevice(bool connected) {
    _state = _state.copyWith(
      deviceConnected: connected,
      statusText: connected ? 'Mock 设备已连接' : 'Mock 设备已断开',
    );
    SedentaryReminderService.instance.setOppoWearableConnection(connected);
    notifyListeners();
  }

  void mockStepDelta(int stepDelta) {
    _applyMock(stepDelta: stepDelta);
  }

  void mockMoveCount(int moveCountDelta) {
    _applyMock(moveCountDelta: moveCountDelta);
  }

  void mockActiveMinutes(int activeMinutesDelta) {
    _applyMock(activeMinutesDelta: activeMinutesDelta);
  }

  void mockWorkout() {
    _applyMock(workoutDetected: true);
  }

  void _applyMock({
    int stepDelta = 0,
    int moveCountDelta = 0,
    int activeMinutesDelta = 0,
    bool workoutDetected = false,
  }) {
    _state = _state.copyWith(
      deviceConnected: true,
      latestStepDelta: stepDelta,
      latestMoveCountDelta: moveCountDelta,
      latestActiveMinutesDelta: activeMinutesDelta,
      latestWorkoutDetected: workoutDetected,
      latestDataSummary: _buildSummaryText(
        stepDelta: stepDelta,
        moveCountDelta: moveCountDelta,
        activeMinutesDelta: activeMinutesDelta,
        workoutDetected: workoutDetected,
      ),
      statusText: '已注入 Mock OPPO 健康数据',
    );

    SedentaryReminderService.instance.setOppoWearableConnection(true);
    SedentaryReminderService.instance.ingestOppoActivityData(
      stepDelta: stepDelta,
      moveCountDelta: moveCountDelta,
      activeMinutesDelta: activeMinutesDelta,
      workoutDetected: workoutDetected,
    );
    notifyListeners();
  }

  _OppoDataSummary _extractSummary({
    required OppoHealthDataResponse activity,
    required OppoHealthDataResponse activityCount,
    required OppoHealthDataResponse sport,
  }) {
    int stepDelta = 0;
    int moveCountDelta = 0;
    int activeMinutesDelta = 0;

    for (final dataSet in activity.dataSets) {
      final points = (dataSet['points'] as List<dynamic>? ?? const []);
      for (final point in points.whereType<Map>()) {
        stepDelta = _max(stepDelta, _asInt(point['step']) ?? 0);
        moveCountDelta = _max(moveCountDelta, _asInt(point['moveTime']) ?? 0);
        activeMinutesDelta = _max(activeMinutesDelta, _asInt(point['workMinute']) ?? 0);
      }
    }

    for (final dataSet in activityCount.dataSets) {
      final points = (dataSet['points'] as List<dynamic>? ?? const []);
      for (final point in points.whereType<Map>()) {
        stepDelta = _max(stepDelta, _asInt(point['step']) ?? 0);
        moveCountDelta = _max(moveCountDelta, _asInt(point['moveTime']) ?? 0);
        activeMinutesDelta = _max(activeMinutesDelta, _asInt(point['workMinute']) ?? 0);
      }
    }

    final workoutDetected = sport.dataSets.any((dataSet) {
      final points = (dataSet['points'] as List<dynamic>? ?? const []);
      return points.isNotEmpty;
    });

    return _OppoDataSummary(
      stepDelta: stepDelta,
      moveCountDelta: moveCountDelta,
      activeMinutesDelta: activeMinutesDelta,
      workoutDetected: workoutDetected,
      label: _buildSummaryText(
        stepDelta: stepDelta,
        moveCountDelta: moveCountDelta,
        activeMinutesDelta: activeMinutesDelta,
        workoutDetected: workoutDetected,
      ),
    );
  }

  String _buildSummaryText({
    required int stepDelta,
    required int moveCountDelta,
    required int activeMinutesDelta,
    required bool workoutDetected,
  }) {
    final parts = <String>[];
    if (stepDelta > 0) parts.add('步数+$stepDelta');
    if (moveCountDelta > 0) parts.add('活动次数+$moveCountDelta');
    if (activeMinutesDelta > 0) parts.add('活动时长+${activeMinutesDelta}m');
    if (workoutDetected) parts.add('检测到运动记录');
    return parts.isEmpty ? '暂无有效 OPPO 活动信号' : parts.join(' / ');
  }

  String _friendlyError(String action, Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    String actionText;
    switch (action) {
      case 'initialize':
        actionText = '初始化 SDK 失败';
        break;
      case 'requestAuth':
        actionText = '请求授权失败';
        break;
      case 'validateAuth':
        actionText = '校验授权失败';
        break;
      case 'queryDevices':
        actionText = '查询设备失败';
        break;
      case 'readData':
        actionText = '读取健康数据失败';
        break;
      default:
        actionText = '调用失败';
    }

    final hints = <String>[];

    if (lower.contains('platformexception') || lower.contains('missingplugin')) {
      hints.add('可能当前平台不支持，或原生桥接尚未在该设备环境生效');
    }
    if (lower.contains('notimplemented')) {
      hints.add('当前方法在此设备环境下不可用');
    }
    if (lower.contains('auth') || lower.contains('permission')) {
      hints.add('请确认已安装 OPPO 健康 App，并在 OPPO 手机上完成授权');
    }
    if (lower.contains('device') || lower.contains('bound')) {
      hints.add('请确认 OPPO 健康中已绑定手环或手表设备');
    }
    if (lower.contains('read') || lower.contains('data')) {
      hints.add('可能没有可读取的健康数据，或当前没有连接可穿戴设备');
    }
    if (hints.isEmpty) {
      hints.add('如果当前没有 OPPO 手机或穿戴设备，建议先切换到 Mock 模式继续调试');
    }

    return '$actionText：${hints.join('；')}';
  }
}

class _OppoDataSummary {
  final int stepDelta;
  final int moveCountDelta;
  final int activeMinutesDelta;
  final bool workoutDetected;
  final String label;

  const _OppoDataSummary({
    required this.stepDelta,
    required this.moveCountDelta,
    required this.activeMinutesDelta,
    required this.workoutDetected,
    required this.label,
  });

  bool get hasAnySignal =>
      stepDelta > 0 || moveCountDelta > 0 || activeMinutesDelta > 0 || workoutDetected;
}

int _max(int a, int b) => a > b ? a : b;

int? _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}
