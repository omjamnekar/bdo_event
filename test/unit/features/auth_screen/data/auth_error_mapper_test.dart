import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/auth_screen/data/auth_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('maps invalid sign-in credentials to the user-facing message', () {
    expect(
      mapAuthError(
        const AuthException('Invalid login credentials'),
        signingUp: false,
      ),
      AppText.emailOrPasswordIncorrect,
    );
    expect(
      mapAuthError(
        const AuthException('invalid credentials'),
        signingUp: false,
      ),
      AppText.emailOrPasswordIncorrect,
    );
  });

  test('maps duplicate sign-up errors to the registered-email message', () {
    for (final message in [
      'User already registered',
      'Email already exists',
      'This user already has an account',
    ]) {
      expect(
        mapAuthError(AuthException(message), signingUp: true),
        AppText.emailAlreadyRegistered,
      );
    }
  });

  test('uses operation-specific fallbacks for unknown errors', () {
    expect(
      mapAuthError(StateError('offline'), signingUp: false),
      AppText.unableToSignIn,
    );
    expect(
      mapAuthError(const AuthException('server unavailable'), signingUp: true),
      AppText.unableToCreateAccount,
    );
    expect(
      mapAuthError(
        const AuthException('invalid login credentials'),
        signingUp: true,
      ),
      AppText.emailOrPasswordIncorrect,
    );
  });
}
