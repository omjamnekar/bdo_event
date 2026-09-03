import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/auth_screen/domain/repositories/auth_repository.dart';
import 'package:bdo_event/features/calendar_screen/domain/repositories/calendar_repository.dart';
import 'package:bdo_event/features/calendar_screen/domain/usecases/load_registered_events.dart';
import 'package:bdo_event/features/event_screen/domain/entities/event_operation_result.dart';
import 'package:bdo_event/features/event_screen/domain/repositories/event_repository.dart';
import 'package:bdo_event/features/event_screen/domain/usecases/event_use_cases.dart';
import 'package:bdo_event/features/event_screen/presentation/cubit/event_screen_cubit.dart';
import 'package:bdo_event/features/event_screen/presentation/cubit/event_screen_state.dart';
import 'package:bdo_event/core/prefs/recent_event_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';

void main() {
  final pastEvent = event('past', '01/01/2020');
  final futureEvent = event('future', '01/01/2099');

  test('load populates events, registered IDs, and saved IDs', () async {
    SharedPreferences.setMockInitialValues({
      'saved_event_ids': ['saved'],
    });
    final repository = FakeEventRepository(events: [pastEvent, futureEvent]);
    final cubit = createCubit(
      repository: repository,
      registeredEvents: [futureEvent],
      preferences: await SharedPreferences.getInstance(),
    );

    await cubit.load();

    expect(cubit.state.hasLoaded, isTrue);
    expect(cubit.state.events, [pastEvent, futureEvent]);
    expect(cubit.state.registeredEventIds, {'future'});
    expect(cubit.state.savedEventIds, {'saved'});
    await cubit.close();
  });

  test('duplicate load calls are ignored while loading', () async {
    final repository = FakeEventRepository(events: [futureEvent]);
    final cubit = createCubit(repository: repository);

    final first = cubit.load();
    final second = cubit.load();
    await Future.wait([first, second]);

    expect(repository.loadCalls, 1);
    await cubit.close();
  });

  test(
    'forced loads keep the latest response when they finish out of order',
    () async {
      final firstResult = Completer<List<Event>>();
      final secondResult = Completer<List<Event>>();
      var loadNumber = 0;
      final repository = FakeEventRepository(
        loadEventsOverride: () {
          loadNumber++;
          return loadNumber == 1 ? firstResult.future : secondResult.future;
        },
      );
      final cubit = createCubit(repository: repository);

      final firstLoad = cubit.load(force: true);
      final secondLoad = cubit.load(force: true);
      secondResult.complete([pastEvent]);
      await secondLoad;
      firstResult.complete([futureEvent]);
      await firstLoad;

      expect(cubit.state.events, [pastEvent]);
      await cubit.close();
    },
  );

  test(
    'currentTabEvents separates upcoming, registered, and past events',
    () async {
      final state = EventScreenState(
        events: [pastEvent, futureEvent],
        registeredEventIds: {'future'},
      );

      expect(state.currentTabEvents, isEmpty);
      expect(state.copyWith(selectedTab: 1).currentTabEvents, [futureEvent]);
      expect(state.copyWith(selectedTab: 2).currentTabEvents, [pastEvent]);
    },
  );

  test('currentTabEvents moves an event to past after its end time', () {
    final now = DateTime.now();
    final today = '${now.day}/${now.month}/${now.year}';
    final state = EventScreenState(
      events: [
        Event(
          id: 'ended-today',
          title: 'Ended today',
          date: today,
          endTime: '00:00',
          location: 'Pune',
          imageUrl: '',
        ),
      ],
    );

    expect(state.currentTabEvents, isEmpty);
    expect(state.copyWith(selectedTab: 2).currentTabEvents, hasLength(1));
  });

  test('delete rolls back the event when the repository fails', () async {
    final repository = FakeEventRepository(
      events: [futureEvent],
      deleteResult: const EventOperationResult([], 'delete failed'),
    );
    final cubit = createCubit(repository: repository);
    await cubit.load();

    final error = await cubit.delete(futureEvent);

    expect(error, 'delete failed');
    expect(cubit.state.events, [futureEvent]);
    expect(cubit.state.deletingEventIds, isEmpty);
    await cubit.close();
  });

  test(
    'save maps create and edit operation errors and clears saving state',
    () async {
      final repository = FakeEventRepository(
        saveResult: const EventOperationResult([], 'save failed'),
      );
      final cubit = createCubit(repository: repository);

      expect(await cubit.save(futureEvent, isEditing: false), 'save failed');
      expect(cubit.state.isSaving, isFalse);
      expect(cubit.state.error, 'save failed');

      expect(await cubit.save(futureEvent, isEditing: true), 'save failed');
      expect(cubit.state.isSaving, isFalse);
      expect(cubit.state.error, 'save failed');
      await cubit.close();
    },
  );

  test('save requires an authenticated user', () async {
    final cubit = createCubit(
      repository: FakeEventRepository(),
      authRepository: const FakeAuthRepository(null),
    );

    expect(
      await cubit.save(futureEvent, isEditing: false),
      AppText.pleaseSignInToManageEvents,
    );
    expect(cubit.state.isSaving, isFalse);
    await cubit.close();
  });

  test('closed Cubit rejects save without invoking the repository', () async {
    final repository = FakeEventRepository();
    final cubit = createCubit(repository: repository);
    await cubit.close();

    expect(
      await cubit.save(futureEvent, isEditing: false),
      AppText.unableToSaveEvent,
    );
    expect(repository.createCalls, 0);
  });

  test('toggleSavedEvent persists add and remove operations', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cubit = createCubit(
      preferences: preferences,
      repository: FakeEventRepository(),
    );

    cubit.toggleSavedEvent(futureEvent);
    expect(cubit.state.savedEventIds, {'future'});
    expect(preferences.getStringList('saved_event_ids'), ['future']);

    cubit.toggleSavedEvent(futureEvent);
    expect(cubit.state.savedEventIds, isEmpty);
    expect(preferences.getStringList('saved_event_ids'), isEmpty);
    await cubit.close();
  });
}

Event event(String id, String date) =>
    Event(id: id, title: id, date: date, location: 'Pune', imageUrl: '');

EventScreenCubit createCubit({
  required FakeEventRepository repository,
  List<Event> registeredEvents = const [],
  SharedPreferences? preferences,
  AuthRepositoryContract? authRepository,
  RecentEventStore? recentEventStore,
}) => EventScreenCubit(
  loadEvents: LoadEvents(repository),
  loadRegisteredEvents: LoadRegisteredEvents(
    FakeCalendarRepository(registeredEvents),
  ),
  createEvent: CreateEvent(repository),
  updateEvent: UpdateEvent(repository),
  deleteEvent: DeleteEvent(repository),
  authRepository: authRepository ?? FakeAuthRepository(testUser),
  preferences: preferences,
  recentEventStore: recentEventStore,
);

class FakeEventRepository implements EventRepositoryContract {
  FakeEventRepository({
    this.events = const [],
    this.deleteResult,
    this.saveResult,
    this.loadEventsOverride,
  });

  final List<Event> events;
  final EventOperationResult? deleteResult;
  final EventOperationResult? saveResult;
  final Future<List<Event>> Function()? loadEventsOverride;
  int loadCalls = 0;
  int createCalls = 0;
  int updateCalls = 0;

  @override
  Future<List<Event>> loadEvents() async {
    loadCalls++;
    if (loadEventsOverride != null) return loadEventsOverride!();
    return events;
  }

  @override
  Future<EventOperationResult> createEvent(Event event, User user) async =>
      _save(event, editing: false);

  @override
  Future<EventOperationResult> updateEvent(Event event) async =>
      _save(event, editing: true);

  @override
  Future<EventOperationResult> deleteEvent(Event event) async =>
      deleteResult ?? const EventOperationResult([]);

  Future<EventOperationResult> _save(
    Event event, {
    required bool editing,
  }) async {
    if (editing) {
      updateCalls++;
    } else {
      createCalls++;
    }
    return saveResult ?? EventOperationResult([event]);
  }
}

final testUser = User(
  id: 'user-1',
  displayName: 'Asha',
  email: 'asha@example.com',
  createdAt: DateTime.utc(2026, 8, 1),
);

class FakeCalendarRepository implements CalendarRepositoryContract {
  const FakeCalendarRepository(this.events);

  final List<Event> events;

  @override
  Future<List<Event>> loadRegisteredEvents(String userId) async => events;
}

class FakeAuthRepository implements AuthRepositoryContract {
  const FakeAuthRepository(this.currentUser);

  @override
  final User? currentUser;

  @override
  bool can(UserPermission permission) =>
      currentUser?.hasPermission(permission) ?? false;
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
