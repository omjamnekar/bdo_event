import 'dart:async';

import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/notification_model/notification_model.dart';
import 'package:bdo_event/core/model/user_model/event_attendee.dart';
import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/auth_screen/domain/repositories/auth_repository.dart';
import 'package:bdo_event/features/event_detail_screen/domain/repositories/registration_repository.dart';
import 'package:bdo_event/features/event_detail_screen/domain/usecases/registration_use_cases.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/cubit/event_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final event = Event(
    id: 'event-1',
    title: 'Town Hall',
    date: '01/09/2026',
    location: 'Pune',
    imageUrl: '',
    creatorId: testOwner.id,
  );

  test('checkRegistration updates the registered state', () async {
    final cubit = createCubit(registered: true);

    await cubit.checkRegistration(event);

    expect(cubit.state.isRegistered, isTrue);
    await cubit.close();
  });

  test('register and cancel update registration state on success', () async {
    final repository = FakeRegistrationRepository();
    final cubit = createCubit(repository: repository);

    expect(await cubit.register(event), isNull);
    expect(cubit.state.isRegistered, isTrue);
    expect(await cubit.cancel(event), isNull);
    expect(cubit.state.isRegistered, isFalse);
    expect(repository.registerCalls, 1);
    expect(repository.cancelCalls, 1);
    await cubit.close();
  });

  test(
    'registration errors clear submitting state and preserve status',
    () async {
      final cubit = createCubit(
        repository: FakeRegistrationRepository(error: AppText.eventAtCapacity),
      );

      expect(await cubit.register(event), AppText.eventAtCapacity);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.isRegistered, isFalse);
      expect(cubit.state.error, AppText.eventAtCapacity);
      await cubit.close();
    },
  );

  test('duplicate submissions return update-in-progress', () async {
    final completer = Completer<String?>();
    final repository = FakeRegistrationRepository(
      pendingResult: completer.future,
    );
    final cubit = createCubit(repository: repository);

    final first = cubit.register(event);
    final second = await cubit.register(event);

    expect(second, AppText.updateInProgress);
    expect(repository.registerCalls, 1);
    completer.complete(null);
    expect(await first, isNull);
    await cubit.close();
  });

  test('only an authorized event owner loads attendance', () async {
    final store = FakeEventStore(attendanceCount: 7);
    final cubit = createCubit(store: store);

    await cubit.loadAttendanceCount(event);

    expect(cubit.state.attendanceCount, 7);
    expect(store.attendanceCalls, 1);
    await cubit.close();
  });

  test('an unauthorized user cannot load attendance', () async {
    final store = FakeEventStore(attendanceCount: 7);
    final cubit = createCubit(
      store: store,
      authRepository: FakeAuthRepository(
        User(
          id: 'other-user',
          displayName: 'Other',
          email: 'other@example.com',
          roles: const {UserRole.admin},
          createdAt: DateTime.utc(2026, 8, 1),
        ),
      ),
    );

    await cubit.loadAttendanceCount(event);

    expect(cubit.state.attendanceCount, isNull);
    expect(store.attendanceCalls, 0);
    await cubit.close();
  });

  test('latest attendance response wins', () async {
    final first = Completer<int>();
    final second = Completer<int>();
    final store = FakeEventStore(
      attendanceResults: {'event-1': first.future, 'event-2': second.future},
    );
    final cubit = createCubit(store: store);
    final secondEvent = event.copyWith(id: 'event-2');

    final firstLoad = cubit.loadAttendanceCount(event);
    final secondLoad = cubit.loadAttendanceCount(secondEvent);
    second.complete(2);
    first.complete(1);
    await Future.wait([firstLoad, secondLoad]);

    expect(cubit.state.attendanceCount, 2);
    await cubit.close();
  });
}

EventDetailCubit createCubit({
  FakeRegistrationRepository? repository,
  FakeEventStore? store,
  AuthRepositoryContract? authRepository,
  bool registered = false,
}) {
  final resolvedRepository =
      repository ?? FakeRegistrationRepository(registered: registered);
  return EventDetailCubit(
    registerForEvent: RegisterForEvent(resolvedRepository),
    cancelEventRegistration: CancelEventRegistration(resolvedRepository),
    eventStore: store ?? FakeEventStore(),
    authRepository: authRepository ?? FakeAuthRepository(testOwner),
  );
}

final testOwner = User(
  id: 'owner-1',
  displayName: 'Owner',
  email: 'owner@example.com',
  roles: const {UserRole.admin},
  createdAt: DateTime.utc(2026, 8, 1),
);

class FakeRegistrationRepository implements RegistrationRepositoryContract {
  FakeRegistrationRepository({
    this.registered = false,
    this.error,
    this.pendingResult,
  });

  bool registered;
  Future<String?>? pendingResult;
  String? error;
  int registerCalls = 0;
  int cancelCalls = 0;

  @override
  Future<bool> isUserRegistered(String eventId) async => registered;

  @override
  Future<String?> registerEvent(Event event) async {
    registerCalls++;

    final result = await pendingResult ?? error;

    if (result == null) {
      registered = true;
    }

    return result;
  }

  @override
  Future<String?> cancelRegistration(Event event) async {
    cancelCalls++;
    if (error == null) registered = false;
    return error;
  }
}

class FakeAuthRepository implements AuthRepositoryContract {
  const FakeAuthRepository(this.currentUser);

  @override
  final User currentUser;
  @override
  bool can(UserPermission permission) => currentUser.hasPermission(permission);
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

class FakeEventStore implements EventStore {
  FakeEventStore({this.attendanceCount = 0, this.attendanceResults = const {}});

  final int attendanceCount;
  final Map<String, Future<int>> attendanceResults;
  int attendanceCalls = 0;

  @override
  Future<int> loadAttendanceCount(String eventId) async {
    attendanceCalls++;
    return attendanceResults[eventId] ?? attendanceCount;
  }

  @override
  Future<List<Event>> readCreatedEvents() async => [];
  @override
  Future<void> createEvent(Event event) async {}
  @override
  Future<void> updateEvent(Event event) async {}
  @override
  Future<void> deleteEvent(String eventId) async {}
  @override
  Future<List<Event>> loadRegistrations(String userId) async => [];
  @override
  Future<Map<String, int>> loadRegistrationCounts(
    List<String> eventIds,
  ) async => {};
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
