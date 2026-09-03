import 'package:bdo_event/features/profile_screen/data/datasource/profile_preferences_local_data_source.dart';
import 'package:bdo_event/features/profile_screen/data/models/profile_preferences_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads defaults when shared preferences are unavailable', () {
    final source = ProfilePreferencesLocalDataSourceImpl(null);

    final preferences = source.load();

    expect(preferences.isDarkModeEnabled, isFalse);
    expect(preferences.isWatcherVibrationEnabled, isTrue);
    expect(preferences.watcherSoundVolume, 1.0);
    expect(preferences.isWatcherAutoOpenNextEnabled, isTrue);
    expect(preferences.isEventRemindersEnabled, isTrue);
    expect(preferences.eventReminderLeadTimeMinutes, 1440);
    expect(preferences.dateFormat, 'dd/MM/yyyy');
    expect(preferences.isBiometricLockEnabled, isFalse);
  });

  test('loads persisted watcher, reminder, and accessibility preferences', () async {
    SharedPreferences.setMockInitialValues({
      'dark_mode_enabled': true,
      'large_text_enabled': true,
      'high_contrast_enabled': true,
      'watcher_voice_muted': true,
      'watcher_vibration_enabled': false,
      'watcher_sound_volume': 0.35,
      'watcher_auto_open_next_enabled': false,
      'watcher_keep_history_visible_after_check_in': true,
      'event_reminders_enabled': false,
      'event_reminder_lead_time': 60,
      'date_format': 'MM/dd/yyyy',
      'biometric_lock_enabled': true,
    });
    final preferences = await SharedPreferences.getInstance();
    final source = ProfilePreferencesLocalDataSourceImpl(preferences);

    final loaded = source.load();

    expect(loaded.isDarkModeEnabled, isTrue);
    expect(loaded.isLargeTextEnabled, isTrue);
    expect(loaded.isHighContrastEnabled, isTrue);
    expect(loaded.isWatcherVoiceMuted, isTrue);
    expect(loaded.isWatcherVibrationEnabled, isFalse);
    expect(loaded.watcherSoundVolume, 0.35);
    expect(loaded.isWatcherAutoOpenNextEnabled, isFalse);
    expect(loaded.isWatcherKeepHistoryVisibleAfterCheckIn, isTrue);
    expect(loaded.isEventRemindersEnabled, isFalse);
    expect(loaded.eventReminderLeadTimeMinutes, 60);
    expect(loaded.dateFormat, 'MM/dd/yyyy');
    expect(loaded.isBiometricLockEnabled, isTrue);
  });

  test('saves every profile preference field', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final source = ProfilePreferencesLocalDataSourceImpl(preferences);

    await source.save(
      const ProfilePreferencesModel(
        isDarkModeEnabled: true,
        isLargeTextEnabled: true,
        isHighContrastEnabled: true,
        isWatcherVoiceMuted: true,
        isWatcherVibrationEnabled: false,
        watcherSoundVolume: 0.4,
        isWatcherAutoOpenNextEnabled: false,
        isWatcherKeepHistoryVisibleAfterCheckIn: true,
        isEventRemindersEnabled: false,
        eventReminderLeadTimeMinutes: 10080,
        dateFormat: 'yyyy-MM-dd',
        isBiometricLockEnabled: true,
      ),
    );

    expect(preferences.getBool('dark_mode_enabled'), isTrue);
    expect(preferences.getBool('large_text_enabled'), isTrue);
    expect(preferences.getBool('high_contrast_enabled'), isTrue);
    expect(preferences.getBool('watcher_voice_muted'), isTrue);
    expect(preferences.getBool('watcher_vibration_enabled'), isFalse);
    expect(preferences.getDouble('watcher_sound_volume'), 0.4);
    expect(preferences.getBool('watcher_auto_open_next_enabled'), isFalse);
    expect(
      preferences.getBool('watcher_keep_history_visible_after_check_in'),
      isTrue,
    );
    expect(preferences.getBool('event_reminders_enabled'), isFalse);
    expect(preferences.getInt('event_reminder_lead_time'), 10080);
    expect(preferences.getString('date_format'), 'yyyy-MM-dd');
    expect(preferences.getBool('biometric_lock_enabled'), isTrue);
  });

  test('does nothing when saving without shared preferences', () async {
    final source = ProfilePreferencesLocalDataSourceImpl(null);

    await expectLater(source.save(const ProfilePreferencesModel()), completes);
  });
}
