import 'package:bdo_event/core/model/location_model/location_catalog.dart';
import 'package:bdo_event/core/model/location_model/location_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips location fields through JSON', () {
    const location = Location(
      id: 'office-1',
      name: 'BDO Rise Office',
      city: 'Pune',
      country: 'India',
      zone: 'West',
      address: 'Main Street',
      latitude: 18.52,
      longitude: 73.85,
    );

    final decoded = Location.fromJson(location.toJson());

    expect(decoded.id, location.id);
    expect(decoded.name, location.name);
    expect(decoded.city, location.city);
    expect(decoded.country, location.country);
    expect(decoded.zone, location.zone);
    expect(decoded.address, location.address);
    expect(decoded.latitude, location.latitude);
    expect(decoded.longitude, location.longitude);
  });

  test('formats display names with an optional zone', () {
    const withoutZone = Location(
      id: 'office-1',
      name: 'Office',
      city: 'Pune',
      country: 'India',
    );
    const withZone = Location(
      id: 'office-2',
      name: 'Office',
      city: 'Pune',
      country: 'India',
      zone: 'West',
    );

    expect(withoutZone.displayName, 'Pune, India');
    expect(withZone.displayName, 'Pune, India (West)');
  });

  test('copyWith clears nullable location fields when null is provided', () {
    const location = Location(
      id: 'office-1',
      name: 'BDO Rise Office',
      city: 'Pune',
      country: 'India',
      zone: 'West',
      address: 'Main Street',
      latitude: 18.52,
      longitude: 73.85,
    );

    final cleared = location.copyWith(
      zone: null,
      address: null,
      latitude: null,
      longitude: null,
    );

    expect(cleared.zone, isNull);
    expect(cleared.address, isNull);
    expect(cleared.latitude, isNull);
    expect(cleared.longitude, isNull);
  });

  test('finds catalog offices by id and returns null for unknown ids', () {
    final office = LocationCatalog.offices.first;

    expect(LocationCatalog.byId(office.id), same(office));
    expect(LocationCatalog.byId('missing-office'), isNull);
    expect(LocationCatalog.byId(null), isNull);
  });
}
