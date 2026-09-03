import 'package:bdo_event/features/calendar_screen/presentation/cubit/calendar_screen_cubit.dart';
import 'package:bdo_event/features/calendar_screen/presentation/cubit/calendar_screen_state.dart';
import 'package:bdo_event/features/calendar_screen/presentation/pages/calendar_screen.dart';
import 'package:bdo_event/features/event_screen/presentation/cubit/event_screen_cubit.dart';
import 'package:bdo_event/features/main_screen/domain/entities/main_tab.dart';
import 'package:bdo_event/features/main_screen/presentation/cubit/main_screen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cubit/calendar_screen_cubit_test.dart' as calendar_fixtures;
import '../../../event_screen/presentation/cubit/event_screen_cubit_test.dart'
  as event_fixtures;
import '../../../profile_screen/presentation/cubit/profile_screen_cubit_test.dart'
  as profile_fixtures;

void main() {
  testWidgets('shows the empty calendar prompt and explores events',
      (tester) async {
    final calendarCubit = calendar_fixtures.createCubit();
    final eventCubit = event_fixtures.createCubit(
      repository: event_fixtures.FakeEventRepository(),
    );
    final mainCubit = MainScreenCubit();
    await pumpPage(tester, calendarCubit, eventCubit, mainCubit);

    expect(find.text('Your calendar is ready'), findsOneWidget);
    expect(find.text('Explore events'), findsOneWidget);
    await tester.tap(find.text('Explore events'));
    await tester.pump();
    expect(mainCubit.state.currentTab, MainTab.events);

    await closeCubits(calendarCubit, eventCubit, mainCubit);
  });

  testWidgets('shows registered events in the calendar list', (tester) async {
    final calendarCubit = calendar_fixtures.createCubit();
    calendarCubit.emit(CalendarScreenState(
      events: [event_fixtures.event('Town Hall', '31/12/2099')],
      status: CalendarScreenStatus.ready,
    ));
    final eventCubit = event_fixtures.createCubit(
      repository: event_fixtures.FakeEventRepository(),
    );
    final mainCubit = MainScreenCubit();
    await pumpPage(tester, calendarCubit, eventCubit, mainCubit);

    expect(find.text('Town Hall'), findsOneWidget);
    expect(find.text('Your calendar is ready'), findsNothing);

    await closeCubits(calendarCubit, eventCubit, mainCubit);
  });

  testWidgets('shows no-match state for a search with no results', (tester) async {
    final calendarCubit = calendar_fixtures.createCubit();
    calendarCubit.emit(CalendarScreenState(
      events: [event_fixtures.event('Town Hall', '31/12/2099')],
      status: CalendarScreenStatus.ready,
    ));
    final eventCubit = event_fixtures.createCubit(
      repository: event_fixtures.FakeEventRepository(),
    );
    final mainCubit = MainScreenCubit();
    await pumpPage(tester, calendarCubit, eventCubit, mainCubit);

    await tester.enterText(find.byType(TextField), 'concert');
    await tester.pump();

    expect(find.text('No events found'), findsOneWidget);
    expect(find.text('Town Hall'), findsNothing);
    await closeCubits(calendarCubit, eventCubit, mainCubit);
  });
}

Future<void> pumpPage(
  WidgetTester tester,
  CalendarScreenCubit calendarCubit,
  EventScreenCubit eventCubit,
  MainScreenCubit mainCubit,
) async {
  final profileCubit = profile_fixtures.createCubit();
  addTearDown(profileCubit.close);
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: calendarCubit),
          BlocProvider.value(value: eventCubit),
          BlocProvider.value(value: mainCubit),
          BlocProvider.value(value: profileCubit),
        ],
        child: const CalendarScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> closeCubits(
  CalendarScreenCubit calendarCubit,
  EventScreenCubit eventCubit,
  MainScreenCubit mainCubit,
) async {
  await calendarCubit.close();
  await eventCubit.close();
  await mainCubit.close();
}

