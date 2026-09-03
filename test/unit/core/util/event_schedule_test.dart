import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/util/event_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Event event({
    required String date,
    String? endTime,
  }) => Event(
    id: 'event-1',
    title: 'Town Hall',
    date: date,
    endTime: endTime,
    location: 'Pune',
    imageUrl: '',
  );

  test('marks an event finished after its end time', () {
    final currentTime = DateTime(2026, 8, 31, 17);

    expect(
      EventSchedule.isFinished(
        event(date: '31/08/2026', endTime: '17:00'),
        now: currentTime,
      ),
      isTrue,
    );
  });

  test('keeps an event upcoming before its end time', () {
    final currentTime = DateTime(2026, 8, 31, 16, 59);

    expect(
      EventSchedule.isUpcoming(
        event(date: '31/08/2026', endTime: '17:00'),
        now: currentTime,
      ),
      isTrue,
    );
  });

  test('finishes a date-only event at the next local midnight', () {
    final eventOnCurrentDay = event(date: '31/08/2026');

    expect(
      EventSchedule.isFinished(
        eventOnCurrentDay,
        now: DateTime(2026, 8, 31, 23, 59),
      ),
      isFalse,
    );
    expect(
      EventSchedule.isFinished(
        eventOnCurrentDay,
        now: DateTime(2026, 9, 1),
      ),
      isTrue,
    );
  });

  test('does not classify invalid dates as finished or upcoming', () {
    final invalidEvent = event(date: '31/02/2026');

    expect(EventSchedule.isFinished(invalidEvent), isFalse);
    expect(EventSchedule.isUpcoming(invalidEvent), isFalse);
  });
}
