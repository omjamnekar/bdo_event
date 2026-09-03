import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/profile_screen/presentation/cubit/profile_screen_cubit.dart';
import 'package:bdo_event/features/profile_screen/presentation/sections/preferences_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cubit/profile_screen_cubit_test.dart' as fixtures;

void main() {
  testWidgets('renders preference controls from the supplied state', (
    tester,
  ) async {
    final cubit = fixtures.createCubit();
    await pumpPreferences(tester, cubit);

    expect(find.text(AppText.preferences), findsOneWidget);
    expect(find.text(AppText.pushNotifications), findsOneWidget);
    expect(find.text(AppText.eventReminders), findsOneWidget);
    expect(find.text(AppText.darkThemeMode), findsOneWidget);
    expect(find.text(AppText.largerText), findsOneWidget);
    expect(find.text(AppText.highContrast), findsOneWidget);
    expect(find.text('Profile visibility'), findsOneWidget);
    expect(find.text('Registration visibility'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('delegates dark-mode changes to the profile Cubit', (
    tester,
  ) async {
    final cubit = fixtures.createCubit();
    await pumpPreferences(tester, cubit);

    final darkModeTile = find.ancestor(
      of: find.text(AppText.darkThemeMode),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: darkModeTile, matching: find.byType(Switch)).first,
    );
    await tester.pump();

    expect(cubit.state.isDarkModeEnabled, isTrue);
    await cubit.close();
  });

  testWidgets('selects and persists a date format from the dialog', (
    tester,
  ) async {
    final cubit = fixtures.createCubit();
    await pumpPreferences(tester, cubit);

    await tester.tap(find.text('Date format').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('yyyy-MM-dd'));
    await tester.pump();

    expect(cubit.state.dateFormat, 'yyyy-MM-dd');
    await cubit.close();
  });

  testWidgets('selects profile visibility from the dialog', (tester) async {
    final cubit = fixtures.createCubit();
    await pumpPreferences(tester, cubit);

    await tester.tap(find.text('Profile visibility'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Everyone'));
    await tester.pump();

    expect(cubit.state.profileVisibility.label, 'Everyone');
    await cubit.close();
  });

  testWidgets('shows feedback when biometric authentication is unavailable', (
    tester,
  ) async {
    final cubit = fixtures.createCubit();
    await pumpPreferences(tester, cubit);

    final biometricTile = find.ancestor(
      of: find.text('Biometric lock'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: biometricTile, matching: find.byType(Switch)).first,
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Biometric authentication is unavailable.'),
      findsOneWidget,
    );
    expect(cubit.state.isBiometricLockEnabled, isFalse);
    await cubit.close();
  });
}

Future<void> pumpPreferences(
  WidgetTester tester,
  ProfileScreenCubit cubit,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: ProfilePreferencesSection(
            state: cubit.state,
            onReminderLeadTime: (_) {},
            onShowLanguageInfo: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
