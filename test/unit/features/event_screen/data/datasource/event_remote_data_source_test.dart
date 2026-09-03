import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/notification_model/notification_model.dart';
import 'package:bdo_event/core/model/user_model/event_attendee.dart';
import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/features/event_screen/data/datasource/event_remote_data_source.dart';
import 'package:bdo_event/features/event_screen/domain/entities/event_operation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final user = User(
    id: 'user-1',
    displayName: 'Asha',
    email: 'asha@example.com',
    createdAt: DateTime.utc(2026, 8, 1),
  );

  Event event({
    String id = 'event-1',
    String imageUrl = '',
    String? creatorId,
    String? organizerName,
    DateTime? createdAt,
    int attendeeCount = 0,
  }) => Event(
    id: id,
    title: 'Town Hall',
    date: '01/09/2026',
    location: 'Pune',
    imageUrl: imageUrl,
    creatorId: creatorId,
    organizerName: organizerName,
    createdAt: createdAt,
    attendeeCount: attendeeCount,
  );

  test('loadEvents applies registration counts to created events', () async {
    final source = FakeEventStore(
      createdEvents: [
        event(),
        event(id: 'event-2'),
      ],
      registrationCounts: {'event-1': 3},
    );

    final result = await EventRemoteDataSource(source).loadEvents();

    expect(result.map((item) => item.attendeeCount), [3, 0]);
    expect(source.loadedCountIds, ['event-1', 'event-2']);
  });

  test(
    'loadEvents skips registration counts when there are no events',
    () async {
      final source = FakeEventStore();

      final result = await EventRemoteDataSource(source).loadEvents();

      expect(result, isEmpty);
      expect(source.loadedCountIds, isNull);
    },
  );

  test('create adds creator metadata and reloads events', () async {
    final source = FakeEventStore();
    final createdAt = DateTime.utc(2026, 8, 30);

    final result = await EventRemoteDataSource(source)
        .create(event(createdAt: createdAt), user);

    expect(source.createdEvent?.creatorId, user.id);
    expect(source.createdEvent?.organizerName, user.displayName);
    expect(result.error, isNull);
    expect(result.events.single.id, 'event-1');
  });

  test('maps create storage failures to an operation error', () async {
    final source = FakeEventStore(createError: const LocalStorageException());

    final result = await EventRemoteDataSource(source).create(event(), user);

    expect(result, isA<EventOperationResult>());
    expect(result.events, isEmpty);
    expect(result.error, 'Unable to save the event');
  });

  test('update preserves existing ownership and creation metadata', () async {
    final original = event(
      creatorId: 'owner-1',
      organizerName: 'Original owner',
      createdAt: DateTime.utc(2026, 8, 1),
    );
    final source = FakeEventStore(createdEvents: [original]);

    final result = await EventRemoteDataSource(source).update(
      event(
        // title: 'Updated title',
        creatorId: 'attacker-1',
        organizerName: 'Changed owner',
        createdAt: DateTime.utc(2026, 8, 30),
      ),
    );

    expect(result.error, isNull);
    // expect(source.updatedEvent?.title, 'Updated title');
    expect(source.updatedEvent?.creatorId, 'owner-1');
    expect(source.updatedEvent?.organizerName, 'Original owner');
    expect(source.updatedEvent?.createdAt, DateTime.utc(2026, 8, 1));
  });

  test('update returns an error when the event does not exist', () async {
    final source = FakeEventStore();

    final result = await EventRemoteDataSource(source).update(event());

    expect(result.events, isEmpty);
    expect(result.error, 'Event could not be found');
    expect(source.updatedEvent, isNull);
  });

  test('maps update storage failures to an operation error', () async {
    final source = FakeEventStore(
      createdEvents: [event()],
      updateError: const LocalStorageException(),
    );

    final result = await EventRemoteDataSource(source).update(event());

    expect(result.events, isEmpty);
    expect(result.error, 'Unable to update the event');
  });

  test('deletes the event and cleans up its stored image', () async {
    final source = FakeEventStore(createdEvents: [event()]);
    final deletedImages = <String>[];
    final result = await EventRemoteDataSource(
      source,
      deleteImage: (path) async => deletedImages.add(path),
    ).delete(event(imageUrl: 'user-1/event-1.jpg'));

    expect(result.error, isNull);
    expect(source.deletedEventId, 'event-1');
    expect(deletedImages, ['user-1/event-1.jpg']);
  });

  test('maps image cleanup failures to a delete operation error', () async {
    final source = FakeEventStore(createdEvents: [event()]);
    final result = await EventRemoteDataSource(
      source,
      deleteImage: (_) async => throw const LocalStorageException(),
    ).delete(event(imageUrl: 'user-1/event-1.jpg'));

    expect(result.events, isEmpty);
    expect(result.error, 'Unable to delete the event');
    expect(source.deletedEventId, 'event-1');
  });

  test(
    'maps database delete failures without attempting image cleanup',
    () async {
      final source = FakeEventStore(
        createdEvents: [event()],
        deleteError: const LocalStorageException(),
      );
      final deletedImages = <String>[];
      final result = await EventRemoteDataSource(
        source,
        deleteImage: (path) async => deletedImages.add(path),
      ).delete(event(imageUrl: 'user-1/event-1.jpg'));

      expect(result.events, isEmpty);
      expect(result.error, 'Unable to delete the event');
      expect(source.deletedEventId, isNull);
      expect(deletedImages, isEmpty);
    },
  );
}

class FakeEventStore implements EventStore {
  FakeEventStore({
    List<Event>? createdEvents,
    this.registrationCounts = const {},
    this.createError,
    this.updateError,
    this.deleteError,
  }) : createdEvents = [...?createdEvents];

  final List<Event> createdEvents;
  final Map<String, int> registrationCounts;
  final Object? createError;
  final Object? updateError;
  final Object? deleteError;
  List<String>? loadedCountIds;
  Event? createdEvent;
  Event? updatedEvent;
  String? deletedEventId;

  @override
  Future<List<Event>> readCreatedEvents() async => [...createdEvents];

  @override
  Future<Map<String, int>> loadRegistrationCounts(List<String> eventIds) async {
    loadedCountIds = [...eventIds];
    return registrationCounts;
  }

  @override
  Future<void> createEvent(Event event) async {
    if (createError != null) throw createError!;
    createdEvent = event;
    createdEvents.add(event);
  }

  @override
  Future<void> updateEvent(Event event) async {
    if (updateError != null) throw updateError!;
    updatedEvent = event;
    final index = createdEvents.indexWhere((item) => item.id == event.id);
    if (index >= 0) createdEvents[index] = event;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    if (deleteError != null) throw deleteError!;
    deletedEventId = eventId;
    createdEvents.removeWhere((event) => event.id == eventId);
  }

  @override
  Future<List<Event>> loadRegistrations(String userId) async => [];

  @override
  Future<void> activateRegistration(String userId, Event event) async {}

  @override
  Future<void> revokeRegistration(String userId, String eventId) async {}

  @override
  Future<String?> loadRegistrationToken(String userId, String eventId) async =>
      null;

  @override
  Future<Map<String, dynamic>?> validateRegistration({
    required String token,
    required String eventId,
  }) async => null;

  @override
  Future<String> checkInRegistration({
    required String token,
    required String eventId,
  }) async => 'checked_in';

  @override
  Future<int> loadAttendanceCount(String eventId) async => 0;

  @override
  Future<int> loadCheckedInCount(String eventId) async => 0;

  @override
  Future<List<EventAttendee>> loadEventAttendees(String eventId) async => [];

  @override
  Future<List<AppNotification>> loadNotifications() async => [];

  @override
  Future<int> loadUnreadNotificationCount() async => 0;

  @override
  Future<void> markNotificationRead(String notificationId) async {}

  @override
  Future<void> updateArrivalStatus({
    required String eventId,
    required ArrivalStatus status,
  }) async {}

  @override
  Future<void> recordLoginActivity({
    String? deviceLabel,
    String? platform,
  }) async {}

  @override
  Future<Map<String, String>> loadProfileVisibility(String userId) async => {};

  @override
  Future<void> saveProfileVisibility({
    required String userId,
    required String profileVisibility,
    required String registrationVisibility,
  }) async {}

  @override
  Future<List<Map<String, String>>> loadInvitationRecipients() async => [];

  @override
  Future<int> sendEventInvitations({
    required String eventId,
    required List<String> userIds,
  }) async => 0;

  @override
  Future<void> respondToEventInvitation({
    required String eventId,
    required bool accepted,
  }) async {}
}
