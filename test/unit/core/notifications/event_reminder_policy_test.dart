import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/notifications/event_reminder_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseEvent = Event(
    id: 'event-1',
    title: 'Town Hall',
    date: '2026-09-01',
    location: 'Pune',
    imageUrl: '',
    startTime: '09:30',
  );

  group('eventStartTime', () {
    test('combines an ISO date and valid start time', () {
      expect(
        EventReminderPolicy.eventStartTime(baseEvent),
        DateTime(2026, 9, 1, 9, 30),
      );
    });

    test('accepts a one-digit hour', () {
      expect(
        EventReminderPolicy.eventStartTime(baseEvent.copyWith(startTime: '9:05')),
        DateTime(2026, 9, 1, 9, 5),
      );
    });

    test('accepts a slash-formatted date produced by event creation', () {
      expect(
        EventReminderPolicy.eventStartTime(
          baseEvent.copyWith(date: '01/09/2026'),
        ),
        DateTime(2026, 9, 1, 9, 30),
      );
    });

    test('returns null for incomplete or invalid scheduling data', () {
      expect(EventReminderPolicy.eventStartTime(baseEvent.copyWith(startTime: '')), isNull);
      expect(EventReminderPolicy.eventStartTime(baseEvent.copyWith(startTime: '9')), isNull);
      expect(EventReminderPolicy.eventStartTime(baseEvent.copyWith(startTime: '24:00')), isNull);
      expect(EventReminderPolicy.eventStartTime(baseEvent.copyWith(startTime: '09:60')), isNull);
      expect(
        EventReminderPolicy.eventStartTime(baseEvent.copyWith(date: '31/02/2026')),
        isNull,
      );
    });
  });

  group('reminderTime', () {
    test('subtracts the selected lead time from the event start', () {
      expect(
        EventReminderPolicy.reminderTime(
          baseEvent,
          leadTime: const Duration(hours: 2),
        ),
        DateTime(2026, 9, 1, 7, 30),
      );
    });

    test('returns null when the event start cannot be parsed', () {
      expect(
        EventReminderPolicy.reminderTime(
          baseEvent.copyWith(startTime: 'unknown'),
        ),
        isNull,
      );
    });
  });

  test('creates stable non-negative notification ids', () {
    final first = EventReminderPolicy.notificationIdFor('event-1');
    final second = EventReminderPolicy.notificationIdFor('event-1');

    expect(first, greaterThanOrEqualTo(0));
    expect(first, second);
    expect(first, isNot(EventReminderPolicy.notificationIdFor('event-2')));
  });
}
