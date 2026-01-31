// Flutter应用主入口
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'utils/sensor_initializer.dart';

void main() {
  SensorInitializer.initializeSensors(); // 先启动传感器
  runApp(const MyApp());
}
