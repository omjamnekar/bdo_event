import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/auth_screen/domain/repositories/auth_repository.dart';
import 'package:bdo_event/features/event_detail_screen/data/datasource/registration_remote_data_source.dart';
import 'package:bdo_event/features/event_detail_screen/data/repositories/registered_event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final user = User(
    id: 'user-1',
    displayName: 'Asha',
    email: 'asha@example.com',
    createdAt: DateTime.utc(2026, 8, 1),
  );

  Event event({
    String date = '01/09/2026',
    String? endTime,
    bool isAvailable = true,
    int attendeeCount = 0,
    int? capacity,
    DateTime? registrationDeadline,
  }) => Event(
    id: 'event-1',
    title: 'Town Hall',
    date: date,
    endTime: endTime,
    location: 'Pune',
    imageUrl: '',
    isAvailable: isAvailable,
    attendeeCount: attendeeCount,
    capacity: capacity,
    registrationDeadline: registrationDeadline,
  );

  group('registerEvent', () {
    test('requires an authenticated user', () async {
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(),
      );

      expect(
        await repository.registerEvent(event()),
        AppText.pleaseSignInToRegister,
      );
      expect(dataSource.activateCalls, 0);
    });

    test('rejects an unavailable event before loading registrations', () async {
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
      );

      expect(
        await repository.registerEvent(event(isAvailable: false)),
        AppText.eventNoLongerAvailable,
      );
      expect(dataSource.loadCalls, 0);
    });

    test('rejects an event at capacity', () async {
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
      );

      expect(
        await repository.registerEvent(event(attendeeCount: 10, capacity: 10)),
        AppText.eventAtCapacity,
      );
      expect(dataSource.activateCalls, 0);
    });

    test('rejects a duplicate registration', () async {
      final dataSource = FakeRegistrationDataSource(registered: [event()]);
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
      );

      expect(
        await repository.registerEvent(event()),
        AppText.alreadyRegistered,
      );
      expect(dataSource.activateCalls, 0);
      expect(dataSource.loadCalls, 1);
    });

    test('activates a valid registration', () async {
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
      );

      expect(await repository.registerEvent(event()), isNull);
      expect(dataSource.activateCalls, 1);
      expect(dataSource.lastUserId, user.id);
      expect(dataSource.lastEvent?.id, event().id);
    });

    test('rejects a second registration after the first succeeds', () async {
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
      );

      expect(await repository.registerEvent(event()), isNull);
      expect(
        await repository.registerEvent(event()),
        AppText.alreadyRegistered,
      );
      expect(dataSource.activateCalls, 1);
    });

    test('accepts registration immediately before the deadline', () async {
      final now = DateTime(2026, 8, 30, 12);
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
        now: () => now,
      );

      expect(
        await repository.registerEvent(
          event(registrationDeadline: now.add(const Duration(minutes: 1))),
        ),
        isNull,
      );
      expect(dataSource.activateCalls, 1);
    });

    test('rejects registration at the exact deadline', () async {
      final now = DateTime(2026, 8, 30, 12);
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
        now: () => now,
      );

      expect(
        await repository.registerEvent(event(registrationDeadline: now)),
        AppText.registrationDeadlinePassed,
      );
      expect(dataSource.activateCalls, 0);
    });

    test('rejects registration after the deadline', () async {
      final now = DateTime(2026, 8, 30, 12);
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
        now: () => now,
      );

      expect(
        await repository.registerEvent(
          event(registrationDeadline: now.subtract(const Duration(minutes: 1))),
        ),
        AppText.registrationDeadlinePassed,
      );
      expect(dataSource.activateCalls, 0);
    });

    test('rejects registration after the event date', () async {
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
        now: () => DateTime(2026, 8, 31, 12),
      );

      expect(
        await repository.registerEvent(event(date: '30/08/2026')),
        AppText.eventNoLongerAvailable,
      );
      expect(dataSource.activateCalls, 0);
    });

    test('rejects registration after the event end time', () async {
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
        now: () => DateTime(2026, 8, 31, 17),
      );

      expect(
        await repository.registerEvent(
          event(date: '31/08/2026', endTime: '17:00'),
        ),
        AppText.eventNoLongerAvailable,
      );
      expect(dataSource.activateCalls, 0);
    });

    test('maps server capacity and deadline errors', () async {
      final capacitySource = FakeRegistrationDataSource(
        activationError: const LocalStorageException(
          'Event has reached its capacity',
        ),
      );
      final deadlineSource = FakeRegistrationDataSource(
        activationError: const LocalStorageException(
          'Registration for this event has closed',
        ),
      );

      final capacityRepository = RegisteredEventRepository(
        dataSource: capacitySource,
        authRepository: FakeAuthRepository(user),
      );
      final deadlineRepository = RegisteredEventRepository(
        dataSource: deadlineSource,
        authRepository: FakeAuthRepository(user),
      );

      expect(
        await capacityRepository.registerEvent(event()),
        AppText.eventAtCapacity,
      );
      expect(
        await deadlineRepository.registerEvent(event()),
        AppText.registrationDeadlinePassed,
      );
    });
  });

  group('cancelRegistration', () {
    test('requires an authenticated user', () async {
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(),
      );

      expect(
        await repository.cancelRegistration(event()),
        AppText.pleaseSignInToModifyRegistrations,
      );
    });

    test('rejects cancellation when no registration exists', () async {
      final dataSource = FakeRegistrationDataSource();
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
      );

      expect(
        await repository.cancelRegistration(event()),
        AppText.notRegistered,
      );
      expect(dataSource.revokeCalls, 0);
    });

    test('revokes an existing registration', () async {
      final dataSource = FakeRegistrationDataSource(registered: [event()]);
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
      );

      expect(await repository.cancelRegistration(event()), isNull);
      expect(dataSource.revokeCalls, 1);
      expect(dataSource.lastUserId, user.id);
      expect(dataSource.lastEventId, event().id);
    });

    test('maps cancellation storage failures', () async {
      final dataSource = FakeRegistrationDataSource(
        registered: [event()],
        revocationError: const LocalStorageException(),
      );
      final repository = RegisteredEventRepository(
        dataSource: dataSource,
        authRepository: FakeAuthRepository(user),
      );

      expect(
        await repository.cancelRegistration(event()),
        AppText.unableToCancelRegistration,
      );
    });
  });
}

class FakeRegistrationDataSource implements RegistrationDataSource {
  FakeRegistrationDataSource({
    List<Event>? registered,
    this.activationError,
    this.revocationError,
  }) : registered = [...?registered];

  final List<Event> registered;
  final Object? activationError;
  final Object? revocationError;
  int loadCalls = 0;
  int activateCalls = 0;
  int revokeCalls = 0;
  String? lastUserId;
  String? lastEventId;
  Event? lastEvent;

  @override
  Future<List<Event>> load(String userId) async {
    loadCalls++;
    return [...registered];
  }

  @override
  Future<void> activate(String userId, Event event) async {
    activateCalls++;
    lastUserId = userId;
    lastEvent = event;
    if (activationError != null) throw activationError!;
    registered.add(event);
  }

  @override
  Future<void> revoke(String userId, String eventId) async {
    revokeCalls++;
    lastUserId = userId;
    lastEventId = eventId;
    if (revocationError != null) throw revocationError!;
    registered.removeWhere((event) => event.id == eventId);
  }
}

class FakeAuthRepository implements AuthRepositoryContract {
  FakeAuthRepository([this.currentUser]);

  @override
  final User? currentUser;

  @override
  bool can(UserPermission permission) => false;

  @override
  bool canDelete(Event event) => false;

  @override
  bool canUpdate(Event event) => false;

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
