import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/features/auth_screen/domain/repositories/auth_repository.dart';
import 'package:bdo_event/features/profile_screen/domain/entities/profile_preferences.dart';
import 'package:bdo_event/features/profile_screen/domain/repositories/profile_preferences_repository.dart';
import 'package:bdo_event/features/profile_screen/domain/usecases/load_profile_preferences.dart';
import 'package:bdo_event/features/profile_screen/domain/usecases/save_profile_preferences.dart';
import 'package:bdo_event/features/profile_screen/presentation/cubit/profile_screen_cubit.dart';
import 'package:bdo_event/features/profile_screen/presentation/cubit/profile_screen_state.dart';
import 'package:bdo_event/features/profile_screen/domain/entities/profile_visibility.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/core/model/notification_model/notification_model.dart';
import 'package:bdo_event/core/model/user_model/event_attendee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hydrates the profile state from user and saved preferences', () {
    final preferences = ProfilePreferences(
      isDarkModeEnabled: true,
      isLargeTextEnabled: true,
      watcherSoundVolume: 0.4,
      dateFormat: 'MM/dd/yyyy',
    );
    final cubit = createCubit(
      preferences: preferences,
      user: testUser,
    );

    expect(cubit.state.user, testUser);
    expect(cubit.state.isNotificationEnabled, isFalse);
    expect(cubit.state.isDarkModeEnabled, isTrue);
    expect(cubit.state.isLargeTextEnabled, isTrue);
    expect(cubit.state.watcherSoundVolume, 0.4);
    expect(cubit.state.dateFormat, 'MM/dd/yyyy');
    cubit.close();
  });

  test('persists display preferences and clamps watcher volume', () async {
    final store = FakePreferencesStore();
    final cubit = createCubit(preferenceStore: store);

    cubit.toggleDarkMode(true);
    cubit.toggleLargeText(true);
    cubit.toggleHighContrast(true);
    cubit.toggleWatcherVoiceMuted(true);
    cubit.toggleWatcherVibration(false);
    cubit.updateWatcherSoundVolume(2.0);
    cubit.toggleWatcherAutoOpenNext(false);
    cubit.toggleWatcherKeepHistoryVisibleAfterCheckIn(true);
    cubit.updateDateFormat('yyyy-MM-dd');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isDarkModeEnabled, isTrue);
    expect(cubit.state.isHighContrastEnabled, isTrue);
    expect(cubit.state.watcherSoundVolume, 1.0);
    expect(cubit.state.isWatcherVibrationEnabled, isFalse);
    expect(store.saved.last.dateFormat, 'yyyy-MM-dd');
    expect(store.saved.last.isWatcherKeepHistoryVisibleAfterCheckIn, isTrue);
    await cubit.close();
  });

  test('rolls visibility settings back when persistence fails', () async {
    final cubit = createCubit(
      user: testUser,
      eventStore: FakeVisibilityStore(saveError: StateError('offline')),
    );

    await cubit.updateVisibility(
      profileVisibility: ProfileVisibility.public,
      registrationVisibility: RegistrationVisibility.organizers,
    );

    expect(cubit.state.profileVisibility, ProfileVisibility.private);
    expect(cubit.state.registrationVisibility, RegistrationVisibility.private);
    expect(cubit.state.errorMessage, AppText.unableToSaveVisibility);
    await cubit.close();
  });

  test('persists valid reminder lead times and ignores invalid values', () async {
    final store = FakePreferencesStore();
    final cubit = createCubit(preferenceStore: store);

    await cubit.updateEventReminderLeadTime(60);
    final saveCount = store.saved.length;
    await cubit.updateEventReminderLeadTime(30);

    expect(cubit.state.eventReminderLeadTimeMinutes, 60);
    expect(store.saved.length, saveCount);
    await cubit.close();
  });

  test('updates event reminders and tolerates preference save failures', () async {
    final store = FakePreferencesStore(saveError: StateError('offline'));
    final cubit = createCubit(preferenceStore: store);

    await cubit.toggleEventReminders(false);

    expect(cubit.state.isEventRemindersEnabled, isFalse);
    expect(cubit.state.status, ProfileScreenStatus.ready);
    await cubit.close();
  });

  test('returns profile update errors without refreshing on failure', () async {
    final repository = FakeAuthRepository(updateProfileResult: 'invalid profile');
    final cubit = createCubit(authRepository: repository);

    final error = await cubit.updateProfile(
      displayName: 'New Name',
      email: 'new@example.com',
    );

    expect(error, 'invalid profile');
    expect(repository.updateProfileCalls, 1);
    await cubit.close();
  });

  test('forwards password changes to the auth repository', () async {
    final repository = FakeAuthRepository(passwordResult: 'weak password');
    final cubit = createCubit(authRepository: repository);

    final error = await cubit.changePassword('secret');

    expect(error, 'weak password');
    expect(repository.passwordValue, 'secret');
    await cubit.close();
  });

  test('refreshes after a successful profile update', () async {
    final repository = FakeAuthRepository(
      user: testUser,
      updateProfileResult: null,
    );
    final cubit = createCubit(authRepository: repository);

    await cubit.updateProfile(displayName: 'Asha', email: 'asha@example.com');

    expect(cubit.state.user, testUser);
    expect(cubit.state.status, ProfileScreenStatus.ready);
    await cubit.close();
  });

  test('updates notification preference on success', () async {
    final repository = FakeAuthRepository(notificationResult: null);
    final cubit = createCubit(authRepository: repository);

    await cubit.updateNotificationPreference(true);

    expect(repository.notificationValue, isTrue);
    expect(cubit.state.isNotificationEnabled, isTrue);
    expect(cubit.state.status, ProfileScreenStatus.ready);
    await cubit.close();
  });

  test('rolls notification preference back when saving fails', () async {
    final repository = FakeAuthRepository(notificationResult: 'save failed');
    final cubit = createCubit(authRepository: repository);

    await cubit.updateNotificationPreference(true);

    expect(cubit.state.isNotificationEnabled, isFalse);
    expect(cubit.state.status, ProfileScreenStatus.notificationPreferenceError);
    expect(cubit.state.errorMessage, 'save failed');
    await cubit.close();
  });

  test('does not enable biometric lock when the device service is unavailable',
      () async {
    final cubit = createCubit();

    expect(await cubit.toggleBiometricLock(true), isFalse);
    expect(cubit.state.isBiometricLockEnabled, isFalse);
    await cubit.close();
  });

  test('disables biometric lock without requiring device authentication',
      () async {
    final cubit = createCubit(
      preferences: const ProfilePreferences(isBiometricLockEnabled: true),
    );

    expect(await cubit.toggleBiometricLock(false), isTrue);
    expect(cubit.state.isBiometricLockEnabled, isFalse);
    await cubit.close();
  });

  test('loads and persists profile visibility for the signed-in user',
      () async {
    final store = FakeVisibilityStore(
      values: const {
        'profile_visibility': 'public',
        'registration_visibility': 'organizers',
      },
    );
    final cubit = createCubit(
      user: testUser,
      eventStore: store,
    );

    await cubit.loadVisibility();
    expect(cubit.state.profileVisibility, ProfileVisibility.public);
    expect(cubit.state.registrationVisibility, RegistrationVisibility.organizers);

    await cubit.updateVisibility(
      profileVisibility: ProfileVisibility.registeredUsers,
      registrationVisibility: RegistrationVisibility.public,
    );

    expect(store.loadedUserId, testUser.id);
    expect(store.savedUserId, testUser.id);
    expect(store.savedProfileVisibility, 'registered_users');
    expect(store.savedRegistrationVisibility, 'public');
    await cubit.close();
  });

  test('clearState removes the user and restores default notification state', () async {
    final cubit = createCubit(user: testUser);

    cubit.clearState();

    expect(cubit.state.user, isNull);
    expect(cubit.state.isNotificationEnabled, isTrue);
    await cubit.close();
  });
}

final testUser = User(
  id: 'user-1',
  displayName: 'Asha',
  email: 'asha@example.com',
  roles: const {UserRole.user},
  notificationsEnabled: false,
  createdAt: DateTime.utc(2026, 8, 1),
);

ProfileScreenCubit createCubit({
  FakeAuthRepository? authRepository,
  FakePreferencesStore? preferenceStore,
  ProfilePreferences? preferences,
  User? user,
  EventStore? eventStore,
}) {
  final auth = authRepository ?? FakeAuthRepository(user: user);
  final store = preferenceStore ?? FakePreferencesStore(initial: preferences);
  return ProfileScreenCubit(
    authRepository: auth,
    loadProfilePreferences: LoadProfilePreferences(store),
    saveProfilePreferences: SaveProfilePreferences(store),
    eventStore: eventStore,
  );
}

class FakePreferencesStore implements ProfilePreferencesRepositoryContract {
  FakePreferencesStore({this.initial, this.saveError});

  final ProfilePreferences? initial;
  final Object? saveError;
  final saved = <ProfilePreferences>[];

  @override
  ProfilePreferences load() => initial ?? const ProfilePreferences();

  @override
  Future<void> save(ProfilePreferences preferences) async {
    if (saveError != null) throw saveError!;
    saved.add(preferences);
  }
}

class FakeVisibilityStore implements EventStore {
  FakeVisibilityStore({this.values = const {}, this.saveError});

  final Map<String, String> values;
  final Object? saveError;
  String? loadedUserId;
  String? savedUserId;
  String? savedProfileVisibility;
  String? savedRegistrationVisibility;

  @override
  Future<Map<String, String>> loadProfileVisibility(String userId) async {
    loadedUserId = userId;
    return values;
  }

  @override
  Future<void> saveProfileVisibility({
    required String userId,
    required String profileVisibility,
    required String registrationVisibility,
  }) async {
    if (saveError != null) throw saveError!;
    savedUserId = userId;
    savedProfileVisibility = profileVisibility;
    savedRegistrationVisibility = registrationVisibility;
  }

  @override
  Future<List<Event>> readCreatedEvents() => throw UnimplementedError();
  @override
  Future<void> createEvent(Event event) => throw UnimplementedError();
  @override
  Future<void> updateEvent(Event event) => throw UnimplementedError();
  @override
  Future<void> deleteEvent(String eventId) => throw UnimplementedError();
  @override
  Future<List<Event>> loadRegistrations(String userId) => throw UnimplementedError();
  @override
  Future<Map<String, int>> loadRegistrationCounts(List<String> eventIds) => throw UnimplementedError();
  @override
  Future<void> activateRegistration(String userId, Event event) => throw UnimplementedError();
  @override
  Future<void> revokeRegistration(String userId, String eventId) => throw UnimplementedError();
  @override
  Future<String?> loadRegistrationToken(String userId, String eventId) => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> validateRegistration({required String token, required String eventId}) => throw UnimplementedError();
  @override
  Future<String> checkInRegistration({required String token, required String eventId}) => throw UnimplementedError();
  @override
  Future<int> loadAttendanceCount(String eventId) => throw UnimplementedError();
  @override
  Future<int> loadCheckedInCount(String eventId) => throw UnimplementedError();
  @override
  Future<List<EventAttendee>> loadEventAttendees(String eventId) => throw UnimplementedError();
  @override
  Future<List<AppNotification>> loadNotifications() => throw UnimplementedError();
  @override
  Future<int> loadUnreadNotificationCount() => throw UnimplementedError();
  @override
  Future<void> markNotificationRead(String notificationId) => throw UnimplementedError();
  @override
  Future<void> updateArrivalStatus({required String eventId, required ArrivalStatus status}) => throw UnimplementedError();
  @override
  Future<void> recordLoginActivity({String? deviceLabel, String? platform}) => throw UnimplementedError();
  @override
  Future<List<Map<String, String>>> loadInvitationRecipients() => throw UnimplementedError();
  @override
  Future<int> sendEventInvitations({required String eventId, required List<String> userIds}) => throw UnimplementedError();
  @override
  Future<void> respondToEventInvitation({required String eventId, required bool accepted}) => throw UnimplementedError();
}

class FakeAuthRepository implements AuthRepositoryContract {
  FakeAuthRepository({
    User? user,
    this.updateProfileResult,
    this.notificationResult,
    this.passwordResult,
  }) : currentUser = user;

  @override
  final User? currentUser;
  final String? updateProfileResult;
  final String? notificationResult;
  final String? passwordResult;
  int updateProfileCalls = 0;
  bool? notificationValue;
  String? passwordValue;

  @override
  bool can(UserPermission permission) => currentUser?.hasPermission(permission) ?? false;
  @override
  bool canDelete(Event event) => false;
  @override
  bool canUpdate(Event event) => false;
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> register({required String name, required String email, required String password, required UserRole requestedRole}) async => null;
  @override
  Future<String?> login({required String email, required String password}) async => null;
  @override
  Future<String?> updatePassword(String password) async {
    passwordValue = password;
    return passwordResult;
  }
  @override
  Future<String?> updateProfile({required String displayName, required String email, String? photoUrl, String? phoneNumber, String? bio, String? locale}) async {
    updateProfileCalls++;
    return updateProfileResult;
  }
  @override
  Future<void> logout() async {}
  @override
  Future<String?> logoutEverywhere() async => null;
  @override
  Future<String?> updateNotificationPreference(bool enable) async {
    notificationValue = enable;
    return notificationResult;
  }
}
