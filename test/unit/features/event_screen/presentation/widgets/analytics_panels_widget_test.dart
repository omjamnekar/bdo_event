import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/event_screen/presentation/widgets/analytics_insight_panel.dart';
import 'package:bdo_event/features/event_screen/presentation/widgets/analytics_metric_tile.dart';
import 'package:bdo_event/features/event_screen/presentation/widgets/analytics_palette.dart';
import 'package:bdo_event/features/event_screen/presentation/widgets/analytics_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const palette = AnalyticsPalette(
    background: Color(0xFFF3F7F5),
    panel: Colors.white,
    border: Color(0xFFDCE7E2),
    ink: Color(0xFF132322),
    muted: Color(0xFF647773),
    teal: Color(0xFF00A89A),
    coral: Color(0xFFFF6F61),
    gold: Color(0xFFF2B84B),
    lilac: Color(0xFF9B8AFB),
  );

  testWidgets('shows the ready insight when there are no check-ins', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      const AnalyticsInsightPanel(
        registered: 0,
        checkedIn: 0,
        capacity: null,
        palette: palette,
      ),
    );

    expect(find.text(AppText.operationalInsight), findsOneWidget);
    expect(find.text(AppText.readyForEventDay), findsOneWidget);
    expect(find.text(AppText.noCheckInsRecorded), findsOneWidget);
  });

  testWidgets('shows active attendance with singular and plural messages', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      const AnalyticsInsightPanel(
        registered: 4,
        checkedIn: 1,
        capacity: 10,
        palette: palette,
      ),
    );

    expect(find.text(AppText.attendanceIsActive), findsOneWidget);
    expect(find.text(AppText.attendeesArrived(1)), findsOneWidget);

    await pumpPanel(
      tester,
      const AnalyticsInsightPanel(
        registered: 4,
        checkedIn: 2,
        capacity: 10,
        palette: palette,
      ),
    );

    expect(find.text(AppText.attendeesArrived(2)), findsOneWidget);
  });

  testWidgets('prioritizes the capacity insight when the event is full', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      const AnalyticsInsightPanel(
        registered: 10,
        checkedIn: 3,
        capacity: 10,
        palette: palette,
      ),
    );

    expect(find.text(AppText.capacityReached), findsOneWidget);
    expect(find.text(AppText.eventAtCapacityInsight), findsOneWidget);
    expect(find.text(AppText.attendanceIsActive), findsNothing);
  });

  testWidgets('renders open and closed analytics status pills', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AnalyticsStatusPill(isOpen: true, palette: palette),
              AnalyticsStatusPill(isOpen: false, palette: palette),
            ],
          ),
        ),
      ),
    );

    expect(find.text('OPEN'), findsOneWidget);
    expect(find.text('CLOSED'), findsOneWidget);
  });

  testWidgets(
    'uses two metric columns on narrow layouts and four on wide ones',
    (tester) async {
      const metrics = [
        AnalyticsMetricData('One', '1', Icons.looks_one, Colors.red, 'note'),
        AnalyticsMetricData('Two', '2', Icons.looks_two, Colors.green, 'note'),
        AnalyticsMetricData('Three', '3', Icons.looks_3, Colors.blue, 'note'),
        AnalyticsMetricData('Four', '4', Icons.looks_4, Colors.orange, 'note'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: AnalyticsMetricGrid(metrics: metrics, isWide: false),
            ),
          ),
        ),
      );
      var grid = tester.widget<GridView>(find.byType(GridView));
      var delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 820,
              child: AnalyticsMetricGrid(metrics: metrics, isWide: true),
            ),
          ),
        ),
      );
      grid = tester.widget<GridView>(find.byType(GridView));
      delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 4);
    },
  );
}

Future<void> pumpPanel(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
}
