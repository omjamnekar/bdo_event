import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/notifications/reminders.dart';
import 'package:bdo_event/core/util/resource/app_notification.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../../shared/fixtures/local_notification_adapter.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  test('initializes through the notification adapter', () async {
    final adapter = RecordingLocalNotificationAdapter();
    final service = EventReminderNotificationService(adapter: adapter);

    await service.initialize();

    expect(adapter.initializeCalls, 1);
  });

  test('contains initialization and permission failures', () async {
    final service = EventReminderNotificationService(
      adapter: RecordingLocalNotificationAdapter(
        initializeError: StateError('initialization unavailable'),
        permissionError: StateError('permission unavailable'),
      ),
    );

    await expectLater(service.initialize(), completes);
    expect(await service.requestPermission(), isFalse);
  });

  test('schedules a future event reminder through the adapter', () async {
    final adapter = RecordingLocalNotificationAdapter();
    final service = EventReminderNotificationService(adapter: adapter);

    final scheduled = await service.scheduleEventReminder(
      _futureEvent(),
      leadTime: const Duration(days: 1),
    );

    expect(scheduled, isTrue);
    expect(adapter.scheduled, hasLength(1));
    expect(adapter.scheduled.single.title, 'Integration event');
    expect(
      adapter.scheduled.single.id,
      EventReminderNotificationService.notificationIdFor('event-1'),
    );
    expect(
      adapter.scheduled.single.payload,
      AppNotificationConfig.reminderPayload,
    );
  });

  test(
    'does not schedule when the platform or permission is unavailable',
    () async {
      final unsupported = RecordingLocalNotificationAdapter(supported: false);
      final unsupportedService = EventReminderNotificationService(
        adapter: unsupported,
      );
      expect(
        await unsupportedService.scheduleEventReminder(_futureEvent()),
        isFalse,
      );

      final denied = RecordingLocalNotificationAdapter();
      denied.permissionGranted = false;
      final deniedService = EventReminderNotificationService(adapter: denied);
      expect(
        await deniedService.scheduleEventReminder(_futureEvent()),
        isFalse,
      );
      expect(denied.scheduled, isEmpty);
    },
  );

  test('returns false when native scheduling fails', () async {
    final adapter = RecordingLocalNotificationAdapter(
      scheduleError: StateError('scheduling unavailable'),
    );
    final service = EventReminderNotificationService(adapter: adapter);

    expect(await service.scheduleEventReminder(_futureEvent()), isFalse);
    expect(adapter.scheduled, isEmpty);
  });

  test('reconciliation cancels only stale reminder payloads', () async {
    final adapter = RecordingLocalNotificationAdapter();
    adapter.pending.addAll([
      PendingNotificationRequest(
        11,
        'Reminder',
        'Old reminder',
        AppNotificationConfig.reminderPayload,
      ),
      const PendingNotificationRequest(12, 'Other', 'Other', 'other-payload'),
    ]);
    final service = EventReminderNotificationService(adapter: adapter);

    await service.reconcileEventReminders(const [], enabled: false);

    expect(adapter.canceledIds, [11]);
    expect(adapter.pending.map((request) => request.id), [12]);
  });

  test('cancels a reminder using the stable event notification ID', () async {
    final adapter = RecordingLocalNotificationAdapter();
    final service = EventReminderNotificationService(adapter: adapter);
    final id = EventReminderNotificationService.notificationIdFor('event-1');

    await service.cancelEventReminder('event-1');

    expect(adapter.canceledIds, [id]);
  });

  test('contains pending-request and cancellation failures', () async {
    final pendingFailure = EventReminderNotificationService(
      adapter: RecordingLocalNotificationAdapter(pendingError: StateError("")),
    );
    await expectLater(
      pendingFailure.reconcileEventReminders([_futureEvent()]),
      completes,
    );

    final cancelFailure = RecordingLocalNotificationAdapter(
      cancelError: StateError('cancellation unavailable'),
    );
    final service = EventReminderNotificationService(adapter: cancelFailure);
    await service.cancelEventReminder('event-1');
    await service.cancelTestNotification();
  });
}

Event _futureEvent() {
  final date = DateTime.now().add(const Duration(days: 3));
  return Event(
    id: 'event-1',
    title: 'Integration event',
    date: date.toIso8601String().substring(0, 10),
    startTime: '12:00',
    location: 'Pune',
    imageUrl: '',
  );
}
