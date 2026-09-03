import 'package:bdo_event/core/common/event_image/event_image_platform.dart';
import 'package:bdo_event/core/util/resource/app_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ignores bundled asset paths during storage cleanup', () async {
    await expectLater(deleteStoredImage(AppAssets.logo), completes);
  });
}
