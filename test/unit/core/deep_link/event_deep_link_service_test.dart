import 'package:bdo_event/core/deep_link/event_deep_link_service.dart';
import 'package:bdo_event/core/util/resource/app_deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds an encoded event deep link', () {
    final uri = EventDeepLinkService.eventUri('event/with spaces');

    expect(uri.scheme, AppDeepLinks.httpsScheme);
    expect(uri.host, Uri.parse(AppDeepLinks.baseUrl).host);
    expect(uri.pathSegments, ['events', 'event/with spaces']);
  });

  test('extracts event IDs from HTTPS and custom-scheme links', () {
    expect(
      EventDeepLinkService.eventIdFromUri(
        Uri.parse('${AppDeepLinks.baseUrl}/events/event-1'),
      ),
      'event-1',
    );
    expect(
      EventDeepLinkService.eventIdFromUri(
        Uri.parse('bdoevent://events/event-2'),
      ),
      'event-2',
    );
  });

  test('rejects unsupported hosts, schemes, and paths', () {
    expect(
      EventDeepLinkService.eventIdFromUri(
        Uri.parse('https://other.example/events/event-1'),
      ),
      isNull,
    );
    expect(
      EventDeepLinkService.eventIdFromUri(
        Uri.parse('http://bdo-event.app/events/event-1'),
      ),
      isNull,
    );
    expect(
      EventDeepLinkService.eventIdFromUri(
        Uri.parse('${AppDeepLinks.baseUrl}/other/event-1'),
      ),
      isNull,
    );
    expect(
      EventDeepLinkService.eventIdFromUri(
        Uri.parse('${AppDeepLinks.baseUrl}/events/event-1/extra'),
      ),
      isNull,
    );
  });

  test('rejects an empty event ID', () {
    expect(
      EventDeepLinkService.eventIdFromUri(
        Uri.parse('${AppDeepLinks.baseUrl}/events/%20'),
      ),
      isNull,
    );
  });

  test('preserves percent characters in encoded event IDs', () {
    expect(
      EventDeepLinkService.eventIdFromUri(
        EventDeepLinkService.eventUri('event%2Fid'),
      ),
      'event%2Fid',
    );
    expect(
      EventDeepLinkService.eventIdFromUri(
        Uri.parse('bdoevent://events/event%252Fid'),
      ),
      'event%2Fid',
    );
  });
}
