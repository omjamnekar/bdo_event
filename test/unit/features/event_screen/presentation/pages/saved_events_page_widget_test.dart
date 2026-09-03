import 'package:bdo_event/features/event_screen/presentation/cubit/event_screen_cubit.dart';
import 'package:bdo_event/features/event_screen/presentation/cubit/event_screen_state.dart';
import 'package:bdo_event/features/event_screen/presentation/pages/saved_events_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../profile_screen/presentation/cubit/profile_screen_cubit_test.dart'
    as profile_fixtures;
import '../cubit/event_screen_cubit_test.dart' as event_fixtures;

void main() {
  testWidgets('shows an empty state when there are no saved events',
      (tester) async {
    final eventCubit = event_fixtures.createCubit(
      repository: event_fixtures.FakeEventRepository(),
    );
    await pumpSavedEvents(tester, eventCubit);

    expect(find.text('You have not saved any events yet.'), findsOneWidget);
    await eventCubit.close();
  });

  testWidgets('shows only saved events and toggles the bookmark', (tester) async {
    final saved = event_fixtures.event('Saved Meetup', '31/12/2099');
    final unsaved = event_fixtures.event('Open Meetup', '31/12/2099');
    final eventCubit = event_fixtures.createCubit(
      repository: event_fixtures.FakeEventRepository(),
    );
    eventCubit.emit(
      EventScreenState(
        events: [saved, unsaved],
        savedEventIds: {saved.id},
        hasLoaded: true,
      ),
    );
    await pumpSavedEvents(tester, eventCubit);

    expect(find.text('Saved Meetup'), findsOneWidget);
    expect(find.text('Open Meetup'), findsNothing);
    expect(find.byTooltip('Remove saved event'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove saved event'));
    await tester.pump();

    expect(eventCubit.state.savedEventIds, isEmpty);
    expect(find.text('You have not saved any events yet.'), findsOneWidget);
    await eventCubit.close();
  });
}

Future<void> pumpSavedEvents(
  WidgetTester tester,
  EventScreenCubit eventCubit,
) async {
  final profileCubit = profile_fixtures.createCubit();
  await tester.pumpWidget(
    MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: eventCubit),
          BlocProvider.value(value: profileCubit),
        ],
        child: const SavedEventsPage(),
      ),
    ),
  );
  await tester.pump();
  await profileCubit.close();
}
