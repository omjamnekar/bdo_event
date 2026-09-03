import 'package:bdo_event/core/util/resource/app_other.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exposes shared MIME type constants through the resource facade', () {
    expect(AppMimeTypes.jpeg, 'image/jpeg');
    expect(AppMimeTypes.csv, 'text/csv');
  });

  test('exposes supported date formats through the resource facade', () {
    expect(AppDateFormats.dayMonthYear, 'dd/MM/yyyy');
    expect(AppDateFormats.monthDayYear, 'MM/dd/yyyy');
    expect(AppDateFormats.yearMonthDay, 'yyyy-MM-dd');
  });

  test('exposes the shared monospace font family constant', () {
    expect(AppUtil.monospace, 'monospace');
  });
}
