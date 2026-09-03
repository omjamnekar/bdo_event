import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/common/clipboard_share.dart';
import 'package:bdo_event/core/util/registration_code_codec.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/registered_screen/presentation/cubit/registered_event_cubit.dart';
import 'package:bdo_event/features/registered_screen/presentation/pages/registered_event_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../calendar_screen/presentation/cubit/calendar_screen_cubit_test.dart'
    as calendar_fixtures;
import '../../../event_screen/presentation/cubit/event_screen_cubit_test.dart'
    as event_fixtures;
import '../../../profile_screen/presentation/cubit/profile_screen_cubit_test.dart'
    as profile_fixtures;
import '../cubit/registered_event_cubit_test.dart' as registered_fixtures;
import '../../../../shared/fixtures/clipboard_share_adapters.dart';

void main() {
  testWidgets('shows the preparing ticket while token is unavailable', (
    tester,
  ) async {
    final cubit = registered_fixtures.createCubit();
    await pumpPage(tester, cubit);

    expect(find.text(AppText.showQrCode), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text(AppText.registrationCode), findsNothing);
    await cubit.close();
  });

  testWidgets('shows QR and manual registration code after token loads', (
    tester,
  ) async {
    final cubit = registered_fixtures.createCubit(
      store: registered_fixtures.FakeEventStore(token: 'token-1'),
    );
    await pumpPage(tester, cubit);

    expect(find.text(AppText.registrationCode), findsOneWidget);
    expect(
      find.text(
        RegistrationCodeCodec.encode(eventId: 'event-1', token: 'token-1'),
      ),
      findsOneWidget,
    );
    expect(find.byType(QrImageView), findsOneWidget);
    await cubit.close();
  });

  testWidgets('shows ticket error when token loading fails', (tester) async {
    final cubit = registered_fixtures.createCubit(
      store: registered_fixtures.FakeEventStore(
        tokenError: StateError('offline'),
      ),
    );
    await pumpPage(tester, cubit);

    expect(find.text(AppText.unableToLoadTicket), findsOneWidget);
    await cubit.close();
  });

  testWidgets('copies the manual registration code and shows confirmation', (
    tester,
  ) async {
    final clipboard = RecordingClipboardAdapter();
    final cubit = registered_fixtures.createCubit(
      store: registered_fixtures.FakeEventStore(token: 'token-1'),
    );
    await pumpPage(tester, cubit, clipboard: clipboard);

    await tester.tap(find.byTooltip(AppText.copyRegistrationCode));
    await tester.pump();

    expect(find.text(AppText.registrationCodeCopied), findsOneWidget);
    expect(
      clipboard.text,
      RegistrationCodeCodec.encode(eventId: 'event-1', token: 'token-1'),
    );
    await cubit.close();
  });

  testWidgets('contains ticket clipboard failures without confirmation', (
    tester,
  ) async {
    final clipboard = RecordingClipboardAdapter(
      error: StateError('clipboard unavailable'),
    );
    final cubit = registered_fixtures.createCubit(
      store: registered_fixtures.FakeEventStore(token: 'token-1'),
    );
    await pumpPage(tester, cubit, clipboard: clipboard);

    await tester.tap(find.byTooltip(AppText.copyRegistrationCode));
    await tester.pumpAndSettle();

    expect(find.text(AppText.registrationCodeCopied), findsNothing);
    expect(tester.takeException(), isNull);
    await cubit.close();
  });

  testWidgets('opens cancellation confirmation and keeps registration', (
    tester,
  ) async {
    final cubit = registered_fixtures.createCubit();
    await pumpPage(tester, cubit);
    final cancelButton = find.text(AppText.cancelRegistrationButton);
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.text(AppText.cancelRegistrationQuestion), findsOneWidget);
    await tester.tap(find.text(AppText.keepRegistration));
    await tester.pumpAndSettle();

    expect(find.text(AppText.cancelRegistrationQuestion), findsNothing);
    expect(cubit.state.isCancelling, isFalse);
    await cubit.close();
  });

  testWidgets('cancels registration, refreshes screens, and closes ticket', (
    tester,
  ) async {
    final registrationRepository =
        registered_fixtures.FakeRegistrationRepository();
    final registeredCubit = registered_fixtures.createCubit(
      repository: registrationRepository,
    );
    final eventCubit = event_fixtures.createCubit(
      repository: event_fixtures.FakeEventRepository(),
    );
    final calendarCubit = calendar_fixtures.createCubit();
    final profileCubit = profile_fixtures.createCubit();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: registeredCubit),
            BlocProvider.value(value: eventCubit),
            BlocProvider.value(value: calendarCubit),
            BlocProvider.value(value: profileCubit),
          ],
          child: RegisteredEventPage(event: ticketEvent),
        ),
      ),
    );
    await tester.pump();

    final cancelButton = find.text(AppText.cancelRegistrationButton);
    await tester.ensureVisible(cancelButton);
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppText.cancelEvent));
    await tester.pumpAndSettle();

    expect(registrationRepository.cancelledEvent, ticketEvent);
    expect(find.byType(RegisteredEventPage), findsNothing);
    await registeredCubit.close();
    await eventCubit.close();
    await calendarCubit.close();
    await profileCubit.close();
  });
}

final ticketEvent = Event(
  id: 'event-1',
  title: 'Town Hall',
  date: '01/09/2026',
  location: 'Pune',
  imageUrl: '',
);

Future<void> pumpPage(
  WidgetTester tester,
  RegisteredEventCubit registeredCubit, {
  ClipboardAdapter? clipboard,
}) async {
  final profileCubit = profile_fixtures.createCubit();
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: registeredCubit),
          BlocProvider.value(value: profileCubit),
        ],
        child: RegisteredEventPage(
          event: ticketEvent,
          clipboardAdapter: clipboard,
        ),
      ),
    ),
  );
  await tester.pump();
  await profileCubit.close();
}
