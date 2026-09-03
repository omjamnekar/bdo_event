import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/common/form_elements/auth_button.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/auth_screen/domain/repositories/auth_repository.dart';
import 'package:bdo_event/features/auth_screen/signin_screen/presentation/cubit/signin_cubit.dart';
import 'package:bdo_event/features/auth_screen/signin_screen/presentation/pages/signin_screen.dart';
import 'package:bdo_event/features/auth_screen/signup_screen/presentation/cubit/signup_cubit.dart';
import 'package:bdo_event/features/auth_screen/signup_screen/presentation/pages/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sign-in shows validation errors and preserves initial email', (
    tester,
  ) async {
    final cubit = SignInCubit(authRepository: FakeAuthRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: SigninScreen(
            initialEmail: 'person@example.com',
            onShowSignup: () {},
            onAuthenticated: () {},
          ),
        ),
      ),
    );

    expect(find.text('person@example.com'), findsOneWidget);
    await tester.tap(find.widgetWithText(AppButton, AppText.signIn));
    await tester.pump();

    expect(find.text(AppText.validEmail), findsOneWidget);
    expect(find.text(AppText.enterPassword), findsOneWidget);
    await cubit.close();
  });

  testWidgets(
    'sign-in renders repository errors and toggles password visibility',
    (tester) async {
      final repository = FakeAuthRepository(loginResult: 'Invalid credentials');

      final cubit = SignInCubit(authRepository: repository);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cubit,
            child: SigninScreen(onShowSignup: () {}, onAuthenticated: () {}),
          ),
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).first,
        'person@example.com',
      );

      await tester.enterText(find.byType(TextFormField).last, 'secret');

      await tester.tap(find.widgetWithText(AppButton, AppText.signIn));

      await tester.pumpAndSettle();

      expect(find.text('Invalid credentials'), findsOneWidget);

      // Check password is initially hidden.
      expect(
        tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
        isTrue,
      );

      await tester.tap(find.byTooltip(AppText.showPassword));

      await tester.pump();

      // Check password is now visible.
      expect(
        tester.widget<EditableText>(find.byType(EditableText).last).obscureText,
        isFalse,
      );

      await cubit.close();
    },
  );

  testWidgets('sign-up requires valid fields and accepted terms', (
    tester,
  ) async {
    final cubit = SignUpCubit(authRepository: FakeAuthRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: SignupScreen(onShowSignin: (_) {}, onSignedUp: (_) {}),
        ),
      ),
    );

    await tester.tap(find.widgetWithText(AppButton, AppText.createAccount));
    await tester.pump();
    expect(find.text(AppText.enterFullName), findsOneWidget);
    expect(find.text(AppText.validEmail), findsOneWidget);
    expect(find.text(AppText.useAtLeastEightCharacters), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Asha');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'asha@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'password');
    await tester.enterText(find.byType(TextFormField).at(3), 'password');
    await tester.tap(find.widgetWithText(AppButton, AppText.createAccount));
    await tester.pump();

    expect(find.text(AppText.acceptTerms), findsOneWidget);
    await cubit.close();
  });
}

class FakeAuthRepository implements AuthRepositoryContract {
  FakeAuthRepository({this.loginResult});

  final String? loginResult;
  @override
  User? get currentUser => null;
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
  }) async => loginResult;
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
