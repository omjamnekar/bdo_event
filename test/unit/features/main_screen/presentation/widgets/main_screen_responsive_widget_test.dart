import 'package:bdo_event/core/common/app_keyboard_tracker/app_keyboard_tracker.dart';
import 'package:bdo_event/core/common/footer_element/element/footer_element.dart';
import 'package:bdo_event/core/di/app_dependencies.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/core/theme/app_theme.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/main_screen/domain/entities/main_tab.dart';
import 'package:bdo_event/features/main_screen/presentation/cubit/main_screen_cubit.dart';
import 'package:bdo_event/features/main_screen/presentation/widgets/main_screen_destination.dart';
import 'package:bdo_event/features/main_screen/presentation/widgets/main_screen_shell.dart';
import 'package:bdo_event/features/profile_screen/presentation/cubit/profile_screen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../shared/fixtures/fake_notification_event_store.dart';
import '../../../profile_screen/presentation/cubit/profile_screen_cubit_test.dart'
    as profile_fixtures;

void main() {
  tearDown(() async {
    AppKeyboardTracker.isKeyboardVisible.value = false;
    await getIt.reset();
  });

  testWidgets('keeps shell controls usable at narrow width with large text', (
    tester,
  ) async {
    final mainCubit = MainScreenCubit();
    final profileCubit = profile_fixtures.createCubit();
    await pumpResponsiveShell(
      tester,
      mainCubit,
      profileCubit,
      size: const Size(320, 640),
      textScaler: const TextScaler.linear(1.15),
      theme: AppTheme.light(highContrast: true),
    );

    expect(find.byTooltip(AppText.accountMenu), findsOneWidget);
    expect(find.byType(FooterElement), findsOneWidget);
    expect(tester.takeException(), isNull);

    await mainCubit.close();
    await profileCubit.close();
  });

  testWidgets('hides the footer while the keyboard is visible', (tester) async {
    final mainCubit = MainScreenCubit();
    final profileCubit = profile_fixtures.createCubit();
    await pumpResponsiveShell(
      tester,
      mainCubit,
      profileCubit,
      size: const Size(320, 640),
    );

    AppKeyboardTracker.isKeyboardVisible.value = true;
    await tester.pumpAndSettle();

    expect(find.byType(FooterElement), findsNothing);
    expect(find.byTooltip(AppText.accountMenu), findsOneWidget);
    expect(tester.takeException(), isNull);

    await mainCubit.close();
    await profileCubit.close();
  });

  testWidgets('keeps dark-theme controls available at narrow width', (
    tester,
  ) async {
    final mainCubit = MainScreenCubit();
    final profileCubit = profile_fixtures.createCubit();
    await pumpResponsiveShell(
      tester,
      mainCubit,
      profileCubit,
      size: const Size(320, 640),
      textScaler: const TextScaler.linear(1.15),
      theme: AppTheme.dark(),
    );

    expect(find.byTooltip(AppText.accountMenu), findsOneWidget);
    expect(find.byType(FooterElement), findsOneWidget);
    expect(tester.takeException(), isNull);

    await mainCubit.close();
    await profileCubit.close();
  });
}

Future<void> pumpResponsiveShell(
  WidgetTester tester,
  MainScreenCubit mainCubit,
  ProfileScreenCubit profileCubit, {
  required Size size,
  TextScaler textScaler = const TextScaler.linear(1.0),
  ThemeData? theme,
}) async {
  getIt.registerSingleton<EventStore>(FakeNotificationEventStore());
  final destinations = [
    const MainScreenDestination(
      tab: MainTab.events,
      label: AppText.event,
      icon: Icons.calendar_month,
      page: Center(child: Text('Events page')),
    ),
    const MainScreenDestination(
      tab: MainTab.registrations,
      label: AppText.register,
      icon: Icons.app_registration_rounded,
      page: Center(child: Text('Registrations page')),
    ),
    const MainScreenDestination(
      tab: MainTab.profile,
      label: AppText.profile,
      icon: Icons.account_box,
      page: Center(child: Text('Profile page')),
    ),
  ];
  await tester.pumpWidget(
    MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: SizedBox(
        width: size.width,
        height: size.height,
        child: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: mainCubit),
              BlocProvider.value(value: profileCubit),
            ],
            child: MainScreenShell(
              destinations: destinations,
              currentTab: MainTab.events,
              onLogoutSelected: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
