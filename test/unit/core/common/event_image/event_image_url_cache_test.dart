import 'package:bdo_event/core/common/event_image/event_image_url_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expires entries after the configured lifetime', () {
    final cache = ExpiringImageUrlCache(
      timeToLive: const Duration(minutes: 5),
    );
    final createdAt = DateTime(2026, 9, 1, 10);

    cache.put('event-image', 'https://example.com/image', now: createdAt);

    expect(
      cache.get(
        'event-image',
        now: createdAt.add(const Duration(minutes: 4)),
      ),
      'https://example.com/image',
    );
    expect(
      cache.get(
        'event-image',
        now: createdAt.add(const Duration(minutes: 5)),
      ),
      isNull,
    );
  });

  test('evicts the least recently used entry at the size limit', () {
    final cache = ExpiringImageUrlCache(maxEntries: 2);
    final createdAt = DateTime(2026, 9, 1, 10);

    cache.put('first', 'url-1', now: createdAt);
    cache.put('second', 'url-2', now: createdAt);
    expect(cache.get('first', now: createdAt), 'url-1');
    cache.put('third', 'url-3', now: createdAt);

    expect(cache.get('first', now: createdAt), 'url-1');
    expect(cache.get('second', now: createdAt), isNull);
    expect(cache.get('third', now: createdAt), 'url-3');
  });

  test('removes expired entries while resolving another key', () {
    final cache = ExpiringImageUrlCache();
    final createdAt = DateTime(2026, 9, 1, 10);

    cache.put('expired', 'url-1', now: createdAt);
    cache.put('active', 'url-2', now: createdAt);

    expect(
      cache.get(
        'active',
        now: createdAt.add(const Duration(minutes: 50)),
      ),
      isNull,
    );
    expect(cache.get('expired', now: createdAt), isNull);
  });
}
