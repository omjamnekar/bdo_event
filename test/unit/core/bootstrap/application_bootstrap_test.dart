import 'package:bdo_event/core/bootstrap/application_bootstrap.dart';
import 'package:bdo_event/dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'short-circuits when environment configuration is unavailable',
    () async {
      final calls = <String>[];
      final bootstrap = ApplicationBootstrap(
        loadEnvironment: () async {
          calls.add('environment');
          return null;
        },
        initializeSupabase: ({required url, required publishableKey}) async {
          calls.add('supabase');
        },
        loadPreferences: () async {
          calls.add('preferences');
          return SharedPreferences.getInstance();
        },
      );

      expect(await bootstrap.initialize(), isFalse);
      expect(calls, ['environment']);
    },
  );

  test('runs configured startup steps in production order', () async {
    SharedPreferences.setMockInitialValues(const {});
    final calls = <String>[];
    final bootstrap = ApplicationBootstrap(
      loadEnvironment: () async {
        calls.add('environment');
        return DotEnvInitialization.fromValues(
          url: 'https://example.supabase.co',
          anonKey: 'anon-key',
        );
      },
      initializeSupabase: ({required url, required publishableKey}) async {
        calls.add('supabase:$url:$publishableKey');
      },
      loadPreferences: () async {
        calls.add('preferences');
        return SharedPreferences.getInstance();
      },
      configureDependenciesIN: ({preferences}) {
        calls.add('dependencies:${preferences != null}');
      },

      initializeNotifications: () async => calls.add('notifications'),
      restoreSession: () async => calls.add('session'),
      refreshProfile: () => calls.add('profile'),
      loadRegistrations: () async => calls.add('registrations'),
      finishLoading: () => calls.add('finish'),
    );

    expect(await bootstrap.initialize(), isTrue);
    expect(calls, [
      'environment',
      'supabase:https://example.supabase.co:anon-key',
      'preferences',
      'dependencies:true',
      'notifications',
      'session',
      'profile',
      'registrations',
      'finish',
    ]);
  });
}
