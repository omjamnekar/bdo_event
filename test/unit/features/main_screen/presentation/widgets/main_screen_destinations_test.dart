import 'package:bdo_event/features/calendar_screen/presentation/pages/calendar_screen.dart';
import 'package:bdo_event/features/event_screen/presentation/pages/event_screen.dart';
import 'package:bdo_event/features/event_screen/presentation/pages/my_event_screen.dart';
import 'package:bdo_event/features/main_screen/domain/entities/main_tab.dart';
import 'package:bdo_event/features/main_screen/presentation/widgets/main_screen_destinations.dart';
import 'package:bdo_event/features/profile_screen/presentation/pages/profile_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('includes the public destinations for a regular user', () {
    final destinations = mainScreenDestinations(
      canScan: false,
      canCreateEvents: false,
    );

    expect(destinations.map((destination) => destination.tab), [
      MainTab.events,
      MainTab.registrations,
      MainTab.profile,
    ]);
    expect(destinations.map((destination) => destination.label), [
      'Event',
      'Register',
      'Profile',
    ]);
    expect(destinations[0].page, isNull);
    expect(destinations[1].page, isNull);
    expect(destinations[2].page, isNull);
    expect(destinations[0].createPage(), isA<EventPage>());
    expect(destinations[1].createPage(), isA<CalendarScreen>());
    expect(destinations[2].createPage(), isA<ProfileScreen>());
  });

  test('adds the organizer destination when event creation is allowed', () {
    final destinations = mainScreenDestinations(
      canScan: false,
      canCreateEvents: true,
    );

    expect(destinations.map((destination) => destination.tab), [
      MainTab.events,
      MainTab.registrations,
      MainTab.createEvent,
      MainTab.profile,
    ]);
    expect(destinations[2].label, 'Create');
    expect(destinations[2].page, isNull);
    expect(destinations[2].createPage(), isA<MyEventScreen>());
  });
}
