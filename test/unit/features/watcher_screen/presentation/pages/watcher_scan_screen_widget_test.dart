import 'dart:convert';

import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/util/resource/app_identifier.dart';
import 'package:bdo_event/core/util/resource/app_locals.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/profile_screen/presentation/cubit/profile_screen_cubit.dart';
import 'package:bdo_event/features/watcher_screen/data/datasource/watcher_remote_data_source.dart';
import 'package:bdo_event/features/watcher_screen/data/repositories/watcher_repository.dart';
import 'package:bdo_event/features/watcher_screen/domain/usecases/check_in_registration.dart';
import 'package:bdo_event/features/watcher_screen/domain/usecases/load_scan_dashboard.dart';
import 'package:bdo_event/features/watcher_screen/domain/usecases/validate_registration.dart';
import 'package:bdo_event/features/watcher_screen/presentation/adapters.dart';
import 'package:bdo_event/features/watcher_screen/presentation/cubit/watcher_scan_cubit.dart';
import 'package:bdo_event/features/watcher_screen/presentation/pages/watcher_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../profile_screen/presentation/cubit/profile_screen_cubit_test.dart'
    as profile_fixtures;
import '../../../../shared/fixtures/fake_notification_event_store.dart';
import '../../../../shared/fixtures/watcher_native_adapters.dart';

void main() {
  testWidgets('routes scanner callbacks and native controls through adapters', (
    tester,
  ) async {
    final scanner = RecordingScannerAdapter();
    final voice = RecordingVoiceAdapter();
    final feedback = RecordingFeedbackAdapter();
    final store = FakeWatcherStore(
      validationResult: {
        'event_id': 'event-1',
        'user_id': 'user-1',
        'display_name': 'Asha',
      },
    );
    final watcherCubit = createWatcherCubit(store);
    final profileCubit = profile_fixtures.createCubit();
    await pumpScreen(
      tester,
      watcherCubit,
      profileCubit,
      scanner,
      voice,
      feedback,
    );

    expect(voice.languages, [AppLocales.englishIndia]);
    scanner.detect(
      jsonEncode({
        'type': AppIdentifiers.qrRegistrationType,
        'eventId': 'event-1',
        'token': 'token-1',
      }),
    );
    scanner.detect('ignored-during-cooldown');
    await tester.pump(const Duration(milliseconds: 1600));

    expect(store.validationCalls, 1);
    expect(find.text(AppText.registrationValid), findsOneWidget);
    expect(voice.spoken, contains(AppText.registrationValid));
    expect(feedback.mediumImpactCalls, 1);

    profileCubit.updateWatcherSoundVolume(0.4);
    await tester.pump();
    expect(voice.volumes, [0.4]);

    final spokenCount = voice.spoken.length;
    profileCubit.toggleWatcherVoiceMuted(true);
    watcherCubit.reset();
    await tester.pump();
    scanner.detect('invalid-registration-code');
    await tester.pumpAndSettle();
    expect(voice.spoken, hasLength(spokenCount));

    await tester.tap(find.byTooltip(AppText.toggleFlashLight));
    await tester.tap(find.byTooltip(AppText.switchCamera));
    expect(scanner.toggleTorchCalls, 1);
    expect(scanner.switchCameraCalls, 1);

    await watcherCubit.close();
    await profileCubit.close();
  });

  testWidgets('contains native adapter failures and completes teardown', (
    tester,
  ) async {
    final scanner = RecordingScannerAdapter(
      toggleTorchError: StateError('torch unavailable'),
      switchCameraError: StateError('camera unavailable'),
      disposeError: StateError('dispose unavailable'),
    );
    final voice = RecordingVoiceAdapter(
      configureError: StateError('speech unavailable'),
      setVolumeError: StateError('volume unavailable'),
      speakError: StateError('speak unavailable'),
    );
    final feedback = RecordingFeedbackAdapter(
      error: StateError('haptics unavailable'),
    );
    final store = FakeWatcherStore(
      validationResult: {'event_id': 'event-1', 'user_id': 'user-1'},
    );
    final watcherCubit = createWatcherCubit(store);
    final profileCubit = profile_fixtures.createCubit();
    await pumpScreen(
      tester,
      watcherCubit,
      profileCubit,
      scanner,
      voice,
      feedback,
    );

    profileCubit.updateWatcherSoundVolume(0.4);
    await tester.pump();
    scanner.detect(
      jsonEncode({
        'type': AppIdentifiers.qrRegistrationType,
        'eventId': 'event-1',
        'token': 'token-1',
      }),
    );
    await tester.pump(const Duration(milliseconds: 1600));

    expect(find.text(AppText.registrationValid), findsOneWidget);
    await tester.tap(find.byTooltip(AppText.toggleFlashLight));
    await tester.tap(find.byTooltip(AppText.switchCamera));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(voice.disposeCalls, 1);
    expect(tester.takeException(), isNull);
    await watcherCubit.close();
    await profileCubit.close();
  });

  testWidgets('disposes scanner and voice adapters with the screen', (
    tester,
  ) async {
    final scanner = RecordingScannerAdapter();
    final voice = RecordingVoiceAdapter();
    final feedback = RecordingFeedbackAdapter();
    final watcherCubit = createWatcherCubit(FakeWatcherStore());
    final profileCubit = profile_fixtures.createCubit();
    await pumpScreen(
      tester,
      watcherCubit,
      profileCubit,
      scanner,
      voice,
      feedback,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(scanner.disposeCalls, 1);
    expect(voice.disposeCalls, 1);
    await watcherCubit.close();
    await profileCubit.close();
  });
}

Future<void> pumpScreen(
  WidgetTester tester,
  WatcherScanCubit watcherCubit,
  ProfileScreenCubit profileCubit,
  WatcherScannerAdapter scanner,
  WatcherVoiceAdapter voice,
  WatcherFeedbackAdapter feedback,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: watcherCubit),
          BlocProvider.value(value: profileCubit),
        ],
        child: WatcherScanScreen(
          scanner: scanner,
          voice: voice,
          feedback: feedback,
        ),
      ),
    ),
  );
  await tester.pump();
}

WatcherScanCubit createWatcherCubit(FakeWatcherStore store) {
  final repository = WatcherRepository(WatcherRemoteDataSourceImpl(store));
  return WatcherScanCubit(
    validateRegistration: ValidateRegistration(repository),
    checkInRegistration: CheckInRegistration(repository),
    loadScanDashboard: LoadScanDashboard(repository),
    authRepository: profile_fixtures.FakeAuthRepository(
      user: User(
        id: 'watcher-1',
        displayName: 'Watcher',
        email: 'watcher@example.com',
        roles: const {UserRole.watcher},
        createdAt: DateTime(2026, 1, 1),
      ),
    ),
  );
}

class FakeWatcherStore extends FakeNotificationEventStore {
  FakeWatcherStore({this.validationResult});

  final Map<String, dynamic>? validationResult;
  int validationCalls = 0;

  @override
  Future<Map<String, dynamic>?> validateRegistration({
    required String token,
    required String eventId,
  }) async {
    validationCalls++;
    return validationResult;
  }

  @override
  Future<int> loadAttendanceCount(String eventId) async => 1;

  @override
  Future<int> loadCheckedInCount(String eventId) async => 0;
}
