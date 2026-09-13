import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../core/config/api_paths.dart';
import 'marine_weather_repository.dart';

class LiveMarinePoint {
  final LatLng point;
  final double? windKnots;
  final double? waveHeight;
  final double? temperature;
  final double? gustKnots;
  final double? windDirectionDegrees;
  final double? currentKnots;
  final double? currentDirectionDegrees;
  final String sourceStatus;

  const LiveMarinePoint({
    required this.point,
    required this.windKnots,
    required this.waveHeight,
    required this.temperature,
    required this.gustKnots,
    required this.windDirectionDegrees,
    required this.currentKnots,
    required this.currentDirectionDegrees,
    required this.sourceStatus,
  });
}

class LiveForecastPoint {
  final DateTime time;
  final double? windKnots;
  final double? waveHeight;
  final String status;

  const LiveForecastPoint({required this.time, required this.windKnots, required this.waveHeight, required this.status});
}

class LiveMarineAlert {
  final String id;
  final String title;
  final String message;
  final String source;
  final LatLng? point;
  final SafetyLevel severity;

  const LiveMarineAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.source,
    required this.point,
    required this.severity,
  });
}

class LiveVessel {
  final String vesselId;
  final String deviceId;
  final LatLng point;
  final double? speedKnots;
  final double? heading;
  final double? battery;
  final bool sos;
  final bool online;

  const LiveVessel({
    required this.vesselId,
    required this.deviceId,
    required this.point,
    required this.speedKnots,
    required this.heading,
    required this.battery,
    required this.sos,
    required this.online,
  });
}

class LivePfzLine {
  final List<LatLng> points;
  final String label;

  const LivePfzLine({required this.points, required this.label});
}

class MapSearchResult {
  final String name;
  final LatLng point;
  final String source;

  const MapSearchResult({required this.name, required this.point, required this.source});
}

class LiveMarineMapData {
  final List<LiveMarinePoint> points;
  final List<LiveMarineAlert> alerts;
  final DateTime fetchedAt;
  final String status;
  final List<String> sources;
  final List<String> failedSources;
  final List<LiveForecastPoint> forecast;
  final List<LiveVessel> vessels;
  final List<LivePfzLine> pfzLines;

  const LiveMarineMapData({
    required this.points,
    required this.alerts,
    required this.fetchedAt,
    required this.status,
    required this.sources,
    required this.failedSources,
    required this.forecast,
    required this.vessels,
    required this.pfzLines,
  });

  bool get hasMeasurements => points.any((point) => point.windKnots != null || point.waveHeight != null);
}

class LiveMarineMapRepository {
  final Dio _dio;

  const LiveMarineMapRepository(this._dio);

  Future<LiveMarineMapData> load({double latitude = 14.5, double longitude = 82.0}) async {
    try {
      final zoneResponse = await _dio.get<dynamic>(
        ApiPaths.zone,
        queryParameters: {'lat': latitude, 'lon': longitude},
      );
      final zone = _asMap(zoneResponse.data);
      final points = _parseZone(zone);
      Map<String, dynamic> alerts = const {};
      try {
        final alertsResponse = await _dio.get<dynamic>(ApiPaths.alerts);
        alerts = _asMap(alertsResponse.data);
      } on DioException {
        // Alerts are optional; preserve the live marine measurement if they fail.
      }
      final sources = _stringList(zone['sources']);
      final failedSources = _stringList(zone['sources_failed']);
      return LiveMarineMapData(
        points: points,
        alerts: _parseAlerts(alerts['alerts']),
        fetchedAt: DateTime.now(),
        status: points.isEmpty ? 'UNAVAILABLE' : 'LIVE',
        sources: sources,
        failedSources: failedSources,
        forecast: _parseForecast(zone['hourly_forecast']),
        vessels: await _loadVessels(),
        pfzLines: _parsePfz(zone['pfz']),
      );
    } on DioException catch (error) {
      return LiveMarineMapData(
        points: const [],
        alerts: const [],
        fetchedAt: DateTime.now(),
        status: 'UNAVAILABLE: ${error.type.name}',
        sources: const [],
        failedSources: const ['ORCA Box live map API'],
        forecast: const [],
        vessels: const [],
        pfzLines: const [],
      );
    }
  }

  Future<LiveMarinePoint?> probe(double latitude, double longitude) async {
    try {
      final response = await _dio.get<dynamic>(ApiPaths.zone, queryParameters: {'lat': latitude, 'lon': longitude});
      final points = _parseZone(_asMap(response.data));
      return points.isEmpty ? null : points.first;
    } on DioException {
      return null;
    }
  }

  Future<List<LiveMarinePoint>> loadGrid({double latitude = 14.5, double longitude = 82.0, double span = 12}) async {
    try {
      final response = await _dio.get<dynamic>(ApiPaths.grid, queryParameters: {'lat': latitude, 'lon': longitude, 'span': span}, options: Options(receiveTimeout: const Duration(seconds: 45)));
      return _parseGrid(_asMap(response.data));
    } on DioException {
      return const [];
    }
  }

  Future<List<MapSearchResult>> search(String query) async {
    try {
      final response = await _dio.get<dynamic>(ApiPaths.mapSearch, queryParameters: {'query': query});
      final raw = _asMap(response.data)['results'];
      if (raw is! List) return const [];
      return raw.whereType<Map>().map((item) {
        final result = Map<String, dynamic>.from(item);
        return MapSearchResult(
          name: '${result['name'] ?? 'Unnamed location'}',
          point: LatLng(_number(result['latitude']), _number(result['longitude'])),
          source: '${result['source'] ?? 'ORCA Box'}',
        );
      }).where((item) => item.point.latitude != 0 || item.point.longitude != 0).toList(growable: false);
    } on DioException {
      return const [];
    }
  }

  Future<List<LiveVessel>> _loadVessels() async {
    try {
      final response = await _dio.get<dynamic>(ApiPaths.vessels);
      final payload = _asMap(response.data);
      final rawVessels = payload['vessels'];
      if (rawVessels is! List) return const [];
      return rawVessels.whereType<Map<String, dynamic>>().map((item) {
        return LiveVessel(
          vesselId: '${item['vesselId'] ?? 'unknown-vessel'}',
          deviceId: '${item['deviceId'] ?? 'unknown-device'}',
          point: LatLng(_number(item['latitude']), _number(item['longitude'])),
          speedKnots: _optionalNumber(item['speedKnots']),
          heading: _optionalNumber(item['heading']),
          battery: _optionalNumber(item['battery']),
          sos: item['sos'] == true,
          online: item['online'] != false,
        );
      }).toList(growable: false);
    } on DioException {
      return const [];
    }
  }

  List<LiveMarinePoint> _parseZone(Map<String, dynamic> payload) {
    final latitude = _optionalNumber(payload['lat']);
    final longitude = _optionalNumber(payload['lon']);
    if (latitude == null || longitude == null) return const [];
    return [
      LiveMarinePoint(
        point: LatLng(latitude, longitude),
        windKnots: _optionalNumber(payload['wind_speed_kn']),
        waveHeight: _optionalNumber(payload['wave_height_m']),
        temperature: _optionalNumber(payload['sea_temp_c']),
        gustKnots: _optionalNumber(payload['wind_gust_kn']),
        windDirectionDegrees: _optionalNumber(payload['wind_direction']),
        currentKnots: _optionalNumber(payload['current_speed_kn']),
        currentDirectionDegrees: _optionalNumber(payload['current_direction']),
        sourceStatus: 'LIVE',
      ),
    ];
  }

  List<LiveMarinePoint> _parseGrid(Map<String, dynamic> payload) {
    final rawPoints = payload['points'];
    if (rawPoints is! List) return const [];
    return rawPoints.whereType<Map<String, dynamic>>().map((item) {
      return LiveMarinePoint(
        point: LatLng(_number(item['lat']), _number(item['lon'])),
        windKnots: _optionalNumber(item['wind_kn']),
        waveHeight: _optionalNumber(item['wave_h']),
        temperature: _optionalNumber(item['sst_c']),
        gustKnots: null,
        windDirectionDegrees: _optionalNumber(item['wind_direction_deg']),
        currentKnots: null,
        currentDirectionDegrees: null,
        sourceStatus: 'LIVE',
      );
    }).where((point) => point.point.latitude != 0 || point.point.longitude != 0).toList(growable: false);
  }

  List<LiveForecastPoint> _parseForecast(dynamic value) {
    final payload = _asMap(value);
    final times = payload['time'];
    if (times is! List) return const [];
    final winds = payload['wind_speed_kn'];
    final waves = payload['wave_height_m'];
    return List.generate(times.length, (index) {
      final time = DateTime.tryParse('${times[index]}');
      if (time == null) return null;
      return LiveForecastPoint(
        time: time,
        windKnots: winds is List && index < winds.length ? _optionalNumber(winds[index]) : null,
        waveHeight: waves is List && index < waves.length ? _optionalNumber(waves[index]) : null,
        status: 'FORECAST',
      );
    }).whereType<LiveForecastPoint>().toList(growable: false);
  }

  List<LivePfzLine> _parsePfz(dynamic value) {
    if (value is! List) return const [];
    final lines = <LivePfzLine>[];
    for (final raw in value.whereType<Map<String, dynamic>>()) {
      final geometry = raw['geometry'];
      final properties = raw['properties'];
      final label = properties is Map ? '${properties['UID'] ?? properties['Sno'] ?? 'Official PFZ'}' : 'Official PFZ';
      if (geometry is! Map) continue;
      final coordinates = geometry['coordinates'];
      final type = geometry['type'];
      final rawLine = type == 'LineString' ? coordinates : (type == 'MultiLineString' && coordinates is List && coordinates.isNotEmpty ? coordinates.first : null);
      if (rawLine is! List) continue;
      final points = rawLine.cast<dynamic>().whereType<List<dynamic>>().where((item) => item.length >= 2).map((item) => LatLng(_number(item[1]), _number(item[0]))).toList(growable: false);
      if (points.length > 1) lines.add(LivePfzLine(points: points, label: label));
    }
    return lines;
  }

  List<LiveMarineAlert> _parseAlerts(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().map((item) {
      final latitude = _optionalNumber(item['latitude'] ?? item['lat']);
      final longitude = _optionalNumber(item['longitude'] ?? item['lon']);
      return LiveMarineAlert(
        id: '${item['id'] ?? item['title'] ?? 'live-alert'}',
        title: '${item['title'] ?? 'Official marine alert'}',
        message: '${item['message'] ?? 'Open the source alert for instructions.'}',
        source: '${item['source'] ?? 'ORCA live alerts'}',
        point: latitude != null && longitude != null ? LatLng(latitude, longitude) : null,
        severity: _severity('${item['severity'] ?? 'warning'}'),
      );
    }).toList(growable: false);
  }

  static Map<String, dynamic> _asMap(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : const {};
  static List<String> _stringList(dynamic value) => value is List ? value.whereType<String>().toList(growable: false) : const [];
  static double _number(dynamic value) => value is num ? value.toDouble() : 0;
  static double? _optionalNumber(dynamic value) => value is num ? value.toDouble() : null;
  static SafetyLevel _severity(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('danger') || normalized.contains('no-go')) return SafetyLevel.danger;
    if (normalized.contains('warning')) return SafetyLevel.warning;
    if (normalized.contains('caution')) return SafetyLevel.caution;
    return SafetyLevel.safe;
  }
}
