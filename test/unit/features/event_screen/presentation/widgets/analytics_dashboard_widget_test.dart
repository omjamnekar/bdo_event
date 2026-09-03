import 'dart:ui' as ui;

import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/features/event_screen/presentation/widgets/analytics_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';

import '../../../profile_screen/presentation/cubit/profile_screen_cubit_test.dart'
    as profile_fixtures;

void main() {
  testWidgets('renders unlimited-capacity analytics with zero attendance',
      (tester) async {
    await pumpDashboard(
      tester,
      event: analyticsEvent(attendeeCount: 0),
      checkedIn: 0,
      width: 400,
    );

    expect(find.text('Registered'), findsOneWidget);
    expect(find.text('0'), findsAtLeastNWidgets(3));
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Attendance mix'), findsOneWidget);
    expect(find.byType(CustomPaint), findsNWidgets(2));
  });

  testWidgets('clamps over-capacity metrics and checked-in conversion',
      (tester) async {
    await pumpDashboard(
      tester,
      event: analyticsEvent(attendeeCount: 12, capacity: 10),
      checkedIn: 20,
      width: 400,
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('100% conversion'), findsOneWidget);
    expect(find.text('0'), findsAtLeastNWidgets(1));
    expect(find.text('120% filled'), findsNothing);
  });

  testWidgets('renders exact capacity as fully filled with no remaining seats',
      (tester) async {
    await pumpDashboard(
      tester,
      event: analyticsEvent(attendeeCount: 10, capacity: 10),
      checkedIn: 5,
      width: 400,
    );

    expect(find.text('10'), findsNWidgets(2));
    expect(find.text('100% filled'), findsOneWidget);
    expect(find.text('0'), findsAtLeastNWidgets(1));
  });

  testWidgets('shows a loading placeholder for checked-in analytics',
      (tester) async {
    await pumpDashboard(
      tester,
      event: analyticsEvent(attendeeCount: 8, capacity: 20),
      checkedIn: 0,
      width: 400,
      isLoadingCheckIns: true,
    );

    expect(find.text('--'), findsOneWidget);
    expect(find.text('0% conversion'), findsOneWidget);
  });

  testWidgets('rebuilds chart values when the event attendance changes',
      (tester) async {
    final profileCubit = profile_fixtures.createCubit();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 900,
          child: BlocProvider.value(
            value: profileCubit,
            child: AnalyticsDashboard(
              event: analyticsEvent(attendeeCount: 2, capacity: 10),
              checkedIn: 1,
              isLoadingCheckIns: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final firstPainter = tester
        .renderObject<RenderCustomPaint>(find.byType(CustomPaint).first)
        .painter;

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 900,
          child: BlocProvider.value(
            value: profileCubit,
            child: AnalyticsDashboard(
              event: analyticsEvent(attendeeCount: 9, capacity: 10),
              checkedIn: 1,
              isLoadingCheckIns: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final secondPainter = tester
        .renderObject<RenderCustomPaint>(find.byType(CustomPaint).first)
        .painter;

    expect(firstPainter, isNot(same(secondPainter)));
    await profileCubit.close();
  });

  testWidgets('paints visible chart and donut pixels', (tester) async {
    final profileCubit = profile_fixtures.createCubit();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          child: SizedBox(
            width: 400,
            height: 900,
            child: BlocProvider.value(
              value: profileCubit,
              child: AnalyticsDashboard(
                event: analyticsEvent(attendeeCount: 8, capacity: 20),
                checkedIn: 4,
                isLoadingCheckIns: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pixels = byteData!.buffer.asUint8List();

    expect(pixels.any((pixel) => pixel != 0), isTrue);
    image.dispose();
    await profileCubit.close();
  });

  testWidgets('uses the wide dashboard layout at the breakpoint',
      (tester) async {
    await pumpDashboard(
      tester,
      event: analyticsEvent(attendeeCount: 4, capacity: 20),
      checkedIn: 2,
      width: 820,
    );

    expect(find.text('Capacity trajectory'), findsOneWidget);
    expect(find.text('Attendance mix'), findsOneWidget);
    expect(find.byType(Row), findsWidgets);
  });
}

Event analyticsEvent({required int attendeeCount, int? capacity}) => Event(
  id: 'analytics-event',
  title: 'Community Town Hall',
  date: '01/09/2099',
  location: 'Pune',
  imageUrl: '',
  attendeeCount: attendeeCount,
  capacity: capacity,
);

Future<void> pumpDashboard(
  WidgetTester tester, {
  required Event event,
  required int checkedIn,
  required double width,
  bool isLoadingCheckIns = false,
}) async {
  final profileCubit = profile_fixtures.createCubit();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: width,
        height: 900,
        child: MultiBlocProvider(
          providers: [BlocProvider.value(value: profileCubit)],
          child: AnalyticsDashboard(
            event: event,
            checkedIn: checkedIn,
            isLoadingCheckIns: isLoadingCheckIns,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await profileCubit.close();
}
