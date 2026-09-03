import 'package:bdo_event/core/common/app_keyboard_tracker/app_keyboard_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(AppKeyboardTracker.dispose);
  tearDown(AppKeyboardTracker.dispose);

  test('initializes the observer once and disposes it safely', () {
    AppKeyboardTracker.initialize();
    AppKeyboardTracker.initialize();

    expect(AppKeyboardTracker.isInitialized, isTrue);

    AppKeyboardTracker.dispose();
    AppKeyboardTracker.dispose();

    expect(AppKeyboardTracker.isInitialized, isFalse);
    expect(AppKeyboardTracker.isKeyboardVisible.value, isFalse);
  });
}
