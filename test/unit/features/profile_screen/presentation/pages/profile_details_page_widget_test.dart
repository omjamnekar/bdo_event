import 'package:bdo_event/core/model/user_model/user_model.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/profile_screen/presentation/cubit/profile_screen_cubit.dart';
import 'package:bdo_event/features/profile_screen/presentation/pages/profile_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cubit/profile_screen_cubit_test.dart' as fixtures;

void main() {
  testWidgets('hydrates editable profile details and locale choices', (
    tester,
  ) async {
    final cubit = fixtures.createCubit(user: fixtures.testUser);
    await pumpDetails(tester, cubit, fixtures.testUser);

    expect(find.text(fixtures.testUser.displayName), findsOneWidget);
    expect(find.text(fixtures.testUser.email), findsOneWidget);
    expect(find.text(AppText.englishIndiaFull), findsOneWidget);
    expect(find.text(AppText.saveProfile), findsOneWidget);

    await tester.tap(find.text(AppText.englishIndiaFull));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppText.englishUnitedStates));
    await tester.pump();

    expect(find.text(AppText.englishUnitedStates), findsOneWidget);
  });

  testWidgets('saves profile details and closes on success', (tester) async {
    final repository = fixtures.FakeAuthRepository(user: fixtures.testUser);
    final cubit = fixtures.createCubit(authRepository: repository);
    await pumpDetails(tester, cubit, fixtures.testUser);

    await tester.enterText(find.byType(TextFormField).at(2), '555-0101');
    await tester.enterText(find.byType(TextFormField).at(3), 'Updated bio');
    await tester.tap(find.text(AppText.saveProfile));
    await tester.pumpAndSettle();

    expect(repository.updateProfileCalls, 1);
    expect(find.byType(ProfileDetailsPage), findsNothing);
    await cubit.close();
  });

  testWidgets('keeps the page open and shows an error when save fails', (
    tester,
  ) async {
    final repository = fixtures.FakeAuthRepository(
      user: fixtures.testUser,
      updateProfileResult: 'profile save failed',
    );
    final cubit = fixtures.createCubit(authRepository: repository);
    await pumpDetails(tester, cubit, fixtures.testUser);

    await tester.tap(find.text(AppText.saveProfile));
    await tester.pumpAndSettle();

    expect(find.text('profile save failed'), findsOneWidget);
    expect(find.byType(ProfileDetailsPage), findsOneWidget);
    await cubit.close();
  });

  testWidgets('removes an existing profile photo before saving', (
    tester,
  ) async {
    final user = fixtures.testUser.copyWith(photoUrl: 'photo.png');
    final cubit = fixtures.createCubit(user: user);
    await pumpDetails(tester, cubit, user);

    expect(find.text(AppText.remove), findsOneWidget);
    await tester.tap(find.text(AppText.remove));
    await tester.pump();

    expect(find.text(AppText.remove), findsNothing);
    await cubit.close();
  });
}

Future<void> pumpDetails(
  WidgetTester tester,
  ProfileScreenCubit cubit,
  User? user,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: ProfileDetailsPage(user: user),
      ),
    ),
  );
  await tester.pump();
}
