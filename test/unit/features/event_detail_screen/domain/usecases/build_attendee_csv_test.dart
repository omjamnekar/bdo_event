import 'package:bdo_event/core/model/user_model/event_attendee.dart';
import 'package:bdo_event/features/event_detail_screen/domain/usecases/build_attendee_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a CSV header and one row per attendee', () {
    final csv = const BuildAttendeeCsv()(
      eventTitle: 'Town Hall',
      attendees: const [
        EventAttendee(userId: 'user-1', displayName: 'Asha'),
        EventAttendee(userId: 'user-2', displayName: 'Dev'),
      ],
    );

    expect(csv, 'Event,Attendee name,User ID\n"Town Hall","Asha","user-1"\n"Town Hall","Dev","user-2"');
  });

  test('escapes quotes in event and attendee values', () {
    final csv = const BuildAttendeeCsv()(
      eventTitle: 'Town "Hall"',
      attendees: const [
        EventAttendee(userId: 'user-1', displayName: 'Asha "Admin"'),
      ],
    );

    expect(csv, 'Event,Attendee name,User ID\n"Town ""Hall""","Asha ""Admin""","user-1"');
  });
}
