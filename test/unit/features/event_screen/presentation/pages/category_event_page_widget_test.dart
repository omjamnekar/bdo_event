import 'package:bdo_event/core/model/event_model/event_catagory.dart';
import 'package:bdo_event/features/event_screen/presentation/cubit/event_screen_cubit.dart';
import 'package:bdo_event/features/event_screen/presentation/pages/category_event_page.dart';
import 'package:bdo_event/features/event_screen/presentation/pages/create_event_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cubit/event_screen_cubit_test.dart' as fixtures;

void main() {
  testWidgets('renders every default event category', (tester) async {
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(),
    );
    await pumpCategories(tester, cubit);

    for (final category in EventCategory.defaults) {
      await tester.scrollUntilVisible(
        find.text(category.name),
        200,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text(category.name), findsOneWidget);
    }
    await cubit.close();
  });

  testWidgets('opens create-event form with the selected category',
      (tester) async {
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(),
    );
    await pumpCategories(tester, cubit);

    await tester.tap(find.text('Sports'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateEventPage), findsOneWidget);
    expect(find.text('Bring people together'), findsOneWidget);
    await cubit.close();
  });
}

Future<void> pumpCategories(
  WidgetTester tester,
  EventScreenCubit cubit,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: const CategoryEventPage(),
      ),
    ),
  );
  await tester.pump();
}
