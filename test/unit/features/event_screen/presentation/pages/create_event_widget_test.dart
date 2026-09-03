import 'package:bdo_event/core/common/form_elements/auth_button.dart';
import 'package:bdo_event/core/model/event_model/event_catagory.dart';
import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/util/resource/app_text.dart';
import 'package:bdo_event/features/event_screen/presentation/cubit/event_screen_cubit.dart';
import 'package:bdo_event/features/event_screen/presentation/pages/create_event_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cubit/event_screen_cubit_test.dart' as fixtures;
import '../../../../shared/fixtures/location_search_adapter.dart';

void main() {
  testWidgets('shows required validation errors for an empty event form', (
    tester,
  ) async {
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(),
    );
    await pumpPage(tester, cubit, const CreateEventPage());

    final createButton = find.widgetWithText(AppButton, AppText.createEvent);
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pump();

    expect(find.text(AppText.enterEventTitle), findsOneWidget);
    expect(find.text(AppText.chooseEventDate), findsOneWidget);
    expect(find.text('Choose a start time'), findsOneWidget);
    expect(find.text('Choose an end time'), findsOneWidget);
    expect(find.text(AppText.enterEventLocation), findsOneWidget);
    expect(find.text(AppText.addAtLeastTenCharacters), findsOneWidget);
    expect(find.text(AppText.pleaseSelectCategory), findsOneWidget);
    await cubit.close();
  });

  testWidgets('hydrates edit form fields from an existing event', (
    tester,
  ) async {
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(),
    );
    final existing = Event(
      id: 'event-1',
      title: 'Town Hall',
      date: '31/12/2099',
      startTime: '09:00',
      endTime: '10:30',
      location: 'Pune',
      imageUrl: 'existing.png',
      description: 'A detailed event description',
    );
    await pumpPage(tester, cubit, CreateEventPage(event: existing));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField && widget.controller?.text == 'Town Hall',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField && widget.controller?.text == '31/12/2099',
      ),
      findsOneWidget,
    );
    expect(find.text(AppText.updateEvent), findsOneWidget);
    await cubit.close();
  });

  testWidgets('rejects an end time that is not after the start time', (
    tester,
  ) async {
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(),
    );
    await pumpPage(tester, cubit, CreateEventPage(event: _validEvent()));

    final endTimeField = tester.widget<TextFormField>(
      find.byType(TextFormField).at(3),
    );
    endTimeField.controller!.text = '09:00';
    await tester.pump();
    final updateButton = find.widgetWithText(AppButton, AppText.updateEvent);
    await tester.ensureVisible(updateButton);
    await tester.tap(updateButton);
    await tester.pump();

    expect(find.text('End time must be after start time'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('rejects a non-positive seat limit', (tester) async {
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(),
    );
    await pumpPage(tester, cubit, CreateEventPage(event: _validEvent()));

    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    await tester.enterText(find.byType(TextFormField).at(4), '0');
    final updateButton = find.widgetWithText(AppButton, AppText.updateEvent);
    await tester.ensureVisible(updateButton);
    await tester.tap(updateButton);
    await tester.pump();

    expect(find.text('Enter a positive number'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('rejects a registration deadline that is no longer in future', (
    tester,
  ) async {
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(),
    );
    await pumpPage(
      tester,
      cubit,
      CreateEventPage(
        event: _validEvent().copyWith(
          registrationDeadline: DateTime.now().subtract(
            const Duration(minutes: 1),
          ),
        ),
      ),
    );

    final updateButton = find.widgetWithText(AppButton, AppText.updateEvent);
    await tester.ensureVisible(updateButton);
    await tester.tap(updateButton);
    await tester.pump();

    expect(find.text('Deadline must be in the future'), findsOneWidget);
    await cubit.close();
  });

  testWidgets('saves a valid edited event and closes the page', (tester) async {
    final repository = fixtures.FakeEventRepository();
    final cubit = fixtures.createCubit(repository: repository);
    await pumpPage(tester, cubit, CreateEventPage(event: _validEvent()));

    final updateButton = find.widgetWithText(AppButton, AppText.updateEvent);
    await tester.ensureVisible(updateButton);
    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    expect(repository.updateCalls, 1);
    expect(find.byType(CreateEventPage), findsNothing);
    await cubit.close();
  });

  testWidgets('searches location through the injected adapter', (tester) async {
    final cubit = fixtures.createCubit(
      repository: fixtures.FakeEventRepository(),
    );
    final locationSearch = RecordingLocationSearchAdapter();
    await pumpPage(
      tester,
      cubit,
      CreateEventPage(
        event: _validEvent(),
        locationSearchAdapter: locationSearch,
      ),
    );

    final searchField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText == AppText.searchAddressOrPlace,
    );
    await tester.enterText(searchField, 'Pune station');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(locationSearch.query, 'Pune station');
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField &&
            widget.initialValue == null,
      ),
      findsAtLeastNWidgets(1),
    );
    await cubit.close();
  });
}

Event _validEvent() => Event(
  id: 'event-1',
  title: 'Town Hall',
  date: '31/12/2099',
  startTime: '09:00',
  endTime: '10:30',
  location: 'Pune',
  imageUrl: 'existing.png',
  description: 'A detailed event description',
  catagory: EventCategory.defaults.first,
);

Future<void> pumpPage(
  WidgetTester tester,
  EventScreenCubit cubit,
  CreateEventPage page,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(value: cubit, child: page),
    ),
  );
  await tester.pump();
}
