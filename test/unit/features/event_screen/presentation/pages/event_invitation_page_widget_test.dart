import 'package:bdo_event/core/di/app_dependencies.dart';
import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/prefs/supabase_store.dart';
import 'package:bdo_event/features/event_screen/presentation/pages/event_invitation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../shared/fixtures/fake_notification_event_store.dart';

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('shows available recipients and sends selected users',
      (tester) async {
    final store = FakeNotificationEventStore(
      recipients: const [
        {'id': 'user-1', 'name': 'Asha', 'email': 'asha@example.com'},
        {'id': 'user-2', 'name': '', 'email': 'dev@example.com'},
      ],
    );
    await pumpInvitationPage(tester, store);

    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('dev@example.com'), findsNWidgets(2));
    expect(find.text('Send to 0 users'), findsOneWidget);

    await tester.tap(find.text('Asha'));
    await tester.pump();
    expect(find.text('Send to 1 users'), findsOneWidget);

    await tester.tap(find.text('Send to 1 users'));
    await tester.pumpAndSettle();

    expect(store.sentEventId, 'event-1');
    expect(store.sentUserIds, ['user-1']);
    expect(find.byType(EventInvitationPage), findsNothing);
  });

  testWidgets('shows an empty state when no recipients are available',
      (tester) async {
    await pumpInvitationPage(tester, FakeNotificationEventStore());

    expect(find.text('No users available to invite'), findsOneWidget);
  });

  testWidgets('shows an error when invitation sending fails', (tester) async {
    final store = FakeNotificationEventStore(
      recipients: const [
        {'id': 'user-1', 'name': 'Asha', 'email': 'asha@example.com'},
      ],
      sendError: true,
    );
    await pumpInvitationPage(tester, store);

    await tester.tap(find.text('Asha'));
    await tester.tap(find.text('Send to 1 users'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to send invitations'), findsOneWidget);
    expect(find.byType(EventInvitationPage), findsOneWidget);
  });
}

Future<void> pumpInvitationPage(
  WidgetTester tester,
  FakeNotificationEventStore store,
) async {
  getIt.registerSingleton<EventStore>(store);
  await tester.pumpWidget(
    MaterialApp(
      home: EventInvitationPage(
        event: Event(
          id: 'event-1',
          title: 'Town Hall',
          date: '01/09/2099',
          location: 'Pune',
          imageUrl: '',
        ),
      ),
    ),
  );
  await tester.pump();
}
