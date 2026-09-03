import 'package:bdo_event/core/di/app_dependencies.dart';
import 'package:bdo_event/core/model/notification_model/notification_model.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/notification_screen/presentation/pages/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../shared/fixtures/fake_notification_event_store.dart';
import '../../../profile_screen/presentation/cubit/profile_screen_cubit_test.dart'
    as profile_fixtures;

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('shows the empty notification state', (tester) async {
    final store = FakeNotificationEventStore();
    await pumpNotifications(tester, store);

    expect(find.text('No notifications'), findsOneWidget);
  });

  testWidgets('shows the notification loading state', (tester) async {
    final store = FakeNotificationEventStore(pendingNotifications: true);
    await pumpNotifications(tester, store);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    store.completeNotifications(const []);
    await tester.pumpAndSettle();
    expect(find.text('No notifications'), findsOneWidget);
  });

  testWidgets('renders an arrival notification and marks it read', (
    tester,
  ) async {
    final notification = sampleNotification();
    final store = FakeNotificationEventStore(notifications: [notification]);
    await pumpNotifications(tester, store);
    await tester.pump();

    expect(find.text('Event reminder'), findsOneWidget);
    expect(find.text('Would you like to attend?'), findsOneWidget);
    expect(find.text(AppText.attending), findsOneWidget);
    expect(store.markedReadId, notification.id);
  });

  testWidgets('renders invitation actions and sends an accept response', (
    tester,
  ) async {
    final notification = sampleNotification(
      category: NotificationCategory.invitation,
    );
    final store = FakeNotificationEventStore(notifications: [notification]);
    await pumpNotifications(tester, store);

    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(store.respondedEventId, notification.eventId);
    expect(store.respondedAccepted, isTrue);
  });

  testWidgets('shows an error when notifications cannot be loaded', (
    tester,
  ) async {
    await pumpNotifications(
      tester,
      FakeNotificationEventStore(notificationError: true),
    );

    expect(find.text(AppText.unableToLoadNotifications), findsOneWidget);
  });

  testWidgets('confirms attendance and shows success feedback', (tester) async {
    final store = FakeNotificationEventStore(
      notifications: [sampleNotification()],
    );
    await pumpNotifications(tester, store);

    await tester.tap(find.text(AppText.attending));
    await tester.pumpAndSettle();

    expect(store.arrivalEventId, 'event-1');
    expect(store.arrivalStatus, ArrivalStatus.attending);
    expect(find.text(AppText.arrivalConfirmed), findsOneWidget);
  });

  testWidgets('shows feedback when attendance confirmation fails', (
    tester,
  ) async {
    final store = FakeNotificationEventStore(
      notifications: [sampleNotification()],
      arrivalError: true,
    );
    await pumpNotifications(tester, store);

    await tester.tap(find.text(AppText.notAttending));
    await tester.pumpAndSettle();

    expect(find.text(AppText.unableToUpdateArrival), findsOneWidget);
  });
}

AppNotification sampleNotification({
  NotificationCategory category = NotificationCategory.event,
  ArrivalStatus arrivalStatus = ArrivalStatus.pending,
}) => AppNotification(
  id: 'notification-1',
  eventId: 'event-1',
  title: 'Event reminder',
  message: 'Town Hall starts soon',
  eventDate: DateTime.utc(2099, 9, 1),
  createdAt: DateTime.utc(2099, 8, 1),
  isRead: false,
  arrivalStatus: arrivalStatus,
  category: category,
);

Future<void> pumpNotifications(
  WidgetTester tester,
  FakeNotificationEventStore store,
) async {
  getIt.registerSingleton<EventStore>(store);
  final profileCubit = profile_fixtures.createCubit();
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: profileCubit,
        child: const NotificationScreen(),
      ),
    ),
  );
  await tester.pump();
  await profileCubit.close();
}
