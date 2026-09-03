import 'dart:async';

import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/notification_model/notification_model.dart';
import 'package:bdo_event/core/model/user_model/event_attendee.dart';
import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/auth_screen/domain/repositories/auth_repository.dart';
import 'package:bdo_event/features/registered_screen/domain/repositories/registered_event_repository.dart';
import 'package:bdo_event/features/registered_screen/domain/usecases/cancel_registered_event.dart';
import 'package:bdo_event/features/registered_screen/presentation/cubit/registered_event_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final testUser = User(
  id: 'user-1',
  displayName: 'Asha',
  email: 'asha@example.com',
  createdAt: DateTime.utc(2026, 8, 1),
);

void main() {
  final event = Event(
    id: 'event-1',
    title: 'Town Hall',
    date: '01/09/2026',
    location: 'Pune',
    imageUrl: '',
  );

  test('loadToken returns without changing state when signed out', () async {
    final cubit = RegisteredEventCubit(
      cancelRegisteredEvent: CancelRegisteredEvent(
        FakeRegistrationRepository(),
      ),
      authRepository: FakeAuthRepository(),
      eventStore: FakeEventStore(),
      reminderNotifications: null,
    );

    await cubit.loadToken(event.id);

    expect(cubit.state.isLoadingToken, isFalse);
    expect(cubit.state.registrationToken, isNull);
    await cubit.close();
  });

  test('loadToken emits the returned token', () async {
    final store = FakeEventStore(token: 'token-1');
    final cubit = createCubit(store: store);

    await cubit.loadToken(event.id);

    expect(cubit.state.isLoadingToken, isFalse);
    expect(cubit.state.registrationToken, 'token-1');
    expect(store.tokenUserId, testUser.id);
    expect(store.tokenEventId, event.id);
    await cubit.close();
  });

  test('a latest null token clears a previous token', () async {
    final store = FakeEventStore(token: 'token-1');
    final cubit = createCubit(store: store);

    await cubit.loadToken(event.id);
    store.token = null;
    await cubit.loadToken(event.id);

    expect(cubit.state.registrationToken, isNull);
    await cubit.close();
  });

  test('loadToken maps store failures to ticket error', () async {
    final cubit = createCubit(
      store: FakeEventStore(tokenError: StateError('offline')),
    );

    await cubit.loadToken(event.id);

    expect(cubit.state.isLoadingToken, isFalse);
    expect(cubit.state.error, AppText.unableToLoadTicket);
    await cubit.close();
  });

  test('cancel emits success and clears cancelling state', () async {
    final repository = FakeRegistrationRepository();
    final cubit = createCubit(repository: repository);

    expect(await cubit.cancel(event), isTrue);
    expect(repository.cancelledEvent, event);
    expect(cubit.state.isCancelling, isFalse);
    expect(cubit.state.error, isNull);
    await cubit.close();
  });

  test('cancel maps repository errors', () async {
    final cubit = createCubit(
      repository: FakeRegistrationRepository(error: AppText.notRegistered),
    );

    expect(await cubit.cancel(event), isFalse);
    expect(cubit.state.isCancelling, isFalse);
    expect(cubit.state.error, AppText.notRegistered);
    await cubit.close();
  });

  test('ignores a second cancellation while the first is pending', () async {
    final completer = Completer<String?>();
    final repository = FakeRegistrationRepository(
      pendingResult: completer.future,
    );
    final cubit = createCubit(repository: repository);

    final first = cubit.cancel(event);
    final second = await cubit.cancel(event);

    expect(second, isFalse);
    expect(repository.cancelCalls, 1);
    completer.complete(null);
    expect(await first, isTrue);
    await cubit.close();
  });
}

RegisteredEventCubit createCubit({
  FakeEventStore? store,
  FakeRegistrationRepository? repository,
  User? authenticatedUser,
}) => RegisteredEventCubit(
  cancelRegisteredEvent: CancelRegisteredEvent(
    repository ?? FakeRegistrationRepository(),
  ),
  authRepository: FakeAuthRepository(authenticatedUser ?? testUser),
  eventStore: store ?? FakeEventStore(),
  reminderNotifications: null,
);

class FakeRegistrationRepository implements RegisteredEventRepositoryContract {
  FakeRegistrationRepository({this.error, this.pendingResult});

  final String? error;
  final Future<String?>? pendingResult;
  Event? cancelledEvent;
  int cancelCalls = 0;

  @override
  Future<String?> cancelRegistration(Event event) async {
    cancelCalls++;
    cancelledEvent = event;
    return pendingResult ?? error;
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

class FakeEventStore implements EventStore {
  FakeEventStore({this.token, this.tokenError});

  String? token;
  final Object? tokenError;
  String? tokenUserId;
  String? tokenEventId;

  @override
  Future<String?> loadRegistrationToken(String userId, String eventId) async {
    tokenUserId = userId;
    tokenEventId = eventId;
    if (tokenError != null) throw tokenError!;
    return token;
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
