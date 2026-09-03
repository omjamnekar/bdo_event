import 'package:bdo_event/core/security/biometric.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/fixtures/biometric_adapter.dart';

void main() {
  test('reports availability from the biometric adapter', () async {
    final adapter = RecordingBiometricAdapter();
    final service = BiometricLockService(adapter: adapter);

    expect(await service.isAvailable(), isTrue);
    expect(adapter.availabilityCalls, 1);
  });

  test('unlocks through the adapter when biometrics are available', () async {
    final adapter = RecordingBiometricAdapter();
    final service = BiometricLockService(adapter: adapter);

    expect(await service.unlock(), isTrue);
    expect(adapter.authenticationCalls, 1);
    expect(
      adapter.localizedReason,
      'Authenticate to open your event account',
    );
  });

  test('does not authenticate when biometrics are unavailable', () async {
    final adapter = RecordingBiometricAdapter(available: false);
    final service = BiometricLockService(adapter: adapter);

    expect(await service.unlock(), isFalse);
    expect(adapter.authenticationCalls, 0);
  });

  test('maps adapter failures to unavailable or locked results', () async {
    final unavailable = BiometricLockService(
      adapter: RecordingBiometricAdapter(
        availabilityError: StateError('unavailable'),
      ),
    );
    final locked = BiometricLockService(
      adapter: RecordingBiometricAdapter(
        authenticationError: StateError('locked'),
      ),
    );

    expect(await unavailable.isAvailable(), isFalse);
    expect(await unavailable.unlock(), isFalse);
    expect(await locked.unlock(), isFalse);
  });
}
