import 'package:bdo_event/core/di/app_dependencies.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/features/main_screen/domain/entities/main_tab.dart';
import 'package:bdo_event/features/main_screen/presentation/cubit/main_screen_cubit.dart';
import 'package:bdo_event/features/main_screen/presentation/widgets/main_screen_destination.dart';
import 'package:bdo_event/features/main_screen/presentation/widgets/main_screen_shell.dart';
import 'package:bdo_event/features/profile_screen/presentation/cubit/profile_screen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../shared/fixtures/fake_notification_event_store.dart'
    as notification_fixtures;
import '../../../profile_screen/presentation/cubit/profile_screen_cubit_test.dart'
    as profile_fixtures;

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('renders the selected destination and handles footer tabs',
      (tester) async {
    final mainCubit = MainScreenCubit();
    final profileCubit = profile_fixtures.createCubit();
    await pumpShell(tester, mainCubit, profileCubit, MainTab.events);

    expect(find.text('Events page'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.app_registration_rounded));
    await tester.pump();

    expect(mainCubit.state.currentTab, MainTab.registrations);
    await mainCubit.close();
    await profileCubit.close();
  });

  testWidgets('routes profile and logout actions from the header menu',
      (tester) async {
    final mainCubit = MainScreenCubit();
    final profileCubit = profile_fixtures.createCubit();
    var profileCalls = 0;
    var logoutCalls = 0;
    await pumpShell(
      tester,
      mainCubit,
      profileCubit,
      MainTab.profile,
      onProfileSelected: () => profileCalls++,
      onLogoutSelected: () => logoutCalls++,
    );

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(profileCalls, 1);

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pump();
    expect(logoutCalls, 1);

    await mainCubit.close();
    await profileCubit.close();
  });

  testWidgets('builds only active destinations and caches them', (tester) async {
    final mainCubit = MainScreenCubit();
    final profileCubit = profile_fixtures.createCubit();
    var eventBuilds = 0;
    var registrationBuilds = 0;
    final destinations = [
      MainScreenDestination(
        tab: MainTab.events,
        label: 'Event',
        icon: Icons.calendar_month,
        pageBuilder: () {
          eventBuilds++;
          return const Center(child: Text('Events page'));
        },
      ),
      MainScreenDestination(
        tab: MainTab.registrations,
        label: 'Register',
        icon: Icons.app_registration_rounded,
        pageBuilder: () {
          registrationBuilds++;
          return const Center(child: Text('Registrations page'));
        },
      ),
    ];

    await pumpShell(
      tester,
      mainCubit,
      profileCubit,
      MainTab.events,
      destinations: destinations,
    );
    expect(eventBuilds, 1);
    expect(registrationBuilds, 0);

    await tester.tap(find.byIcon(Icons.app_registration_rounded));
    await tester.pump();
    expect(eventBuilds, 1);
    expect(registrationBuilds, 1);

    await mainCubit.close();
    await profileCubit.close();
  });
}

Future<void> pumpShell(
  WidgetTester tester,
  MainScreenCubit mainCubit,
  ProfileScreenCubit profileCubit,
  MainTab currentTab, {
  VoidCallback? onProfileSelected,
  VoidCallback? onLogoutSelected,
  List<MainScreenDestination>? destinations,
}) async {
  getIt.registerSingleton<EventStore>(
    notification_fixtures.FakeNotificationEventStore(),
  );
  final defaultDestinations = [
    const MainScreenDestination(
      tab: MainTab.events,
      label: 'Event',
      icon: Icons.calendar_month,
      page: Center(child: Text('Events page')),
    ),
    const MainScreenDestination(
      tab: MainTab.registrations,
      label: 'Register',
      icon: Icons.app_registration_rounded,
      page: Center(child: Text('Registrations page')),
    ),
    const MainScreenDestination(
      tab: MainTab.profile,
      label: 'Profile',
      icon: Icons.account_box,
      page: Center(child: Text('Profile page')),
    ),
  ];
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: mainCubit),
          BlocProvider.value(value: profileCubit),
        ],
        child: MainScreenShell(
          destinations: destinations ?? defaultDestinations,
          currentTab: currentTab,
          onLogoutSelected: onLogoutSelected ?? () {},
        ),
      ),
    ),
  );
  await tester.pump();
}
