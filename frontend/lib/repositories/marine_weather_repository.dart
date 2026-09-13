import 'package:latlong2/latlong.dart';

enum SafetyLevel { safe, caution, warning, danger }

class MarineBuoy {
  final String id;
  final LatLng point;
  final double windKmh;
  final double waveHeight;
  final double temperature;
  final SafetyLevel status;

  const MarineBuoy({
    required this.id,
    required this.point,
    required this.windKmh,
    required this.waveHeight,
    required this.temperature,
    required this.status,
  });
}

class MarineBoat {
  final String id;
  final LatLng point;
  final double heading;
  final double speed;
  final SafetyLevel status;

  const MarineBoat({
    required this.id,
    required this.point,
    required this.heading,
    required this.speed,
    required this.status,
  });
}

class MarineHazard {
  final String title;
  final String detail;
  final LatLng point;
  final SafetyLevel severity;

  const MarineHazard({
    required this.title,
    required this.detail,
    required this.point,
    required this.severity,
  });
}

class CycloneModel {
  final String name;
  final LatLng center;
  final int pressure;
  final int windKmh;
  final String category;
  final List<LatLng> forecastPath;

  const CycloneModel({
    required this.name,
    required this.center,
    required this.pressure,
    required this.windKmh,
    required this.category,
    required this.forecastPath,
  });
}

class MarineWeatherSnapshot {
  final List<MarineBuoy> buoys;
  final List<MarineBoat> boats;
  final List<MarineHazard> hazards;
  final CycloneModel cyclone;

  const MarineWeatherSnapshot({
    required this.buoys,
    required this.boats,
    required this.hazards,
    required this.cyclone,
  });
}

abstract interface class MarineWeatherRepository {
  MarineWeatherSnapshot get snapshot;
}