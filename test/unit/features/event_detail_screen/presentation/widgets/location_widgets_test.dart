import 'dart:ui' as ui;

import 'package:bdo_event/core/model/event_model/event_model.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/pages/event_detail_screen.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/widgets/event_location_map.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/widgets/location_map.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/widgets/map_lines_painter.dart';
import 'package:bdo_event/features/event_detail_screen/presentation/widgets/overlay_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';

void main() {
  testWidgets('location chevron expands and collapses the address', (
    tester,
  ) async {
    final event = locationEvent(
      locationAddress:
          '49th Floor, Oberoi Commerz III, International Business Park',
    );
    final overlay = overlayFor(event);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(children: [LocationSection(widget: overlay)]),
        ),
      ),
    );

    final address = find.text(
      '49th Floor, Oberoi Commerz III, International Business Park',
    );
    expect(tester.widget<Text>(address).maxLines, 1);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pump();
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    expect(tester.widget<Text>(address).maxLines, isNull);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
    await tester.pump();
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(tester.widget<Text>(address).maxLines, 1);
  });

  testWidgets('shows a fallback when event coordinates are unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: EventLocationMap(event: locationEvent())),
    );

    expect(
      find.text('Map location is not available for this event yet.'),
      findsOneWidget,
    );
    expect(find.byType(FlutterMap), findsNothing);
  });

  testWidgets('renders a map and marker when event coordinates exist', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EventLocationMap(
          event: locationEvent(latitude: 18.52, longitude: 73.85),
        ),
      ),
    );

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(MarkerLayer), findsOneWidget);
    expect(find.byIcon(Icons.location_on), findsOneWidget);
  });

  testWidgets('paints map-line pixels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          child: SizedBox(
            width: 240,
            height: 180,
            child: CustomPaint(painter: MapLinesPainter()),
          ),
        ),
      ),
    );

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary),
    );
    final image = await boundary.toImage(pixelRatio: 1);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final pixels = byteData!.buffer.asUint8List();

    expect(pixels.any((pixel) => pixel != 0), isTrue);
    image.dispose();
  });
}

Event locationEvent({
  String? locationAddress,
  double? latitude,
  double? longitude,
}) => Event(
  id: 'event-1',
  title: 'Town Hall',
  date: '01/09/2099',
  location: 'Pune',
  imageUrl: '',
  locationAddress: locationAddress,
  latitude: latitude,
  longitude: longitude,
);

OverlayCurveSection overlayFor(Event event) => OverlayCurveSection(
  widget: EventDetailPage(event: event),
  event: event,
  textGrey: Colors.grey,
  primaryDark: Colors.black,
  mapBgColor: Colors.white,
);
