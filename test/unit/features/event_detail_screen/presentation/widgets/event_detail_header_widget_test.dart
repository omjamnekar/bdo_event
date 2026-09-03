import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/common/clipboard_share.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/widgets/event_detail_header.dart';
import 'package:bdo_event/features/profile_screen/presentation/cubit/profile_screen_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../shared/fixtures/clipboard_share_adapters.dart';
import '../../../profile_screen/presentation/cubit/profile_screen_cubit_test.dart'
    as profile_fixtures;

void main() {
  testWidgets('copies event details through the clipboard adapter', (
    tester,
  ) async {
    final clipboard = RecordingClipboardAdapter();
    final profileCubit = profile_fixtures.createCubit(
      user: profile_fixtures.testUser,
    );
    await pumpHeader(tester, profileCubit, clipboard: clipboard);

    await openActions(tester);
    await tester.tap(find.text('Copy event details'));
    await tester.pump();

    expect(clipboard.text, contains('Town Hall'));
    expect(clipboard.text, contains('Pune'));
    await profileCubit.close();
  });

  testWidgets('shares event details through the share adapter', (tester) async {
    final sharing = RecordingShareAdapter();
    final profileCubit = profile_fixtures.createCubit(
      user: profile_fixtures.testUser,
    );
    await pumpHeader(tester, profileCubit, share: sharing);

    await openActions(tester);
    await tester.tap(find.text('Share event'));
    await tester.pump();

    expect(sharing.params?.text, contains('Town Hall'));
    expect(sharing.params?.text, contains('bdo-event.app'));
    await profileCubit.close();
  });

  testWidgets('contains event clipboard failures without confirmation', (
    tester,
  ) async {
    final clipboard = RecordingClipboardAdapter(
      error: StateError('clipboard unavailable'),
    );
    final profileCubit = profile_fixtures.createCubit(
      user: profile_fixtures.testUser,
    );
    await pumpHeader(tester, profileCubit, clipboard: clipboard);

    await openActions(tester);
    await tester.tap(find.text(AppText.copyEventDetails));
    await tester.pumpAndSettle();

    expect(find.text(AppText.eventDetailsCopied), findsNothing);
    expect(tester.takeException(), isNull);
    await profileCubit.close();
  });

  testWidgets('contains event share failures', (tester) async {
    final sharing = RecordingShareAdapter(
      error: StateError('sharing unavailable'),
    );
    final profileCubit = profile_fixtures.createCubit(
      user: profile_fixtures.testUser,
    );
    await pumpHeader(tester, profileCubit, share: sharing);

    await openActions(tester);
    await tester.tap(find.text(AppText.shareEvent));
    await tester.pumpAndSettle();

    expect(sharing.params, isNull);
    expect(tester.takeException(), isNull);
    await profileCubit.close();
  });
}

Future<void> pumpHeader(
  WidgetTester tester,
  ProfileScreenCubit profileCubit, {
  ClipboardAdapter? clipboard,
  ShareAdapter? share,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: profileCubit,
        child: Scaffold(
          body: Stack(
            children: [
              EventDetailHeader(
                event: const Event(
                  id: 'event-1',
                  title: 'Town Hall',
                  date: '31/12/2099',
                  location: 'Pune',
                  imageUrl: '',
                ),
                clipboardAdapter: clipboard,
                shareAdapter: share,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> openActions(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert_rounded));
  await tester.pumpAndSettle();
}
