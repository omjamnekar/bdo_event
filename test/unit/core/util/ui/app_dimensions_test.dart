import 'package:bdo_event/core/util/ui/app_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'exposes the supported typography sizes through the resource facade',
    () {
      expect(AppSize.text9, 9);
      expect(AppSize.text16, 16);
      expect(AppSize.text30, 30);
      expect(AppSize.text9, lessThan(AppSize.text30));
    },
  );

  test('exposes the supported spacing values through the resource facade', () {
    expect(AppSpace.space3, 3);
    expect(AppSpace.space16, 16);
    expect(AppSpace.space30, 30);
    expect(AppSpace.space3, lessThan(AppSpace.space30));
  });
}
