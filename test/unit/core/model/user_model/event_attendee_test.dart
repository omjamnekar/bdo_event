import 'package:bdo_event/core/model/user_model/event_attendee.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps attendee identity and optional photo data', () {
    final attendee = EventAttendee.fromJson({
      'userId': 'user-1',
      'displayName': 'Asha',
      'photoUrl': 'https://example.com/asha.png',
    });

    expect(attendee.userId, 'user-1');
    expect(attendee.displayName, 'Asha');
    expect(attendee.photoUrl, 'https://example.com/asha.png');
  });

  test('uses User when the display name is missing', () {
    final attendee = EventAttendee.fromJson({'userId': 'user-2'});

    expect(attendee.displayName, 'User');
    expect(attendee.photoUrl, isNull);
  });
}
