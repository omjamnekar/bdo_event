import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/features/event_screen/data/model/event_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const event = Event(
    id: 'event-1',
    title: 'Town Hall',
    date: '01/09/2026',
    location: 'Pune',
    imageUrl: '',
  );

  test('converts between the DTO and domain event', () {
    expect(EventDto.fromDomain(event).toDomain(), same(event));
    expect(EventDto(event).toDomain(), same(event));
  });

  test('round-trips the event JSON payload', () {
    final decoded = EventDto.fromJson(event.toJson());

    expect(decoded.event.id, event.id);
    expect(decoded.toJson()['title'], event.title);
  });
}
