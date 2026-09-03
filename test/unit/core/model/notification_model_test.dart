import 'package:bdo_event/core/model/notification_model/notification_model.dart';
import 'package:bdo_event/core/util/notification_count_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotification.fromJson', () {
    final baseJson = <String, dynamic>{
      'id': 7,
      'eventId': 'event-1',
      'title': 'Confirm your event arrival',
      'message': 'Please confirm your arrival.',
      'eventDate': '2026-09-01',
      'createdAt': '2026-08-30T09:00:00Z',
      'isRead': false,
    };

    test('maps attending status and scalar values', () {
      final notification = AppNotification.fromJson({
        ...baseJson,
        'arrivalStatus': 'attending',
      });

      expect(notification.id, '7');
      expect(notification.eventId, 'event-1');
      expect(notification.arrivalStatus, ArrivalStatus.attending);
      expect(notification.isRead, isFalse);
    });

    test('maps not-attending status', () {
      final notification = AppNotification.fromJson({
        ...baseJson,
        'arrivalStatus': 'not_attending',
      });

      expect(notification.arrivalStatus, ArrivalStatus.notAttending);
    });

    test('defaults missing or unknown status to pending', () {
      final missing = AppNotification.fromJson(baseJson);
      final unknown = AppNotification.fromJson({
        ...baseJson,
        'arrivalStatus': 'unexpected',
      });

      expect(missing.arrivalStatus, ArrivalStatus.pending);
      expect(unknown.arrivalStatus, ArrivalStatus.pending);
    });

    test('maps notification categories from both supported key names', () {
      final categories = <Object, NotificationCategory>{
        'registration': NotificationCategory.registration,
        'reminder': NotificationCategory.reminder,
        'invitation': NotificationCategory.invitation,
        'system': NotificationCategory.system,
      };

      for (final entry in categories.entries) {
        final notification = AppNotification.fromJson({
          ...baseJson,
          'notificationType': entry.key,
        });
        expect(notification.category, entry.value);
      }

      expect(
        AppNotification.fromJson({
          ...baseJson,
          'notification_type': 'invitation',
          'notificationType': null,
        }).category,
        NotificationCategory.invitation,
      );
      expect(
        AppNotification.fromJson({...baseJson, 'notificationType': 'other'})
            .category,
        NotificationCategory.event,
      );
    });
  });

  group('formatNotificationCount', () {
    test('hides zero and negative counts', () {
      expect(formatNotificationCount(0), isEmpty);
      expect(formatNotificationCount(-1), isEmpty);
    });

    test('shows exact counts through 99', () {
      expect(formatNotificationCount(1), '1');
      expect(formatNotificationCount(99), '99');
    });

    test('caps counts above 99', () {
      expect(formatNotificationCount(100), '99+');
      expect(formatNotificationCount(250), '99+');
    });
  });
}