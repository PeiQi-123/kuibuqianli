// 传感器服务
import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  final StreamController<Map<String, double>> _sensorDataController =
      StreamController<Map<String, double>>.broadcast();

  Stream<Map<String, double>> get sensorDataStream => _sensorDataController.stream;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  void startListening() {
    if (_isRunning) return;
    _isRunning = true;

    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _sensorDataController.add(<String, double>{
        'ax': event.x,
        'ay': event.y,
        'az': event.z,
      });
    });

    _gyroscopeSubscription = gyroscopeEventStream().listen((event) {
      _sensorDataController.add(<String, double>{
        'gx': event.x,
        'gy': event.y,
        'gz': event.z,
      });
    });
  }

  void stopListening() {
    _isRunning = false;
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
  }

  void dispose() {
    stopListening();
    _sensorDataController.close();
  }

  static String detectPosture(double ax, double ay, double az) {
    final double magnitude = (ax * ax + ay * ay + az * az);

    if (magnitude < 1) {
      return '自由下落';
    } else if (az > 8) {
      return '手机平放（屏幕朝上）';
    } else if (az < -8) {
      return '手机平放（屏幕朝下）';
    } else if (ay > 8) {
      return '直立（竖屏）';
    } else if (ay < -8) {
      return '倒立';
    } else if (ax > 8) {
      return '横屏（左侧朝上）';
    } else if (ax < -8) {
      return '横屏（右侧朝上）';
    }

    return '移动中';
  }
}
