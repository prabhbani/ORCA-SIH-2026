import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';

import '../core/config/api_paths.dart';
import 'marine_weather_repository.dart';

class LiveMarinePoint {
  final LatLng point;
  final double? windKnots;
  final double? waveHeight;
  final double? temperature;
  final String sourceStatus;

  const LiveMarinePoint({
    required this.point,
    required this.windKnots,
    required this.waveHeight,
    required this.temperature,
    required this.sourceStatus,
  });
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

class LiveMarineMapData {
  final List<LiveMarinePoint> points;
  final List<LiveMarineAlert> alerts;
  final DateTime fetchedAt;
  final String status;
  final List<String> sources;
  final List<String> failedSources;

  const LiveMarineMapData({
    required this.points,
    required this.alerts,
    required this.fetchedAt,
    required this.status,
    required this.sources,
    required this.failedSources,
  });

  bool get hasMeasurements => points.any((point) => point.windKnots != null || point.waveHeight != null);
}

class LiveMarineMapRepository {
  final Dio _dio;

  const LiveMarineMapRepository(this._dio);

  Future<LiveMarineMapData> load({double latitude = 14.5, double longitude = 82.0}) async {
    try {
      final responses = await Future.wait<Response<dynamic>>([
        _dio.get<dynamic>(ApiPaths.grid, queryParameters: {'lat': latitude, 'lon': longitude, 'span': 18}),
        _dio.get<dynamic>(ApiPaths.zone, queryParameters: {'lat': latitude, 'lon': longitude}),
        _dio.get<dynamic>(ApiPaths.alerts),
      ]);
      final grid = _asMap(responses[0].data);
      final zone = _asMap(responses[1].data);
      final alerts = _asMap(responses[2].data);
      final points = _parseGrid(grid);
      final sources = _stringList(zone['sources']);
      final failedSources = _stringList(zone['sources_failed']);
      return LiveMarineMapData(
        points: points,
        alerts: _parseAlerts(alerts['alerts']),
        fetchedAt: DateTime.now(),
        status: points.isEmpty ? 'UNAVAILABLE' : 'LIVE',
        sources: sources,
        failedSources: failedSources,
      );
    } on DioException catch (error) {
      return LiveMarineMapData(
        points: const [],
        alerts: const [],
        fetchedAt: DateTime.now(),
        status: 'UNAVAILABLE: ${error.type.name}',
        sources: const [],
        failedSources: const ['ORCA Box live map API'],
      );
    }
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
        sourceStatus: 'LIVE',
      );
    }).where((point) => point.point.latitude != 0 || point.point.longitude != 0).toList(growable: false);
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
