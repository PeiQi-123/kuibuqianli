// lib/services/sensor_service.dart
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:math' as math;

class SensorService {
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  AccelerometerEvent? _latestAccelData;
  GyroscopeEvent? _latestGyroData;
  Timer? _displayTimer;

  AccelerometerEvent? get accelData => _latestAccelData;
  GyroscopeEvent? get gyroData => _latestGyroData;

  String _statusMessage = '未启动';
  String get statusMessage => _statusMessage;

  // 检查并请求权限
  Future<bool> _checkAndRequestPermissions() async {
    try {
      // 检查传感器权限
      var status = await Permission.sensors.status;

      if (!status.isGranted) {
        status = await Permission.sensors.request();
      }

      if (status.isGranted) {
        _statusMessage = '传感器权限已授予';
        return true;
      } else {
        _statusMessage = '传感器权限被拒绝';
        return false;
      }
    } catch (e) {
      _statusMessage = '权限检查错误: $e';
      return false;
    }
  }

  // 开始监听传感器数据
  Future<void> startSensorMonitoring() async {
    print('🚀 开始启动传感器监控...');

    // 检查权限
    bool hasPermission = await _checkAndRequestPermissions();
    if (!hasPermission) {
      print('❌ 没有传感器权限，无法启动监控');
      return;
    }

    try {
      // 检查传感器是否可用
      print('🔍 检查传感器可用性...');

      // 监听加速度计数据
      _accelerometerSubscription = accelerometerEvents.listen(
            (AccelerometerEvent event) {
          _latestAccelData = event;
          print('📱 收到加速度数据: X=${event.x.toStringAsFixed(2)}');
        },
        onError: (error) {
          print('❌ 加速度计监听错误: $error');
          _statusMessage = '加速度计错误: $error';
        },
        cancelOnError: true,
      );

      // 监听陀螺仪数据
      _gyroscopeSubscription = gyroscopeEvents.listen(
            (GyroscopeEvent event) {
          _latestGyroData = event;
          print('🔄 收到陀螺仪数据: X=${event.x.toStringAsFixed(2)}');
        },
        onError: (error) {
          print('❌ 陀螺仪监听错误: $error');
          _statusMessage = '陀螺仪错误: $error';
        },
        cancelOnError: true,
      );

      // 添加超时检查
      Timer(Duration(seconds: 3), () {
        if (_latestAccelData == null && _latestGyroData == null) {
          print('⚠️ 警告：3秒后仍未收到传感器数据');
          _statusMessage = '警告：未检测到传感器数据';
        }
      });

      // 每0.5秒显示一次数据
      _displayTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
        _printSensorData();
      });

      _statusMessage = '传感器监控已启动';
      print('✅ 传感器监控成功启动');

    } catch (e) {
      print('❌ 启动传感器监控失败: $e');
      _statusMessage = '启动失败: $e';

      // 尝试使用备用方法
      _tryAlternativeMethod();
    }
  }

  // 备用方法：检查传感器可用性
  void _tryAlternativeMethod() {
    print('🔄 尝试备用方法检查传感器...');

    // 尝试一次性读取传感器数据
    accelerometerEvents.first.then((event) {
      print('✅ 备用方法：检测到加速度计');
      _latestAccelData = event;
      _statusMessage = '检测到加速度计';
    }).catchError((error) {
      print('❌ 备用方法：加速度计不可用: $error');
    });

    gyroscopeEvents.first.then((event) {
      print('✅ 备用方法：检测到陀螺仪');
      _latestGyroData = event;
      _statusMessage += '，检测到陀螺仪';
    }).catchError((error) {
      print('❌ 备用方法：陀螺仪不可用: $error');
    });
  }

  // 显示传感器数据到终端
  void _printSensorData() {
    print('\n--- 传感器数据更新 ---');
    print('状态: $_statusMessage');

    if (_latestAccelData != null) {
      print('加速度计数据:');
      print('  X轴: ${_latestAccelData!.x.toStringAsFixed(4)} m/s²');
      print('  Y轴: ${_latestAccelData!.y.toStringAsFixed(4)} m/s²');
      print('  Z轴: ${_latestAccelData!.z.toStringAsFixed(4)} m/s²');

      double totalAccel = math.sqrt(
          _latestAccelData!.x * _latestAccelData!.x +
              _latestAccelData!.y * _latestAccelData!.y +
              _latestAccelData!.z * _latestAccelData!.z
      );
      print('  总加速度: ${totalAccel.toStringAsFixed(4)} m/s²');
    } else {
      print('加速度计数据: 未获取到');
    }

    if (_latestGyroData != null) {
      print('陀螺仪数据:');
      print('  X轴: ${_latestGyroData!.x.toStringAsFixed(4)} rad/s');
      print('  Y轴: ${_latestGyroData!.y.toStringAsFixed(4)} rad/s');
      print('  Z轴: ${_latestGyroData!.z.toStringAsFixed(4)} rad/s');

      double angularVelocity = math.sqrt(
          _latestGyroData!.x * _latestGyroData!.x +
              _latestGyroData!.y * _latestGyroData!.y +
              _latestGyroData!.z * _latestGyroData!.z
      );
      print('  角速度幅值: ${angularVelocity.toStringAsFixed(4)} rad/s');
    } else {
      print('陀螺仪数据: 未获取到');
    }

    print('时间戳: ${DateTime.now()}');
    print('------------------------\n');
  }

  // 停止监听传感器
  void stopSensorMonitoring() {
    print('🛑 停止传感器监控...');
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _displayTimer?.cancel();
    _statusMessage = '传感器已停止';
  }
}