import 'package:bdo_event/features/watcher_screen/presentation/widget/scanner_dashboard.dart';
import 'package:bdo_event/features/watcher_screen/presentation/widget/scanner_icon_button.dart';
import 'package:bdo_event/features/watcher_screen/presentation/widget/scanner_target_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows nullable scanner counters and hides an empty badge', (
    tester,
  ) async {
    await pumpWidgetUnderTest(
      tester,
      const ScannerDashboard(
        checkedInCount: null,
        expectedCount: null,
        historyCount: 0,
        onHistoryPressed: _noop,
      ),
    );

    expect(find.text('Checked in'), findsOneWidget);
    expect(find.text('Expected'), findsOneWidget);
    expect(find.text('--'), findsNWidgets(2));
    expect(find.text('0'), findsNothing);
  });

  testWidgets('shows history count and invokes the history callback', (
    tester,
  ) async {
    var historyPressed = false;
    await pumpWidgetUnderTest(
      tester,
      ScannerDashboard(
        checkedInCount: 4,
        expectedCount: 12,
        historyCount: 3,
        onHistoryPressed: () => historyPressed = true,
      ),
    );

    expect(find.text('4'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byTooltip('View scan history'));

    expect(historyPressed, isTrue);
  });

  testWidgets('wires the scanner icon button action', (tester) async {
    var pressed = false;
    await pumpWidgetUnderTest(
      tester,
      ScannerIconButton(
        tooltip: 'Toggle flashlight',
        icon: Icons.flash_off,
        onPressed: () => pressed = true,
      ),
    );

    await tester.tap(find.byTooltip('Toggle flashlight'));

    expect(pressed, isTrue);
  });

  testWidgets('renders the animated scanner target overlay', (tester) async {
    await pumpWidgetUnderTest(tester, const ScannerTargetOverlay());

    expect(find.byType(AnimatedBuilder), findsOneWidget);
    expect(find.byType(CustomPaint), findsOneWidget);
    expect(
      tester.renderObject<RenderCustomPaint>(find.byType(CustomPaint)).painter,
      isNotNull,
    );
  });
}

const _noop = _doNothing;

void _doNothing() {}

Future<void> pumpWidgetUnderTest(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  await tester.pump();
}
