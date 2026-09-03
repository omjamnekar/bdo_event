import 'package:bdo_event/core/di/app_dependencies.dart';
import 'package:bdo_event/core/common/clipboard_share.dart';
import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/user_model/event_attendee.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/pages/event_attendees_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../shared/fixtures/fake_notification_event_store.dart'
    as fixtures;
import '../../../../shared/fixtures/clipboard_share_adapters.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('shows the attendee loading state', (tester) async {
    final store = fixtures.FakeNotificationEventStore(pendingAttendees: true);
    await pumpAttendeesPage(tester, store);

    expect(find.byType(ListView), findsOneWidget);
    store.completeAttendees(const []);
    await tester.pumpAndSettle();
    expect(find.text('No attendees registered yet'), findsOneWidget);
  });

  testWidgets('shows the empty attendee state', (tester) async {
    await pumpAttendeesPage(tester, fixtures.FakeNotificationEventStore());

    expect(find.text('No attendees registered yet'), findsOneWidget);
  });

  testWidgets('shows an error when attendees cannot be loaded', (tester) async {
    await pumpAttendeesPage(
      tester,
      fixtures.FakeNotificationEventStore(attendeeError: true),
    );

    expect(find.text('Unable to load attendees'), findsOneWidget);
  });

  testWidgets('renders attendees and confirms CSV copy', (tester) async {
    final clipboard = RecordingClipboardAdapter();
    final attendees = [
      const EventAttendee(userId: 'user-1', displayName: 'Asha'),
      const EventAttendee(userId: 'user-2', displayName: ''),
    ];
    await pumpAttendeesPage(
      tester,
      fixtures.FakeNotificationEventStore(attendees: attendees),
      clipboard: clipboard,
    );

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('Registered for Town Hall'), findsNWidgets(2));
    expect(find.text('?'), findsOneWidget);
    expect(find.text('Share CSV'), findsOneWidget);

    await tester.tap(find.byTooltip('Copy attendee list as CSV'));
    await tester.pump();

    expect(find.text('Attendee CSV copied'), findsOneWidget);
    expect(clipboard.text, contains('Asha'));
    expect(clipboard.text, contains('Town Hall'));
  });

  testWidgets('shares attendee CSV through the share adapter', (tester) async {
    final sharing = RecordingShareAdapter();
    final attendees = [
      const EventAttendee(userId: 'user-1', displayName: 'Asha'),
    ];
    await pumpAttendeesPage(
      tester,
      fixtures.FakeNotificationEventStore(attendees: attendees),
      share: sharing,
    );

    await tester.tap(find.text(AppText.shareCsv));
    await tester.pump();

    expect(sharing.params?.text, AppText.attendeeListFor('Town Hall'));
  });

  testWidgets('contains attendee clipboard failures without confirmation', (
    tester,
  ) async {
    final clipboard = RecordingClipboardAdapter(
      error: StateError('clipboard unavailable'),
    );
    await pumpAttendeesPage(
      tester,
      fixtures.FakeNotificationEventStore(
        attendees: const [EventAttendee(userId: 'user-1', displayName: 'Asha')],
      ),
      clipboard: clipboard,
    );

    await tester.tap(find.byTooltip(AppText.copyAttendeeListAsCsv));
    await tester.pumpAndSettle();

    expect(find.text(AppText.attendeeCsvCopied), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('contains attendee share failures', (tester) async {
    final sharing = RecordingShareAdapter(
      error: StateError('sharing unavailable'),
    );
    await pumpAttendeesPage(
      tester,
      fixtures.FakeNotificationEventStore(
        attendees: const [EventAttendee(userId: 'user-1', displayName: 'Asha')],
      ),
      share: sharing,
    );

    await tester.tap(find.text(AppText.shareCsv));
    await tester.pumpAndSettle();

    expect(sharing.params, isNull);
    expect(tester.takeException(), isNull);
  });
}

Future<void> pumpAttendeesPage(
  WidgetTester tester,
  fixtures.FakeNotificationEventStore store, {
  ClipboardAdapter? clipboard,
  ShareAdapter? share,
}) async {
  getIt.registerSingleton<EventStore>(store);
  await tester.pumpWidget(
    MaterialApp(
      home: EventAttendeesPage(
        event: Event(
          id: 'event-1',
          title: 'Town Hall',
          date: '01/09/2099',
          location: 'Pune',
          imageUrl: '',
        ),
        clipboardAdapter: clipboard,
        shareAdapter: share,
      ),
    ),
  );
  await tester.pump();
}
