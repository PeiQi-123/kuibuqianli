import 'package:flutter_test/flutter_test.dart';
import 'package:micro_exercise_frontend/services/sensor_service.dart';

void main() {
  group('SensorService.detectPosture', () {
    test('identifies free fall when acceleration is very small', () {
      expect(
        SensorService.detectPosture(0.1, 0.1, 0.1),
        '\u81ea\u7531\u4e0b\u843d',
      );
    });

    test('identifies portrait orientation from y axis', () {
      expect(
        SensorService.detectPosture(0, 9.2, 0),
        '\u76f4\u7acb\uff08\u7ad6\u5c4f\uff09',
      );
    });

    test('identifies face up orientation from z axis', () {
      expect(
        SensorService.detectPosture(0, 0, 9.5),
        '\u624b\u673a\u5e73\u653e\uff08\u5c4f\u5e55\u671d\u4e0a\uff09',
      );
    });

    test('falls back to moving state when no posture threshold matches', () {
      expect(
        SensorService.detectPosture(2.5, 2.5, 2.5),
        '\u79fb\u52a8\u4e2d',
      );
    });
  });
}
