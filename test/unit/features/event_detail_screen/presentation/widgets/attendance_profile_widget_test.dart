import 'package:bdo_event/core/di/app_dependencies.dart';
import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/user_model/event_attendee.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/pages/event_attendees_page.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/pages/event_detail_screen.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/widgets/attendance_profile.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/widgets/overlay_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../shared/fixtures/fake_notification_event_store.dart'
    as fixtures;

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('shows the attendance summary loading state', (tester) async {
    final store = fixtures.FakeNotificationEventStore(pendingAttendees: true);
    await pumpAttendanceProfile(tester, store);

    expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
    store.completeAttendees(const []);
    await tester.pumpAndSettle();
    expect(find.text('0 attendees'), findsOneWidget);
  });

  testWidgets('shows the registered attendee count', (tester) async {
    final attendees = List.generate(
      3,
      (index) =>
          EventAttendee(userId: 'user-$index', displayName: 'User $index'),
    );
    await pumpAttendanceProfile(
      tester,
      fixtures.FakeNotificationEventStore(attendees: attendees),
    );

    expect(find.text('3 attendees'), findsOneWidget);
    expect(find.byType(EventAttendeeAvatar), findsNWidgets(3));
  });

  testWidgets('shows a rounded overflow badge for large attendee lists', (
    tester,
  ) async {
    final attendees = List.generate(
      12,
      (index) =>
          EventAttendee(userId: 'user-$index', displayName: 'User $index'),
    );
    await pumpAttendanceProfile(
      tester,
      fixtures.FakeNotificationEventStore(attendees: attendees),
    );

    expect(find.text('12 attendees'), findsOneWidget);
    expect(find.text('10+'), findsOneWidget);
    expect(find.byType(EventAttendeeAvatar), findsNWidgets(4));
  });

  testWidgets('shows an error and retry action when attendees cannot load',
      (tester) async {
    final store = fixtures.FakeNotificationEventStore(attendeeError: true);
    await pumpAttendanceProfile(tester, store);

    await tester.pumpAndSettle();

    expect(find.text(AppText.unableToLoadAttendees), findsOneWidget);
    expect(find.byTooltip(AppText.retry), findsOneWidget);
  });

  testWidgets('does not reload attendees when the parent rebuilds',
      (tester) async {
    final store = fixtures.FakeNotificationEventStore();
    final rebuildNotifier = ValueNotifier<int>(0);
    addTearDown(rebuildNotifier.dispose);

    await pumpAttendanceProfile(
      tester,
      store,
      rebuildNotifier: rebuildNotifier,
    );
    await tester.pumpAndSettle();

    expect(store.attendeeLoadCount, 1);
    rebuildNotifier.value++;
    await tester.pumpAndSettle();
    expect(store.attendeeLoadCount, 1);
  });
}

Future<void> pumpAttendanceProfile(
  WidgetTester tester,
  fixtures.FakeNotificationEventStore store, {
  ValueNotifier<int>? rebuildNotifier,
}) async {
  getIt.registerSingleton<EventStore>(store);
  final event = Event(
    id: 'event-1',
    title: 'Town Hall',
    date: '01/09/2099',
    location: 'Pune',
    imageUrl: '',
  );
  final section = OverlayCurveSection(
    widget: EventDetailPage(event: event),
    event: event,
    textGrey: Colors.grey,
    primaryDark: Colors.black,
    mapBgColor: Colors.white,
  );
  final attendanceProfile = AttendanceProfileWidget(section: section);
  final body = rebuildNotifier == null
      ? attendanceProfile
      : ValueListenableBuilder<int>(
          valueListenable: rebuildNotifier,
          builder: (context, value, child) => attendanceProfile,
        );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: body,
      ),
    ),
  );
  await tester.pump();
}
