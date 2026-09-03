import 'package:bdo_event/core/model/user_model/event_attendee.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/widgets/attendance_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../shared/fixtures/fake_notification_event_store.dart'
    as fixtures;
import 'attendance_profile_widget_test.dart' show pumpAttendanceProfile;

void main() {
  testWidgets('matches the registered attendee summary', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 160)
      ..devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final attendees = List.generate(
      3,
      (index) =>
          EventAttendee(userId: 'user-$index', displayName: 'User $index'),
    );
    await pumpAttendanceProfile(
      tester,
      fixtures.FakeNotificationEventStore(attendees: attendees),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AttendanceProfileWidget),
      matchesGoldenFile('goldens/attendance_profile_registered.png'),
    );
  });

  testWidgets('matches the attendee overflow summary', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 160)
      ..devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final attendees = List.generate(
      12,
      (index) =>
          EventAttendee(userId: 'user-$index', displayName: 'User $index'),
    );
    await pumpAttendanceProfile(
      tester,
      fixtures.FakeNotificationEventStore(attendees: attendees),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AttendanceProfileWidget),
      matchesGoldenFile('goldens/attendance_profile_overflow.png'),
    );
  });
}