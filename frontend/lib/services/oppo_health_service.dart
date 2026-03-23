import 'package:flutter/services.dart';

class OppoHealthDevice {
  final String? deviceName;
  final int? deviceType;
  final int? subDeviceType;
  final String? model;
  final String? manufacturer;
  final int? connectionState;

  const OppoHealthDevice({
    required this.deviceName,
    required this.deviceType,
    required this.subDeviceType,
    required this.model,
    required this.manufacturer,
    required this.connectionState,
  });

  factory OppoHealthDevice.fromMap(Map<dynamic, dynamic> map) {
    return OppoHealthDevice(
      deviceName: map['deviceName']?.toString(),
      deviceType: _asInt(map['deviceType']),
      subDeviceType: _asInt(map['subDeviceType']),
      model: map['model']?.toString(),
      manufacturer: map['manufacturer']?.toString(),
      connectionState: _asInt(map['connectionState']),
    );
  }
}

class OppoHealthAuthorizationState {
  final bool authorized;
  final List<String> scopes;

  const OppoHealthAuthorizationState({
    required this.authorized,
    required this.scopes,
  });

  factory OppoHealthAuthorizationState.fromMap(Map<dynamic, dynamic> map) {
    final rawScopes = map['scopes'] as List<dynamic>? ?? const [];
    return OppoHealthAuthorizationState(
      authorized: map['authorized'] == true,
      scopes: rawScopes.map((item) => item.toString()).toList(),
    );
  }
}

class OppoHealthDataResponse {
  final String? dataType;
  final int? startTime;
  final int? endTime;
  final List<Map<String, dynamic>> dataSets;

  const OppoHealthDataResponse({
    required this.dataType,
    required this.startTime,
    required this.endTime,
    required this.dataSets,
  });

  factory OppoHealthDataResponse.fromMap(Map<dynamic, dynamic> map) {
    final rawDataSets = map['dataSets'] as List<dynamic>? ?? const [];
    return OppoHealthDataResponse(
      dataType: map['dataType']?.toString(),
      startTime: _asInt(map['startTime']),
      endTime: _asInt(map['endTime']),
      dataSets: rawDataSets
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}

class OppoHealthService {
  OppoHealthService._();

  static final OppoHealthService instance = OppoHealthService._();

  static const MethodChannel _channel = MethodChannel('kuibuqianli/oppo_health');

  Future<Map<String, dynamic>> initialize() async {
    final result = await _channel.invokeMethod<dynamic>('initialize');
    return Map<String, dynamic>.from((result as Map).cast<String, dynamic>());
  }

  Future<void> requestAuthorization() async {
    await _channel.invokeMethod<dynamic>('requestAuthorization');
  }

  Future<OppoHealthAuthorizationState> validateAuthorization() async {
    final result = await _channel.invokeMethod<dynamic>('validateAuthorization');
    return OppoHealthAuthorizationState.fromMap(result as Map);
  }

  Future<void> revokeAuthorization() async {
    await _channel.invokeMethod<dynamic>('revokeAuthorization');
  }

  Future<List<OppoHealthDevice>> queryBoundDevices() async {
    final result = await _channel.invokeMethod<dynamic>('queryBoundDevices');
    final devices = result as List<dynamic>? ?? const [];
    return devices
        .whereType<Map>()
        .map((item) => OppoHealthDevice.fromMap(item))
        .toList();
  }

  Future<OppoHealthDataResponse> readTodayDailyActivity() async {
    final result = await _channel.invokeMethod<dynamic>('readTodayDailyActivity');
    return OppoHealthDataResponse.fromMap(result as Map);
  }

  Future<OppoHealthDataResponse> readTodayDailyActivityCount() async {
    final result =
        await _channel.invokeMethod<dynamic>('readTodayDailyActivityCount');
    return OppoHealthDataResponse.fromMap(result as Map);
  }

  Future<OppoHealthDataResponse> readTodaySportMetadata() async {
    final result = await _channel.invokeMethod<dynamic>('readTodaySportMetadata');
    return OppoHealthDataResponse.fromMap(result as Map);
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}
