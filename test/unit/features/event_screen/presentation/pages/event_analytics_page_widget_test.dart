import 'package:bdo_event/core/di/app_dependencies.dart';
import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/features/event_screen/presentation/pages/event_analytics_page.dart';
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

  testWidgets('renders checked-in analytics from the event store',
      (tester) async {
    await pumpAnalyticsPage(
      tester,
      notification_fixtures.FakeNotificationEventStore(checkedInCount: 6),
    );

    expect(find.text('Event analysis'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Capacity trajectory'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Capacity trajectory'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Attendance mix'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Attendance mix'), findsOneWidget);
    expect(find.text('6'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows an error instead of zero metrics when loading fails',
      (tester) async {
    await pumpAnalyticsPage(
      tester,
      notification_fixtures.FakeNotificationEventStore(
        checkedInError: StateError('offline'),
      ),
    );

    expect(find.text('Unable to load analytics'), findsOneWidget);
    expect(find.text('Capacity trajectory'), findsNothing);
  });
}

Future<void> pumpAnalyticsPage(
  WidgetTester tester,
  notification_fixtures.FakeNotificationEventStore store,
) async {
  getIt.registerSingleton<EventStore>(store);
  final profileCubit = profile_fixtures.createCubit();
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: profileCubit,
        child: EventAnalyticsPage(
          event: Event(
            id: 'event-1',
            title: 'Town Hall',
            date: '01/09/2099',
            location: 'Pune',
            imageUrl: '',
            attendeeCount: 8,
            capacity: 10,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await profileCubit.close();
}
