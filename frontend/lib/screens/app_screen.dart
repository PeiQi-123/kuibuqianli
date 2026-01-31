// lib/screens/app_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/sensor_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  final SensorService _sensorService = SensorService();

  // 传感器数据状态
  AccelerometerEvent? _accelData;
  GyroscopeEvent? _gyroData;
  double? _totalAcceleration;
  double? _angularVelocity;

  Timer? _dataUpdateTimer;
  String _sensorStatus = '等待启动...';
  int _updateCount = 0;
  bool _isMonitoring = false;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    try {
      // 启动传感器监控
      _sensorService.startSensorMonitoring();
      setState(() {
        _sensorStatus = '传感器监控已启动';
        _isMonitoring = true;
      });

      // 设置定时器更新UI数据（每300ms更新一次）
      _dataUpdateTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
        if (mounted) {
          _updateSensorData();
        }
      });
    } catch (e) {
      setState(() {
        _sensorStatus = '传感器启动失败: $e';
      });
    }
  }

  void _updateSensorData() {
    setState(() {
      _accelData = _sensorService.accelData;
      _gyroData = _sensorService.gyroData;
      _updateCount++;

      if (_accelData != null) {
        _totalAcceleration = math.sqrt(
            _accelData!.x * _accelData!.x +
                _accelData!.y * _accelData!.y +
                _accelData!.z * _accelData!.z
        );
      } else {
        _totalAcceleration = null;
      }

      if (_gyroData != null) {
        _angularVelocity = math.sqrt(
            _gyroData!.x * _gyroData!.x +
                _gyroData!.y * _gyroData!.y +
                _gyroData!.z * _gyroData!.z
        );
      } else {
        _angularVelocity = null;
      }
    });
  }

  void _startSensorMonitoring() {
    _sensorService.startSensorMonitoring();
    setState(() {
      _sensorStatus = '传感器监控已启动';
      _isMonitoring = true;
    });

    // 重新启动定时器
    _dataUpdateTimer?.cancel();
    _dataUpdateTimer = Timer.periodic(Duration(milliseconds: 300), (timer) {
      if (mounted) {
        _updateSensorData();
      }
    });
  }

  void _stopSensorMonitoring() {
    _sensorService.stopSensorMonitoring();
    _dataUpdateTimer?.cancel();
    setState(() {
      _sensorStatus = '传感器已停止';
      _isMonitoring = false;
      _accelData = null;
      _gyroData = null;
      _totalAcceleration = null;
      _angularVelocity = null;
    });
  }

  @override
  void dispose() {
    _dataUpdateTimer?.cancel();
    _sensorService.stopSensorMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('跬步千里 - 传感器测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_walk,
                size: 100,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                '传感器数据监控',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '实时显示手机传感器数据',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // 传感器状态卡片
              Card(
                color: _sensorStatus.contains('失败') ? Colors.red[50] :
                _isMonitoring ? Colors.green[50] : Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _sensorStatus.contains('失败') ? Icons.error :
                            _isMonitoring ? Icons.sensors : Icons.sensors_off,
                            color: _sensorStatus.contains('失败') ? Colors.red :
                            _isMonitoring ? Colors.green : Colors.blue,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '传感器状态',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                _sensorStatus,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _sensorStatus.contains('失败') ? Colors.red :
                                  _isMonitoring ? Colors.green : Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '更新次数: $_updateCount',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 传感器数据显示区域
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 加速度计数据
                    _buildSensorSection(
                      title: '加速度计 (m/s²)',
                      icon: Icons.speed,
                      iconColor: Colors.green,
                      data: _accelData,
                      totalValue: _totalAcceleration,
                      unit: 'm/s²',
                      isAccelerometer: true,
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    // 陀螺仪数据
                    _buildSensorSection(
                      title: '陀螺仪 (rad/s)',
                      icon: Icons.rotate_right,
                      iconColor: Colors.orange,
                      data: _gyroData,
                      totalValue: _angularVelocity,
                      unit: 'rad/s',
                      isAccelerometer: false,
                    ),

                    const SizedBox(height: 16),

                    // 数据状态提示
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _accelData != null && _gyroData != null
                                ? Icons.check_circle
                                : Icons.warning,
                            color: _accelData != null && _gyroData != null
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _accelData != null && _gyroData != null
                                  ? '✅ 传感器数据接收正常'
                                  : '⚠️ 等待传感器数据...',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _startSensorMonitoring,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始监控'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _stopSensorMonitoring,
                    icon: const Icon(Icons.stop),
                    label: const Text('停止监控'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () {
                  _updateSensorData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('手动刷新数据 #$_updateCount'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('刷新数据'),
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('进入主页'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSensorSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required dynamic data,
    required double? totalValue,
    required String unit,
    required bool isAccelerometer,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 数据行
        _buildDataRow('X轴', data?.x ?? 0.0, unit),
        _buildDataRow('Y轴', data?.y ?? 0.0, unit),
        _buildDataRow('Z轴', data?.z ?? 0.0, unit),

        const SizedBox(height: 12),

        // 总值显示
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: iconColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAccelerometer ? '总加速度' : '角速度幅值',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              Text(
                totalValue?.toStringAsFixed(4) ?? '0.0000',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 数据状态
        Text(
          data != null
              ? '✅ 数据实时更新中'
              : '⏳ 等待数据...',
          style: TextStyle(
            fontSize: 14,
            color: data != null ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(String axis, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            axis,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${value.toStringAsFixed(4)} $unit',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}