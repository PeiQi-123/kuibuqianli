import 'package:flutter_test/flutter_test.dart';
import 'package:micro_exercise_frontend/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saves and removes token correctly', () async {
    await StorageService.saveToken('token-123');
    expect(await StorageService.getToken(), 'token-123');

    await StorageService.removeToken();
    expect(await StorageService.getToken(), isNull);
  });

  test('saves and removes user id correctly', () async {
    await StorageService.saveUserId('42');
    expect(await StorageService.getUserId(), '42');

    await StorageService.removeUserId();
    expect(await StorageService.getUserId(), isNull);
  });

  test('tracks onboarding completion flag', () async {
    expect(await StorageService.isOnboardingCompleted(), isFalse);

    await StorageService.markOnboardingCompleted();
    expect(await StorageService.isOnboardingCompleted(), isTrue);

    await StorageService.clearOnboardingStatus();
    expect(await StorageService.isOnboardingCompleted(), isFalse);
  });
}
