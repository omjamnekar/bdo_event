import 'dart:async';

import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/notifications/event_reminder_notification_service.dart';
import 'package:bdo_event/features/auth_screen/domain/repositories/auth_repository.dart';
import 'package:bdo_event/features/calendar_screen/domain/repositories/calendar_repository.dart';
import 'package:bdo_event/features/calendar_screen/domain/usecases/load_registered_events.dart';
import 'package:bdo_event/features/calendar_screen/presentation/cubit/calendar_screen_cubit.dart';
import 'package:bdo_event/features/calendar_screen/presentation/cubit/calendar_screen_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updateSearchQuery trims and lowercases the query', () {
    final cubit = createCubit();

    cubit.updateSearchQuery('  Pune Events  ');

    expect(cubit.state.searchQuery, 'pune events');
    cubit.close();
  });

  test('clearState returns to an empty ready state', () {
    final cubit = createCubit();
    cubit.updateSearchQuery('events');

    cubit.clearState();

    expect(cubit.state.status, CalendarScreenStatus.ready);
    expect(cubit.state.searchQuery, isEmpty);
    expect(cubit.state.events, isEmpty);
    cubit.close();
  });

  test('signed-out loading returns a ready empty state', () async {
    final cubit = createCubit(authRepository: const FakeAuthRepository(null));

    await cubit.loadRegistrations();

    expect(cubit.state.status, CalendarScreenStatus.ready);
    expect(cubit.state.events, isEmpty);
    cubit.close();
  });

  test('concurrent loads keep the latest response', () async {
    final firstResult = Completer<List<Event>>();
    final secondResult = Completer<List<Event>>();
    var loadNumber = 0;
    final repository = FakeCalendarRepository(
      loadOverride: (_) {
        loadNumber++;
        return loadNumber == 1 ? firstResult.future : secondResult.future;
      },
    );
    final cubit = createCubit(
      authRepository: FakeAuthRepository(testUser),
      repository: repository,
      reminderNotifications: null,
    );

    final firstLoad = cubit.loadRegistrations();
    final secondLoad = cubit.loadRegistrations();
    secondResult.complete([calendarEvent('latest')]);
    await secondLoad;
    firstResult.complete([calendarEvent('stale')]);
    await firstLoad;

    expect(cubit.state.events.single.id, 'latest');
    cubit.close();
  });
}

CalendarScreenCubit createCubit({
  AuthRepositoryContract? authRepository,
  CalendarRepositoryContract? repository,
  EventReminderNotificationService? reminderNotifications,
}) => CalendarScreenCubit(
  loadRegisteredEvents: LoadRegisteredEvents(
    repository ?? const FakeCalendarRepository(),
  ),
  authRepository: authRepository ?? const FakeAuthRepository(null),
  reminderNotifications: reminderNotifications,
);

class FakeCalendarRepository implements CalendarRepositoryContract {
  const FakeCalendarRepository({this.loadOverride});

  final Future<List<Event>> Function(String userId)? loadOverride;

  @override
  Future<List<Event>> loadRegisteredEvents(String userId) =>
      loadOverride?.call(userId) ?? Future.value(const []);
}

Event calendarEvent(String id) => Event(
  id: id,
  title: id,
  date: '01/01/2099',
  location: 'Pune',
  imageUrl: '',
);

final testUser = User(
  id: 'user-1',
  displayName: 'Asha',
  email: 'asha@example.com',
  createdAt: DateTime.utc(2026, 8, 1),
);

class FakeAuthRepository implements AuthRepositoryContract {
  const FakeAuthRepository(this.currentUser);

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
