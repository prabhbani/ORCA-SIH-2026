import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Presentation-only geometry helpers for supplied route coordinates.
class RouteGeometry {
  const RouteGeometry._();

  static List<LatLng> validPoints(List<List<double>>? legs) {
    if (legs == null) return const <LatLng>[];
    return legs
        .where((leg) => leg.length >= 2 && leg[0] >= -90 && leg[0] <= 90 && leg[1] >= -180 && leg[1] <= 180)
        .map((leg) => LatLng(leg[0], leg[1]))
        .toList(growable: false);
  }

  static double bearingRadians(LatLng start, LatLng end) {
    final latitude1 = start.latitude * math.pi / 180;
    final latitude2 = end.latitude * math.pi / 180;
    final deltaLongitude = (end.longitude - start.longitude) * math.pi / 180;
    return math.atan2(
      math.sin(deltaLongitude) * math.cos(latitude2),
      math.cos(latitude1) * math.sin(latitude2) -
          math.sin(latitude1) * math.cos(latitude2) * math.cos(deltaLongitude),
    );
  }

  static double distanceKm(LatLng start, LatLng end) {
    const earthRadiusKm = 6371.0;
    final latitudeDelta = (end.latitude - start.latitude) * math.pi / 180;
    final longitudeDelta = (end.longitude - start.longitude) * math.pi / 180;
    final latitude1 = start.latitude * math.pi / 180;
    final latitude2 = end.latitude * math.pi / 180;
    final a = math.pow(math.sin(latitudeDelta / 2), 2) +
        math.cos(latitude1) * math.cos(latitude2) * math.pow(math.sin(longitudeDelta / 2), 2);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }
}