import 'package:bdo_event/core/common/clipboard_share.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import '../../../shared/fixtures/clipboard_share_adapters.dart';

void main() {
  test('returns true after copying text successfully', () async {
    final adapter = RecordingClipboardAdapter();

    expect(await tryCopyText(adapter, 'event details'), isTrue);
    expect(adapter.text, 'event details');
  });

  test('returns false when copying text fails', () async {
    final adapter = RecordingClipboardAdapter(error: StateError('clipboard'));

    expect(await tryCopyText(adapter, 'event details'), isFalse);
    expect(adapter.text, isNull);
  });

  test('returns the share result after sharing successfully', () async {
    final adapter = RecordingShareAdapter();
    final params = ShareParams(text: 'event details');

    expect(await tryShareContent(adapter, params), ShareResult.unavailable);
    expect(adapter.params, params);
  });

  test('returns null when sharing fails', () async {
    final adapter = RecordingShareAdapter(error: StateError('sharing'));

    expect(
      await tryShareContent(adapter, ShareParams(text: 'event details')),
      isNull,
    );
    expect(adapter.params, isNull);
  });
}
