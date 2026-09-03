import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/profile_screen/presentation/sections/account_section.dart';
import 'package:bdo_event/features/profile_screen/presentation/sections/organizer_tools_section.dart';
import 'package:bdo_event/features/profile_screen/presentation/sections/support_section.dart';
import 'package:bdo_event/features/profile_screen/presentation/sections/watcher_settings_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cubit/profile_screen_cubit_test.dart' as fixtures;

void main() {
  testWidgets('renders watcher settings and delegates control changes', (
    tester,
  ) async {
    final cubit = fixtures.createCubit();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: ProfileWatcherSettingsSection(state: cubit.state),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Watcher settings'), findsOneWidget);
    expect(find.text('Mute scanning voice'), findsOneWidget);
    expect(find.text('Scan vibration'), findsOneWidget);
    expect(find.text('Scanner sound volume'), findsOneWidget);
    expect(find.text('Auto-open next attendee'), findsOneWidget);
    expect(find.text('Keep history visible after check-in'), findsOneWidget);

    final muteTile = find.ancestor(
      of: find.text('Mute scanning voice'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: muteTile, matching: find.byType(Switch)).first,
    );
    await tester.pump();
    expect(cubit.state.isWatcherVoiceMuted, isTrue);

    await tester.drag(find.byType(Slider), const Offset(80, 0));
    await tester.pump();
    expect(cubit.state.watcherSoundVolume, greaterThan(0.9));
    await cubit.close();
  });

  testWidgets('shows organizer tools only for users with organizer roles', (
    tester,
  ) async {
    final admin = User(
      id: 'admin-1',
      displayName: 'Admin',
      email: 'admin@example.com',
      roles: const {UserRole.admin},
      createdAt: DateTime.utc(2026, 8, 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfileOrganizerToolsSection(user: admin)),
      ),
    );
    await tester.pump();

    expect(find.text('Organizer tools'), findsOneWidget);
    expect(find.text('Create event'), findsOneWidget);
    expect(find.text('Manage my events'), findsOneWidget);
    expect(find.text('Scan registration'), findsOneWidget);

    final regularUser = User(
      id: 'user-1',
      displayName: 'User',
      email: 'user@example.com',
      createdAt: DateTime.utc(2026, 8, 1),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProfileOrganizerToolsSection(user: regularUser)),
      ),
    );
    await tester.pump();

    expect(find.text('Scan registration'), findsNothing);
    expect(find.text('Create event'), findsOneWidget);
  });

  testWidgets('wires account actions to their callbacks', (tester) async {
    var editCalls = 0;
    var passwordCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileAccountSection(
            onEditProfile: () => editCalls++,
            onChangePassword: () => passwordCalls++,
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppText.editProfile));
    await tester.tap(find.text(AppText.changePassword));

    expect(editCalls, 1);
    expect(passwordCalls, 1);
  });

  testWidgets('wires support information and sign-out actions', (tester) async {
    String? infoTitle;
    String? infoMessage;
    var signOutCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileSupportSection(
            onShowInfo: ({required title, required message}) {
              infoTitle = title;
              infoMessage = message;
            },
            onSignOutEverywhere: () => signOutCalls++,
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppText.helpCenterFaq));
    await tester.tap(find.text(AppText.signOutEverywhere));

    expect(infoTitle, AppText.helpCenterFaq);
    expect(infoMessage, AppText.eventHelp);
    expect(signOutCalls, 1);
  });
}
