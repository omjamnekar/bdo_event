import 'package:bdo_event/core/prefs/recent_event_store.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/event_screen/presentation/cubit/event_screen_cubit.dart';
import 'package:bdo_event/features/event_screen/presentation/pages/event_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cubit/event_screen_cubit_test.dart' as fixtures;

void main() {
  testWidgets('shows the empty state when no upcoming events exist', (
    tester,
  ) async {
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(),
    );
    await pumpPage(tester, cubit);

    expect(find.text('A quiet moment'), findsOneWidget);
    expect(
      find.text(
        'Upcoming Events will appear here when there is something to explore.',
      ),
      findsOneWidget,
    );
    await cubit.close();
  });

  testWidgets('shows an event card after loading events', (tester) async {
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(
        events: [fixtures.event('Community Meetup', '31/12/2099')],
      ),
    );
    await pumpPage(tester, cubit);

    expect(find.text('Community Meetup'), findsOneWidget);
    expect(find.text('A quiet moment'), findsNothing);
    await cubit.close();
  });

  testWidgets('filters cards when switching to My Events and Past Events', (
    tester,
  ) async {
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(
        events: [
          fixtures.event('Upcoming Open', '31/12/2099'),
          fixtures.event('Past Gathering', '01/01/2020'),
        ],
      ),
      registeredEvents: [fixtures.event('Upcoming Registered', '31/12/2099')],
    );
    await pumpPage(tester, cubit);

    expect(find.text('Upcoming Open'), findsOneWidget);
    expect(find.text('Upcoming Registered'), findsNothing);
    await tester.tap(find.text('My Events'));
    await tester.pump();
    expect(find.text('Upcoming Registered'), findsOneWidget);
    expect(find.text('Upcoming Open'), findsNothing);

    await tester.tap(find.text('Past'));
    await tester.pump();
    expect(find.text('Past Gathering'), findsOneWidget);
    expect(find.text('Upcoming Registered'), findsNothing);
    await cubit.close();
  });

  testWidgets('does not show finished events in recently viewed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'recent_event_ids_user-1': ['past'],
    });
    final preferences = await SharedPreferences.getInstance();
    final pastEvent = fixtures.event('past', '01/01/2020');
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(events: [pastEvent]),
      preferences: preferences,
      recentEventStore: RecentEventStore(preferences),
    );

    await pumpPage(tester, cubit);

    expect(find.text(AppText.recentlyViewed), findsNothing);
    expect(find.text('past'), findsNothing);
    await cubit.close();
  });
}

Future<void> pumpPage(WidgetTester tester, EventScreenCubit cubit) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(value: cubit, child: const EventPage()),
    ),
  );
  await tester.pumpAndSettle();
}
