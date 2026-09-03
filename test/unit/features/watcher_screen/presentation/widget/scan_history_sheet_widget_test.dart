import 'package:bdo_event/features/watcher_screen/domain/model/scan_history_entry.dart';
import 'package:bdo_event/features/watcher_screen/presentation/widget/scan_history_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows an empty history state', (tester) async {
    await pumpHistorySheet(tester, const []);

    expect(find.text('No scans yet'), findsOneWidget);
  });

  testWidgets('disables confirm all when every scan is already complete',
      (tester) async {
    await pumpHistorySheet(tester, const [
      ScanHistoryEntry(
        registrationToken: 'token-1',
        userId: 'user-1',
        displayName: 'Asha',
        status: 'Checked in',
      ),
    ]);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm all'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('confirms all pending scans and closes the sheet', (tester) async {
    var confirmAllCalls = 0;
    await pumpHistorySheet(
      tester,
      const [
        ScanHistoryEntry(
          registrationToken: 'token-1',
          userId: 'user-1',
          displayName: 'Asha',
          status: 'Ready to check in',
        ),
      ],
      onConfirmAll: () async => confirmAllCalls++,
    );

    await tester.tap(find.text('Confirm all'));
    await tester.pumpAndSettle();

    expect(confirmAllCalls, 1);
    expect(find.text('Scan history'), findsNothing);
  });

  testWidgets('confirms a pending entry and closes the sheet', (tester) async {
    var confirmedEntryToken = '';
    await pumpHistorySheet(
      tester,
      const [
        ScanHistoryEntry(
          registrationToken: 'token-1',
          userId: 'user-1',
          displayName: 'Asha',
          status: 'Ready to check in',
        ),
      ],
      onConfirmEntry: (entry) async {
        confirmedEntryToken = entry.registrationToken;
      },
    );

    await tester.tap(find.byTooltip('Confirm check-in'));
    await tester.pumpAndSettle();

    expect(confirmedEntryToken, 'token-1');
    expect(find.text('Scan history'), findsNothing);
  });
}

Future<void> pumpHistorySheet(
  WidgetTester tester,
  List<ScanHistoryEntry> history, {
  Future<void> Function()? onConfirmAll,
  Future<void> Function(ScanHistoryEntry entry)? onConfirmEntry,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ScanHistorySheet(
          history: history,
          onConfirmAll: onConfirmAll ?? () async {},
          onConfirmEntry: onConfirmEntry ?? (_) async {},
          keepHistoryVisibleAfterCheckIn: false,
        ),
      ),
    ),
  );
  await tester.pump();
}
