import 'package:flutter_test/flutter_test.dart';

import 'package:bdo_event/core/di/app_dependencies.dart';

void main() {
  test('resetDependencies disposes and unregisters services', () async {
    final probe = _DisposableProbe();
    getIt.registerSingleton<_DisposableProbe>(
      probe,
      dispose: (value) => value.dispose(),
    );

    await resetDependencies();

    expect(probe.wasDisposed, isTrue);
    expect(getIt.isRegistered<_DisposableProbe>(), isFalse);
  });
}

class _DisposableProbe {
  bool wasDisposed = false;

  void dispose() => wasDisposed = true;
}
