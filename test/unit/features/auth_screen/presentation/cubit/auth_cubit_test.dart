import 'dart:async';

import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/auth_screen/domain/repositories/auth_repository.dart';
import 'package:bdo_event/features/auth_screen/presentation/cubit/auth_screen_cubit.dart';
import 'package:bdo_event/features/auth_screen/presentation/cubit/auth_screen_state.dart';
import 'package:bdo_event/features/auth_screen/signin_screen/presentation/cubit/signin_cubit.dart';
import 'package:bdo_event/features/auth_screen/signin_screen/presentation/cubit/signin_state.dart';
import 'package:bdo_event/features/auth_screen/signup_screen/presentation/cubit/signup_cubit.dart';
import 'package:bdo_event/features/auth_screen/signup_screen/presentation/cubit/signup_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SignInCubit', () {
    test('returns success and clears a previous error', () async {
      final repository = FakeAuthRepository(loginResult: null);
      final cubit = SignInCubit(authRepository: repository);
      cubit.showError('old error');

      final result = await cubit.submit(
        email: 'person@example.com',
        password: 'secret',
      );

      expect(result, isTrue);
      expect(cubit.state, const SignInState());
      expect(repository.loginEmail, 'person@example.com');
      await cubit.close();
    });

    test('returns repository errors and stops submitting', () async {
      final repository = FakeAuthRepository(loginResult: 'Invalid credentials');
      final cubit = SignInCubit(authRepository: repository);

      final result = await cubit.submit(
        email: 'bad@example.com',
        password: 'x',
      );

      expect(result, isFalse);
      expect(cubit.state.isSubmitting, isFalse);
      expect(cubit.state.error, 'Invalid credentials');
      await cubit.close();
    });

    test('ignores a duplicate submission while the first is pending', () async {
      final completer = Completer<String?>();
      final repository = FakeAuthRepository(loginFuture: completer.future);
      final cubit = SignInCubit(authRepository: repository);

      final first = cubit.submit(email: 'a@example.com', password: 'secret');
      final second = await cubit.submit(
        email: 'b@example.com',
        password: 'secret',
      );
      completer.complete(null);

      expect(await first, isTrue);
      expect(second, isFalse);
      expect(repository.loginCalls, 1);
      await cubit.close();
    });
  });

  group('SignUpCubit', () {
    test('forwards registration fields and requested role', () async {
      final repository = FakeAuthRepository(registerResult: null);
      final cubit = SignUpCubit(authRepository: repository);

      final result = await cubit.submit(
        name: 'Asha',
        email: 'asha@example.com',
        password: 'secret',
        requestedRole: UserRole.watcher,
      );

      expect(result, isNull);
      expect(repository.registerName, 'Asha');
      expect(repository.registerRole, UserRole.watcher);
      expect(cubit.state, const SignUpState());
      await cubit.close();
    });

    test(
      'returns duplicate-submit message while registration is pending',
      () async {
        final completer = Completer<String?>();
        final repository = FakeAuthRepository(registerFuture: completer.future);
        final cubit = SignUpCubit(authRepository: repository);

        final first = cubit.submit(
          name: 'Asha',
          email: 'asha@example.com',
          password: 'secret',
          requestedRole: UserRole.user,
        );
        final second = await cubit.submit(
          name: 'Other',
          email: 'other@example.com',
          password: 'secret',
          requestedRole: UserRole.user,
        );
        completer.complete(null);

        expect(await first, isNull);
        expect(second, AppText.pleaseWait);
        expect(repository.registerCalls, 1);
        await cubit.close();
      },
    );
  });

  group('AuthScreenCubit', () {
    test(
      'selects authenticated step when initialization restores a user',
      () async {
        final cubit = AuthScreenCubit(
          authRepository: FakeAuthRepository(currentUser: testUser),
        );

        await cubit.checkActiveSession();

        expect(cubit.state.step, AuthStep.authenticated);
        await cubit.close();
      },
    );

    test('falls back to sign-in when initialization fails', () async {
      final cubit = AuthScreenCubit(
        authRepository: FakeAuthRepository(
          initializeError: StateError('offline'),
        ),
      );

      await cubit.checkActiveSession();

      expect(cubit.state.step, AuthStep.signIn);
      await cubit.close();
    });

    test(
      'supports sign-up, pre-filled sign-in, logout, and logout-everywhere',
      () async {
        final repository = FakeAuthRepository(logoutEverywhereResult: null);
        final cubit = AuthScreenCubit(authRepository: repository);

        cubit.showSignUp();
        expect(cubit.state.step, AuthStep.signUp);
        cubit.showSignIn('person@example.com');
        expect(cubit.state.preFilledEmail, 'person@example.com');
        cubit.authenticationSucceeded();
        expect(cubit.state.step, AuthStep.authenticated);
        await cubit.logout();
        expect(cubit.state.step, AuthStep.signIn);
        cubit.authenticationSucceeded();
        expect(await cubit.logoutEverywhere(), isNull);
        expect(cubit.state.step, AuthStep.signIn);
        await cubit.close();
      },
    );
  });
}

final testUser = User(
  id: 'user-1',
  displayName: 'Asha',
  email: 'asha@example.com',
  roles: const {UserRole.user},
  createdAt: DateTime.utc(2026, 8, 1),
);

class FakeAuthRepository implements AuthRepositoryContract {
  FakeAuthRepository({
    this.currentUser,
    this.loginResult,
    this.loginFuture,
    this.registerResult,
    this.registerFuture,
    this.initializeError,
    this.logoutEverywhereResult,
  });

  @override
  final User? currentUser;
  final String? loginResult;
  final Future<String?>? loginFuture;
  final String? registerResult;
  final Future<String?>? registerFuture;
  final Object? initializeError;
  final String? logoutEverywhereResult;
  int loginCalls = 0;
  int registerCalls = 0;
  String? loginEmail;
  String? registerName;
  UserRole? registerRole;

  @override
  bool can(UserPermission permission) =>
      currentUser?.hasPermission(permission) ?? false;
  @override
  bool canDelete(Event event) => false;
  @override
  bool canUpdate(Event event) => false;
  @override
  Future<void> initialize() async {
    if (initializeError != null) throw initializeError!;
  }

  @override
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required UserRole requestedRole,
  }) {
    registerCalls++;
    registerName = name;
    registerRole = requestedRole;
    return registerFuture ?? Future.value(registerResult);
  }

  @override
  Future<String?> login({required String email, required String password}) {
    loginCalls++;
    loginEmail = email;
    return loginFuture ?? Future.value(loginResult);
  }

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
  Future<String?> logoutEverywhere() async => logoutEverywhereResult;
  @override
  Future<String?> updateNotificationPreference(bool enable) async => null;
}
