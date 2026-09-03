import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/cubit/event_detail_cubit.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/cubit/event_detail_state.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/pages/event_detail_screen.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/widgets/bottom_event_register_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cubit/event_detail_cubit_test.dart' as fixtures;

void main() {
  testWidgets('shows available registration action', (tester) async {
    final cubit = fixtures.createCubit();
    await pumpSection(tester, cubit, event());

    expect(find.text(AppText.available), findsOneWidget);
    expect(find.text(AppText.register), findsOneWidget);
    await cubit.close();
  });

  testWidgets('shows unavailable state without an enabled action', (
    tester,
  ) async {
    final cubit = fixtures.createCubit();
    await pumpSection(tester, cubit, event(isAvailable: false));

    expect(find.text(AppText.unavailable), findsOneWidget);
    expect(find.text(AppText.registrationClosed), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await cubit.close();
  });

  testWidgets('shows full state when capacity is reached', (tester) async {
    final cubit = fixtures.createCubit();
    await pumpSection(tester, cubit, event(attendeeCount: 10, capacity: 10));

    expect(find.text(AppText.eventFull), findsOneWidget);
    expect(find.text(AppText.fullyBooked), findsOneWidget);
    await cubit.close();
  });

  testWidgets('shows closed state after the registration deadline', (
    tester,
  ) async {
    final cubit = fixtures.createCubit();
    await pumpSection(
      tester,
      cubit,
      event(registrationDeadline: DateTime(2026, 8, 29)),
    );

    expect(find.text(AppText.registrationClosed), findsNWidgets(2));
    await cubit.close();
  });

  testWidgets('shows closed state for a finished event', (tester) async {
    final cubit = fixtures.createCubit();
    await pumpSection(tester, cubit, event(date: '01/01/2020'));

    expect(find.text(AppText.registrationClosed), findsNWidgets(2));
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await cubit.close();
  });

  testWidgets('shows ticket action for registered attendees', (tester) async {
    final cubit = fixtures.createCubit();
    cubit.emit(const EventDetailState(isRegistered: true));
    await pumpSection(tester, cubit, event());

    expect(find.text(AppText.registered), findsOneWidget);
    expect(find.text(AppText.myTicket), findsOneWidget);
    await cubit.close();
  });
}

Event event({
  String date = '01/09/2026',
  String? endTime,
  bool isAvailable = true,
  int attendeeCount = 0,
  int? capacity,
  DateTime? registrationDeadline,
}) => Event(
  id: 'event-1',
  title: 'Town Hall',
  date: date,
  endTime: endTime,
  location: 'Pune',
  imageUrl: '',
  isAvailable: isAvailable,
  attendeeCount: attendeeCount,
  capacity: capacity,
  registrationDeadline: registrationDeadline,
);

Future<void> pumpSection(
  WidgetTester tester,
  EventDetailCubit cubit,
  Event event,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: BottomEventRegisterSection(
            textGrey: Colors.grey,
            primaryDark: Colors.black,
            event: event,
            widget: EventDetailPage(event: event),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
