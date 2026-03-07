// 姿态检测页面
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/sensor_service.dart';

class PostureDetectionScreen extends StatefulWidget {
  const PostureDetectionScreen({super.key});

  @override
  State<PostureDetectionScreen> createState() => _PostureDetectionScreenState();
}

class _PostureDetectionScreenState extends State<PostureDetectionScreen> {
  final SensorService _sensorService = SensorService();
  StreamSubscription? _sensorSubscription;

  bool _isSensorMode = false;
  bool _isListening = false;
  String _currentPosture = '未知';

  double _simAx = 0, _simAy = 0, _simAz = 9.8;

  @override
  void initState() {
    super.initState();
    if (_isSensorMode) {
      _startSensor();
    }
  }

  void _startSensor() {
    if (_isListening) return;
    _isListening = true;
    _sensorService.startListening();
    _sensorSubscription = _sensorService.sensorDataStream.listen((data) {
      if (!mounted) return;
      setState(() {
        if (data.containsKey('ax')) {
          _simAx = data['ax']!;
          _simAy = data['ay']!;
          _simAz = data['az']!;
          _currentPosture = SensorService.detectPosture(_simAx, _simAy, _simAz);
        }
      });
    });
  }

  void _stopSensor() {
    _isListening = false;
    _sensorService.stopListening();
    _sensorSubscription?.cancel();
  }

  @override
  void dispose() {
    _stopSensor();
    _sensorService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('姿态检测'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isSensorMode = !_isSensorMode;
                if (_isSensorMode) {
                  _startSensor();
                } else {
                  _stopSensor();
                }
              });
            },
            icon: Icon(_isSensorMode ? Icons.phone_android : Icons.desktop_windows),
            label: Text(_isSensorMode ? '手机模式' : '电脑模拟'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _isSensorMode ? Icons.phone_android : Icons.desktop_windows,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSensorMode ? '手机传感器模式' : '电脑模拟模式',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isSensorMode
                          ? '使用手机加速度计和陀螺仪检测姿态'
                          : '点击下方按钮模拟不同姿势',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      '当前姿态',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentPosture,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSensorData(),
            const SizedBox(height: 16),
            if (!_isSensorMode) _buildSimulationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorData() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSensorMode ? '实时传感器数据' : '模拟传感器数据',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildDataRow('加速度 X (ax)', _simAx.toStringAsFixed(2)),
            _buildDataRow('加速度 Y (ay)', _simAy.toStringAsFixed(2)),
            _buildDataRow('加速度 Z (az)', _simAz.toStringAsFixed(2)),
            if (_isSensorMode) ...[
              const Divider(),
              const Text(
                '💡 晃动手机或改变手机方向来测试',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '模拟姿势按钮',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.5,
          children: [
            _buildSimButton('竖屏直立', 0, 9.8, 0, Icons.phone_android),
            _buildSimButton('横屏左侧', 9.8, 0, 0, Icons.screen_rotation),
            _buildSimButton('横屏右侧', -9.8, 0, 0, Icons.screen_rotation),
            _buildSimButton('屏幕朝上', 0, 0, 9.8, Icons.flip),
            _buildSimButton('屏幕朝下', 0, 0, -9.8, Icons.flip),
            _buildSimButton('自由下落', 0, 0, 0, Icons.flight),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '手动调整传感器数据',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildSlider('ax', '加速度 X', -20.0, 20.0),
                _buildSlider('ay', '加速度 Y', -20.0, 20.0),
                _buildSlider('az', '加速度 Z', -20.0, 20.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimButton(String label, double ax, double ay, double az, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _simAx = ax;
          _simAy = ay;
          _simAz = az;
          _currentPosture = SensorService.detectPosture(ax, ay, az);
        });
      },
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildSlider(String key, String label, double min, double max) {
    double value;
    if (key == 'ax') value = _simAx;
    else if (key == 'ay') value = _simAy;
    else value = _simAz;

    return Row(
      children: [
        SizedBox(width: 80, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: (v) {
              setState(() {
                if (key == 'ax') _simAx = v;
                else if (key == 'ay') _simAy = v;
                else _simAz = v;
                _currentPosture = SensorService.detectPosture(_simAx, _simAy, _simAz);
              });
            },
          ),
        ),
        SizedBox(width: 50, child: Text(value.toStringAsFixed(1))),
      ],
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
