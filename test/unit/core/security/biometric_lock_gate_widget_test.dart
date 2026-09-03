import 'dart:async';

import 'package:bdo_event/core/security/biometric_adapter.dart';
import 'package:bdo_event/core/di/app_dependencies.dart';
import 'package:bdo_event/core/security/biometric_lock_gate.dart';
import 'package:bdo_event/core/security/biometric_lock_service.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/auth_screen/presentation/cubit/auth_screen_cubit.dart';
import 'package:bdo_event/features/auth_screen/presentation/pages/auth_screen.dart';
import 'package:bdo_event/features/profile_screen/domain/entities/profile_preferences.dart';
import 'package:bdo_event/features/profile_screen/presentation/cubit/profile_screen_cubit.dart';
import 'package:bdo_event/features/main_screen/presentation/cubit/main_screen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/profile_screen/presentation/cubit/profile_screen_cubit_test.dart'
    as profile_fixtures;
import '../../shared/fixtures/biometric_adapter.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('locks an enabled account after the first frame', (tester) async {
    final profileCubit = profile_fixtures.createCubit(
      preferences: const ProfilePreferences(isBiometricLockEnabled: true),
    );
    registerBiometricService(RecordingBiometricAdapter());

    await pumpGate(tester, profileCubit);

    expect(find.text(AppText.unlockApp), findsOneWidget);
    expect(find.text('Protected content'), findsOneWidget);
    await profileCubit.close();
  });

  testWidgets('keeps the lock when the biometric service is unavailable', (
    tester,
  ) async {
    final profileCubit = profileFixturesWithLock();

    await pumpGate(tester, profileCubit);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text(AppText.unlockApp), findsOneWidget);
    expect(tester.takeException(), isNull);
    await profileCubit.close();
  });

  testWidgets('mounts the gate from the authenticated auth path', (
    tester,
  ) async {
    final authCubit = AuthScreenCubit(
      authRepository: profile_fixtures.FakeAuthRepository(),
    )..authenticationSucceeded();
    final mainCubit = MainScreenCubit();
    final profileCubit = profileFixturesWithLock();
    registerBiometricService(RecordingBiometricAdapter());

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: authCubit),
            BlocProvider.value(value: mainCubit),
            BlocProvider.value(value: profileCubit),
          ],
          child: const AuthScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BiometricLockGate), findsOneWidget);
    expect(find.text(AppText.unlockApp), findsOneWidget);
    await authCubit.close();
    await mainCubit.close();
    await profileCubit.close();
  });

  testWidgets('authenticates on resume and removes the lock on success', (
    tester,
  ) async {
    final adapter = RecordingBiometricAdapter();
    final profileCubit = profileFixturesWithLock();
    registerBiometricService(adapter);

    await pumpGate(tester, profileCubit);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(adapter.authenticationCalls, 1);
    expect(find.text(AppText.unlockApp), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(find.text(AppText.unlockApp), findsOneWidget);

    await profileCubit.close();
  });

  testWidgets('keeps the lock visible when authentication fails', (
    tester,
  ) async {
    final adapter = RecordingBiometricAdapter(authenticated: false);
    final profileCubit = profileFixturesWithLock();
    registerBiometricService(adapter);

    await pumpGate(tester, profileCubit);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(adapter.authenticationCalls, 1);
    expect(find.text(AppText.unlockApp), findsOneWidget);
    await profileCubit.close();
  });

  testWidgets('removes the lock when the preference is disabled', (
    tester,
  ) async {
    final profileCubit = profileFixturesWithLock();
    registerBiometricService(RecordingBiometricAdapter());

    await pumpGate(tester, profileCubit);
    await profileCubit.toggleBiometricLock(false);
    await tester.pump();

    expect(find.text(AppText.unlockApp), findsNothing);
    await profileCubit.close();
  });

  testWidgets('does not start duplicate authentication while it is pending', (
    tester,
  ) async {
    final adapter = BlockingBiometricAdapter();
    final profileCubit = profileFixturesWithLock();
    registerBiometricService(adapter);

    await pumpGate(tester, profileCubit);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(adapter.authenticationCalls, 1);
    adapter.complete(true);
    await tester.pumpAndSettle();
    expect(find.text(AppText.unlockApp), findsNothing);
    await profileCubit.close();
  });
}

ProfileScreenCubit profileFixturesWithLock() => profile_fixtures.createCubit(
  preferences: const ProfilePreferences(isBiometricLockEnabled: true),
);

void registerBiometricService(BiometricAdapter adapter) {
  getIt.registerSingleton<BiometricLockService>(
    BiometricLockService(adapter: adapter),
  );
}

Future<void> pumpGate(
  WidgetTester tester,
  ProfileScreenCubit profileCubit,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: profileCubit,
        child: const BiometricLockGate(
          child: Center(child: Text('Protected content')),
        ),
      ),
    ),
  );
  await tester.pump();
}

class BlockingBiometricAdapter implements BiometricAdapter {
  final _authentication = Completer<bool>();
  int authenticationCalls = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate({required String localizedReason}) {
    authenticationCalls++;
    return _authentication.future;
  }

  void complete(bool authenticated) => _authentication.complete(authenticated);
}
