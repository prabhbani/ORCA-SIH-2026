import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:orca_app/features/map/presentation/utils/route_geometry.dart';

void main() {
  group('RouteGeometry', () {
    test('keeps ordered valid route legs and rejects invalid coordinates', () {
      final points = RouteGeometry.validPoints([
        [18.92, 72.83],
        [18.88, 72.78],
        [91.0, 72.55],
        [18.75, 72.55],
      ]);

      expect(points, hasLength(3));
      expect(points.first, equals(const LatLng(18.92, 72.83)));
      expect(points.last, equals(const LatLng(18.75, 72.55)));
    });

    test('measures a supplied leg without creating route geometry', () {
      final distance = RouteGeometry.distanceKm(
        const LatLng(18.92, 72.83),
        const LatLng(18.75, 72.55),
      );

      expect(distance, closeTo(35.0, 1.0));
      expect(RouteGeometry.bearingRadians(const LatLng(18.92, 72.83), const LatLng(18.75, 72.55)), isNotNull);
    });
  });
}