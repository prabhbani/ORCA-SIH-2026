import 'package:latlong2/latlong.dart';

class DemoPoint {
  final String id;
  final String name;
  final LatLng point;
  final bool demo;

  const DemoPoint({required this.id, required this.name, required this.point, required this.demo});

  factory DemoPoint.fromJson(Map<String, dynamic> json) => DemoPoint(
        id: json['id'] as String? ?? 'demo-point',
        name: json['name'] as String? ?? 'Demo point',
        point: _point(json['latitude'], json['longitude']),
        demo: json['demo'] == true,
      );
}

class DemoZone extends DemoPoint {
  final String status;
  final String confidence;
  final List<LatLng> polygon;

  const DemoZone({required super.id, required super.name, required super.point, required super.demo, required this.status, required this.confidence, required this.polygon});

  factory DemoZone.fromJson(Map<String, dynamic> json) => DemoZone(
        id: json['id'] as String? ?? 'demo-zone',
        name: json['name'] as String? ?? 'Demo zone',
        point: _pointFromList((json['polygon'] as List<dynamic>).first),
        demo: json['demo'] == true,
        status: json['status'] as String? ?? 'CAUTION',
        confidence: json['confidence'] as String? ?? 'MEDIUM',
        polygon: _points(json['polygon']),
      );
}

class DemoVessel extends DemoPoint {
  final double heading;
  final double speedKnots;
  final String status;
  final List<LatLng> trail;

  const DemoVessel({required super.id, required super.name, required super.point, required super.demo, required this.heading, required this.speedKnots, required this.status, required this.trail});

  factory DemoVessel.fromJson(Map<String, dynamic> json) => DemoVessel(
        id: json['id'] as String? ?? 'demo-vessel',
        name: json['name'] as String? ?? 'Demo vessel',
        point: _point(json['latitude'], json['longitude']),
        demo: json['demo'] == true,
        heading: (json['heading'] as num?)?.toDouble() ?? 0,
        speedKnots: (json['speed_knots'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'STATIONARY',
        trail: _points(json['trail']),
      );
}

class DemoProbe extends DemoPoint {
  final String status;
  final int signalStrength;

  const DemoProbe({required super.id, required super.name, required super.point, required super.demo, required this.status, required this.signalStrength});

  factory DemoProbe.fromJson(Map<String, dynamic> json) => DemoProbe(
        id: json['id'] as String? ?? 'demo-probe',
        name: json['name'] as String? ?? 'Demo probe',
        point: _point(json['latitude'], json['longitude']),
        demo: json['demo'] == true,
        status: json['status'] as String? ?? 'CONNECTED',
        signalStrength: (json['signal_strength'] as num?)?.toInt() ?? 0,
      );
}

class DemoObservation extends DemoPoint {
  final String type;
  final int minutesAgo;

  const DemoObservation({required super.id, required super.name, required super.point, required super.demo, required this.type, required this.minutesAgo});

  factory DemoObservation.fromJson(Map<String, dynamic> json) => DemoObservation(
        id: json['id'] as String? ?? 'demo-observation',
        name: json['name'] as String? ?? 'Demo observation',
        point: _point(json['latitude'], json['longitude']),
        demo: json['demo'] == true,
        type: json['type'] as String? ?? 'OBSERVATION',
        minutesAgo: (json['observed_minutes_ago'] as num?)?.toInt() ?? 0,
      );
}

class DemoRoute {
  final String name;
  final double distanceKm;
  final int etaMinutes;
  final List<LatLng> geometry;

  const DemoRoute({required this.name, required this.distanceKm, required this.etaMinutes, required this.geometry});

  factory DemoRoute.fromJson(Map<String, dynamic> json) => DemoRoute(
        name: json['name'] as String? ?? 'Demo route',
        distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0,
        etaMinutes: (json['eta_minutes'] as num?)?.toInt() ?? 0,
        geometry: _points(json['geometry']),
      );
}

class DemoMarineData {
  final bool demo;
  final String scenario;
  final DemoPoint userLocation;
  final List<DemoPoint> ports;
  final List<DemoZone> zones;
  final DemoRoute route;
  final List<DemoVessel> vessels;
  final List<DemoProbe> probes;
  final List<DemoObservation> observations;
  final List<LatLng> cycloneTrack;
  final LatLng cycloneCenter;
  final List<LatLng> depth20;
  final List<LatLng> depth50;
  final List<LatLng> depth100;
  final String weatherCondition;
  final int temperatureC;
  final int visibilityKm;
  final int windKmh;
  final String windDirection;
  final double waveHeightM;
  final String waveDirection;
  final String seaState;
  final double currentKnots;
  final String currentDirection;
  final List<String> updates;

  const DemoMarineData({required this.demo, required this.scenario, required this.userLocation, required this.ports, required this.zones, required this.route, required this.vessels, required this.probes, required this.observations, required this.cycloneTrack, required this.cycloneCenter, required this.depth20, required this.depth50, required this.depth100, required this.weatherCondition, required this.temperatureC, required this.visibilityKm, required this.windKmh, required this.windDirection, required this.waveHeightM, required this.waveDirection, required this.seaState, required this.currentKnots, required this.currentDirection, required this.updates});

  factory DemoMarineData.fromJson(Map<String, dynamic> json) {
    final weather = _map(json['weather']);
    final wind = _map(json['wind']);
    final waves = _map(json['waves']);
    final current = _map(json['ocean_current']);
    final cyclone = _map(json['cyclone']);
    final updates = (json['marine_updates'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => _map(item)['message'] as String? ?? 'Demo update')
        .toList();
    return DemoMarineData(
      demo: json['demo'] == true && json['environment'] == 'DEMO',
      scenario: json['scenario'] as String? ?? 'demo',
      userLocation: DemoPoint.fromJson(_map(json['user_location'])),
      ports: _items(json['ports'], DemoPoint.fromJson),
      zones: _items(json['fishing_zones'], DemoZone.fromJson),
      route: DemoRoute.fromJson(_rawItems(json['routes']).first),
      vessels: _items(json['vessels'], DemoVessel.fromJson),
      probes: _items(json['probes'], DemoProbe.fromJson),
      observations: _items(json['marine_observations'], DemoObservation.fromJson),
      cycloneTrack: _points(cyclone['forecast_track']),
      cycloneCenter: _point(cyclone['latitude'], cyclone['longitude']),
      depth20: _points(_rawItems(json['depth_contours'])[0]['geometry']),
      depth50: _points(_rawItems(json['depth_contours'])[1]['geometry']),
      depth100: _points(_rawItems(json['depth_contours'])[2]['geometry']),
      weatherCondition: weather['condition'] as String? ?? 'Unavailable',
      temperatureC: (weather['temperature_c'] as num?)?.toInt() ?? 0,
      visibilityKm: (weather['visibility_km'] as num?)?.toInt() ?? 0,
      windKmh: (wind['speed_kmh'] as num?)?.toInt() ?? 0,
      windDirection: wind['direction'] as String? ?? '--',
      waveHeightM: (waves['height_m'] as num?)?.toDouble() ?? 0,
      waveDirection: waves['direction'] as String? ?? '--',
      seaState: waves['sea_state'] as String? ?? '--',
      currentKnots: (current['speed_knots'] as num?)?.toDouble() ?? 0,
      currentDirection: current['direction'] as String? ?? '--',
      updates: updates,
    );
  }
}

Map<String, dynamic> _map(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
List<T> _items<T>(dynamic value, T Function(Map<String, dynamic>) parse) => (value as List<dynamic>? ?? const <dynamic>[]).map((item) => parse(_map(item))).toList();
List<Map<String, dynamic>> _rawItems(dynamic value) => (value as List<dynamic>? ?? const <dynamic>[]).map(_map).toList();
List<LatLng> _points(dynamic value) => (value as List<dynamic>? ?? const <dynamic>[]).map(_pointFromList).where((point) => point.latitude >= -90 && point.latitude <= 90 && point.longitude >= -180 && point.longitude <= 180).toList();
LatLng _pointFromList(dynamic value) => value is List<dynamic> && value.length >= 2 ? _point(value[0], value[1]) : const LatLng(0, 0);
LatLng _point(dynamic latitude, dynamic longitude) => LatLng((latitude as num?)?.toDouble() ?? 0, (longitude as num?)?.toDouble() ?? 0);
