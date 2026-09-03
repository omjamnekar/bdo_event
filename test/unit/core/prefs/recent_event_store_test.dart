import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/core/prefs/recent_event_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('records newest events first and removes duplicate IDs', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = RecentEventStore(preferences);

    for (var index = 0; index < 9; index++) {
      await store.record(event('event-$index'));
    }
    await store.record(event('event-3'));

    expect(store.readIds(), [
      'event-3',
      'event-8',
      'event-7',
      'event-6',
      'event-5',
      'event-4',
      'event-2',
      'event-1',
    ]);
  });

  test('keeps anonymous and signed-in histories separate', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = RecentEventStore(preferences);

    await store.record(event('anonymous-event'));
    await store.record(event('user-event'), userId: 'user-1');

    expect(store.readIds(), ['anonymous-event']);
    expect(store.readIds(userId: 'user-1'), ['user-event']);
  });

  test('does nothing when shared preferences are unavailable', () async {
    final store = RecentEventStore(null);

    await store.record(event('event-1'));

    expect(store.readIds(), isEmpty);
  });
}

Event event(String id) => Event(
  id: id,
  title: id,
  date: '01/09/2099',
  location: 'Pune',
  imageUrl: '',
);
