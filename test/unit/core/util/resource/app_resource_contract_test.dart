import 'package:bdo_event/core/util/resource/app_database.dart';
import 'package:bdo_event/core/util/resource/app_file.dart';
import 'package:bdo_event/core/util/resource/app_identifier.dart';
import 'package:bdo_event/core/util/resource/app_model_key.dart';
import 'package:bdo_event/core/util/resource/app_notification.dart';
import 'package:bdo_event/core/util/resource/app_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes event and menu identifiers through the resource facade', () {
    expect(AppIdentifiers.qrRegistrationType, 'bdo_event_registration');
    expect(AppIdentifiers.createdEventPrefix, 'created-');
    expect(AppIdentifiers.profileMenuValue, 'profile');
    expect(AppIdentifiers.logoutMenuValue, 'logout');
  });

  test('exposes database keys used by registration persistence', () {
    expect(AppDatabase.eventsTable, 'events');
    expect(AppDatabase.eventRegistrationsTable, 'event_registrations');
    expect(AppDatabase.registrationToken, 'registration_token');
    expect(AppDatabase.activeRegistration, 'active');
    expect(AppDatabase.revokedRegistration, 'revoked');
  });

  test('exposes storage and file-format keys', () {
    expect(AppStorageKeys.displayName, 'display_name');
    expect(AppStorageKeys.notificationsEnabled, 'notifications_enabled');
    expect(AppStorageKeys.dateFormat, 'date_format');
    expect(AppFileFormats.eventImageExtension, '.jpg');
    expect(AppFileFormats.attendeeCsvExtension, '.csv');
  });

  test('exposes registration payload and notification configuration keys', () {
    expect(AppModelKeys.type, 'type');
    expect(AppModelKeys.eventId, 'eventId');
    expect(AppModelKeys.token, 'token');
    expect(AppModelKeys.checkedIn, 'checked_in');
    expect(AppNotificationConfig.reminderPayload, 'bdo_event.event_reminder');
    expect(AppNotificationConfig.reminderChannelId, 'event_reminders');
  });
}
