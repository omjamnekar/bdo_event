import 'package:bdo_event/core/model/event_model/event_catagory.dart';
import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/util/event_date_formatter.dart';
import 'package:bdo_event/core/util/helpers/validation_email.dart';
import 'package:bdo_event/core/util/registration_code_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventCategory', () {
    test('parses names case-insensitively and supports aliases', () {
      expect(EventCategory.fromJson('sPoRtS').name, 'Sports');
      expect(EventCategory.fromJson({'name': 'food'}).name, 'Food Event');
      expect(EventCategory.fromJson({'name': 'gaming'}).name, 'Game Event');
      expect(EventCategory.fromJson('music').name, 'Music');
      expect(EventCategory.fromJson('business').name, 'Business');
    });

    test('falls back to Other for missing and unknown names', () {
      expect(EventCategory.fromJson(null).name, 'Other');
      expect(EventCategory.fromJson({'name': 'unknown'}).name, 'Other');
    });
  });

  group('Event', () {
    test('round-trips supported fields through JSON', () {
      final event = Event(
        id: 'event-1',
        title: 'Town Hall',
        date: '01/09/2026',
        startTime: '09:00',
        endTime: '17:30',
        location: 'Pune',
        locationId: 'loc-1',
        locationAddress: 'Main Street',
        latitude: 18.52,
        longitude: 73.85,
        imageUrl: 'https://example.com/event.png',
        description: 'A useful event',
        isAvailable: false,
        attendeeCount: 4,
        capacity: 10,
        registrationDeadline: DateTime.utc(2026, 8, 31, 12),
        organizerName: 'BDO',
        creatorId: 'user-1',
        createdAt: DateTime.utc(2026, 8, 1),
        catagory: EventCategory.fromJson('Business'),
      );

      final decoded = Event.fromJson(event.toJson());

      expect(decoded.id, event.id);
      expect(decoded.title, event.title);
      expect(decoded.locationAddress, event.locationAddress);
      expect(decoded.latitude, event.latitude);
      expect(decoded.attendeeCount, event.attendeeCount);
      expect(decoded.registrationDeadline, event.registrationDeadline);
      expect(decoded.catagory?.name, 'Business');
    });

    test('creates a deterministic fallback id when id is absent', () {
      final event = Event.fromJson({
        'title': 'My Event: 2026!',
        'date': '01/09/2026',
        'location': 'Pune',
      });

      expect(event.id, 'my-event-2026-');
    });

    test('copyWith replaces requested scalar fields', () {
      const event = Event(
        id: 'event-1',
        title: 'Old title',
        date: '01/09/2026',
        location: 'Pune',
        imageUrl: '',
      );

      final updated = event.copyWith(title: 'New title', capacity: 25);

      expect(updated.title, 'New title');
      expect(updated.capacity, 25);
      expect(updated.location, event.location);
    });

    test('copyWith clears nullable fields when null is provided', () {
      final event = Event(
        id: 'event-1',
        title: 'Event',
        date: '01/09/2026',
        startTime: '09:00',
        endTime: '17:00',
        location: 'Pune',
        imageUrl: '',
        capacity: 25,
        registrationDeadline: DateTime.utc(2026, 8, 31),
        organizerName: 'BDO',
        catagory: EventCategory.fromJson('Business'),
      );

      final cleared = event.copyWith(
        startTime: null,
        endTime: null,
        capacity: null,
        registrationDeadline: null,
        organizerName: null,
        catagory: null,
      );

      expect(cleared.startTime, isNull);
      expect(cleared.endTime, isNull);
      expect(cleared.capacity, isNull);
      expect(cleared.registrationDeadline, isNull);
      expect(cleared.organizerName, isNull);
      expect(cleared.catagory, isNull);
    });
  });

  group('User', () {
    final createdAt = DateTime.utc(2026, 8, 30);

    test('applies the expected permission matrix for every role', () {
      expect(
        User(
          id: 'user',
          displayName: 'User',
          email: 'user@example.com',
          createdAt: createdAt,
        ).hasPermission(UserPermission.registerForEvents),
        isTrue,
      );
      expect(
        User(
          id: 'watcher',
          displayName: 'Watcher',
          email: 'watcher@example.com',
          roles: const {UserRole.watcher},
          createdAt: createdAt,
        ).hasPermission(UserPermission.scanRegistrations),
        isTrue,
      );
      final admin = User(
        id: 'admin',
        displayName: 'Admin',
        email: 'admin@example.com',
        roles: const {UserRole.admin},
        createdAt: createdAt,
      );
      for (final permission in UserPermission.values) {
        expect(admin.hasPermission(permission), isTrue);
      }
    });

    test('parses roles and optional profile fields', () {
      final user = User.fromJson({
        'id': 'user-1',
        'displayName': 'Asha',
        'email': 'asha@example.com',
        'roles': ['watcher', 'unknown'],
        'photoUrl': 'photo.png',
        'createdAt': createdAt.toIso8601String(),
      });

      expect(user.roles, {UserRole.watcher, UserRole.user});
      expect(user.photoUrl, 'photo.png');
      expect(user.hasPermission(UserPermission.scanRegistrations), isTrue);
      expect(user.hasPermission(UserPermission.manageUsers), isFalse);
    });

    test('defaults an unknown stored role to user', () {
      expect(UserRole.fromStorage('invalid'), UserRole.user);
      expect(UserRole.fromStorage(null), UserRole.user);
    });

    test('round-trips user JSON fields', () {
      final user = User(
        id: 'user-1',
        displayName: 'Asha',
        email: 'asha@example.com',
        roles: const {UserRole.admin},
        phoneNumber: '555-0100',
        bio: 'Organizer',
        createdAt: createdAt,
        lastSignedInAt: DateTime.utc(2026, 8, 30, 9),
      );

      final decoded = User.fromJson(user.toJson());

      expect(decoded.id, user.id);
      expect(decoded.roles, {UserRole.admin});
      expect(decoded.phoneNumber, user.phoneNumber);
      expect(decoded.lastSignedInAt, user.lastSignedInAt);
      expect(decoded.isAdministrator, isTrue);
    });

    test('copyWith clears nullable profile fields when null is provided', () {
      final user = User(
        id: 'user-1',
        displayName: 'Asha',
        email: 'asha@example.com',
        photoUrl: 'photo.png',
        phoneNumber: '555-0100',
        bio: 'Organizer',
        createdAt: createdAt,
        updatedAt: createdAt,
        lastSignedInAt: createdAt,
      );

      final cleared = user.copyWith(
        photoUrl: null,
        phoneNumber: null,
        bio: null,
        updatedAt: null,
        lastSignedInAt: null,
      );

      expect(cleared.photoUrl, isNull);
      expect(cleared.phoneNumber, isNull);
      expect(cleared.bio, isNull);
      expect(cleared.updatedAt, isNull);
      expect(cleared.lastSignedInAt, isNull);
    });
  });

  group('RegistrationCodeCodec', () {
    test('round-trips event ids and tokens', () {
      const eventId = 'event-1';
      const token = 'token-abc';

      final code = RegistrationCodeCodec.encode(eventId: eventId, token: token);

      expect(RegistrationCodeCodec.decode(code), {
        'eventId': eventId,
        'token': token,
      });
    });

    test('accepts lowercase compact codes', () {
      final code = RegistrationCodeCodec.encode(eventId: 'event', token: 'token');

      expect(RegistrationCodeCodec.decode(code.toLowerCase()), {
        'eventId': 'event',
        'token': 'token',
      });
    });

    test('rejects invalid prefixes, characters, and empty payloads', () {
      expect(RegistrationCodeCodec.decode('invalid'), isNull);
      expect(RegistrationCodeCodec.decode('BDO2!'), isNull);
      expect(RegistrationCodeCodec.decode('BDO2'), isNull);
      expect(RegistrationCodeCodec.decode('BDO2A'), isNull);
    });
  });

  group('formatting and validation', () {
    test('formats slash-separated and ISO event dates', () {
      expect(formatEventDate('01/09/2026', 'dd MMM yyyy'), '01 Sep 2026');
      expect(formatEventDate('2026-09-01', 'dd MMM yyyy'), '01 Sep 2026');
      expect(formatEventDate('not-a-date', 'dd MMM yyyy'), 'not-a-date');
      expect(formatEventDate('31/02/2026', 'dd MMM yyyy'), '31/02/2026');
    });

    test('formats event times and preserves invalid values', () {
      expect(formatEventTime(null), '--:--');
      expect(formatEventTime(''), '--:--');
      expect(formatEventTime('00:00'), '12:00 AM');
      expect(formatEventTime('23:59'), '11:59 PM');
      expect(formatEventTime('24:00'), '24:00');
    });

    test('validates trimmed and malformed email values', () {
      expect(validateEmail('  user@example.com '), isNull);
      expect(validateEmail(null), isNotNull);
      expect(validateEmail('   '), isNotNull);
      expect(validateEmail('not-an-email'), isNotNull);
    });
  });
}
