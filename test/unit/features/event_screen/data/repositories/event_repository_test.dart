import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/features/auth_screen/domain/repositories/auth_repository.dart';
import 'package:bdo_event/features/event_screen/data/datasource/event_remote_data_source.dart';
import 'package:bdo_event/features/event_screen/data/repositories/event_repository.dart';
import 'package:bdo_event/features/event_screen/domain/entities/event_operation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final owner = User(
    id: 'owner-1',
    displayName: 'Owner',
    email: 'owner@example.com',
    roles: const {UserRole.user},
    createdAt: DateTime.utc(2026, 8, 1),
  );
  final admin = User(
    id: 'admin-1',
    displayName: 'Admin',
    email: 'admin@example.com',
    roles: const {UserRole.admin},
    createdAt: DateTime.utc(2026, 8, 1),
  );
  final event = Event(
    id: 'event-1',
    title: 'Town Hall',
    date: '01/09/2026',
    location: 'Pune',
    imageUrl: '',
    creatorId: owner.id,
  );

  test('allows an administrator to create events', () async {
    final source = FakeEventDataSource();
    final repository = EventRepository(
      dataSource: source,
      authRepository: FakeAuthRepository(admin),
    );

    final result = await repository.createEvent(event, admin);

    expect(result.error, isNull);
    expect(source.createdEvent, event);
  });

  test('denies a normal user from creating events', () async {
    final source = FakeEventDataSource();
    final repository = EventRepository(
      dataSource: source,
      authRepository: FakeAuthRepository(owner, canManageOwnEvent: true),
    );

    final result = await repository.createEvent(event, owner);

    expect(result.events, isEmpty);
    expect(result.error, 'Admin access is required to create events');
    expect(source.createdEvent, isNull);
  });

  test('allows the owner to update and delete their event', () async {
    final source = FakeEventDataSource();
    final repository = EventRepository(
      dataSource: source,
      authRepository: FakeAuthRepository(owner, canManageOwnEvent: true),
    );

    expect((await repository.updateEvent(event)).error, isNull);
    expect((await repository.deleteEvent(event)).error, isNull);
    expect(source.updatedEvent, event);
    expect(source.deletedEvent, event);
  });

  test('allows an administrator to update and delete any event', () async {
    final source = FakeEventDataSource();
    final repository = EventRepository(
      dataSource: source,
      authRepository: FakeAuthRepository(admin),
    );

    expect((await repository.updateEvent(event)).error, isNull);
    expect((await repository.deleteEvent(event)).error, isNull);
  });

  test('forwards ownership and scheduling metadata during updates', () async {
    final source = FakeEventDataSource();
    final repository = EventRepository(
      dataSource: source,
      authRepository: FakeAuthRepository(owner, canManageOwnEvent: true),
    );
    final updated = event.copyWith(
      registrationDeadline: DateTime.utc(2026, 8, 31, 12),
      organizerName: 'Owner',
      locationId: 'pune-office',
      createdAt: DateTime.utc(2026, 8, 1),
    );

    expect((await repository.updateEvent(updated)).error, isNull);
    expect(source.updatedEvent?.creatorId, owner.id);
    expect(source.updatedEvent?.registrationDeadline, updated.registrationDeadline);
    expect(source.updatedEvent?.organizerName, 'Owner');
    expect(source.updatedEvent?.locationId, 'pune-office');
    expect(source.updatedEvent?.createdAt, updated.createdAt);
  });

  test('denies an unrelated user from updating or deleting an event', () async {
    final unrelated = owner.copyWith(
      displayName: 'Other user',
      email: 'other@example.com',
    );
    final source = FakeEventDataSource();
    final repository = EventRepository(
      dataSource: source,
      authRepository: FakeAuthRepository(unrelated),
    );

    expect(
      (await repository.updateEvent(event)).error,
      'You do not have permission to update this event',
    );
    expect(
      (await repository.deleteEvent(event)).error,
      'You do not have permission to delete this event',
    );
    expect(source.updatedEvent, isNull);
    expect(source.deletedEvent, isNull);
  });

  test('forwards current user, name, permissions, and event loading', () async {
    final source = FakeEventDataSource(loadedEvents: [event]);
    final repository = EventRepository(
      dataSource: source,
      authRepository: FakeAuthRepository(owner, canManageOwnEvent: true),
    );

    expect(repository.currentUser, owner);
    expect(repository.currentUserName, owner.displayName);
    expect(repository.can(UserPermission.registerForEvents), isTrue);
    expect(repository.canUpdate(event), isTrue);
    expect(await repository.loadEvents(), [event]);
  });
}

class FakeEventDataSource implements EventDataSource {
  FakeEventDataSource({List<Event>? loadedEvents})
    : loadedEvents = [...?loadedEvents];

  final List<Event> loadedEvents;
  Event? createdEvent;
  Event? updatedEvent;
  Event? deletedEvent;

  @override
  Future<List<Event>> loadEvents() async => [...loadedEvents];

  @override
  Future<EventOperationResult> create(Event event, User user) async {
    createdEvent = event;
    return EventOperationResult([event]);
  }

  @override
  Future<EventOperationResult> update(Event event) async {
    updatedEvent = event;
    return EventOperationResult([event]);
  }

  @override
  Future<EventOperationResult> delete(Event event) async {
    deletedEvent = event;
    return EventOperationResult([]);
  }
}

class FakeAuthRepository implements AuthRepositoryContract {
  FakeAuthRepository(this.currentUser, {this.canManageOwnEvent = false});

  @override
  final User currentUser;
  final bool canManageOwnEvent;

  @override
  bool can(UserPermission permission) => currentUser.hasPermission(permission);

  @override
  bool canDelete(Event event) =>
      currentUser.isAdministrator || canManageOwnEvent;

  @override
  bool canUpdate(Event event) =>
      currentUser.isAdministrator || canManageOwnEvent;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required UserRole requestedRole,
  }) async => null;

  @override
  Future<String?> login({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<String?> updatePassword(String password) async => null;

  @override
  Future<String?> updateProfile({
    required String displayName,
    required String email,
    String? photoUrl,
    String? phoneNumber,
    String? bio,
    String? locale,
  }) async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<String?> logoutEverywhere() async => null;

  @override
  Future<String?> updateNotificationPreference(bool enable) async => null;
}
