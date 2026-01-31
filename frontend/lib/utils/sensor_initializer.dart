// lib/utils/sensor_initializer.dart
import '../services/sensor_service.dart';

class SensorInitializer {
  static SensorService? _sensorService;

  static void initializeSensors() {
    _sensorService = SensorService();
    _sensorService!.startSensorMonitoring();
  }

  static void disposeSensors() {
    _sensorService?.stopSensorMonitoring();
  }
}
