import 'package:latlong2/latlong.dart';
import 'marine_weather_repository.dart';

class SampleMarineWeatherRepository implements MarineWeatherRepository {
  @override
  final MarineWeatherSnapshot snapshot = MarineWeatherSnapshot(
    buoys: [
      MarineBuoy(id: 'IN-BY-07', point: LatLng(16.5, 84.6), windKmh: 42, waveHeight: 2.4, temperature: 28.6, status: SafetyLevel.caution),
      MarineBuoy(id: 'IN-BY-12', point: LatLng(12.3, 87.4), windKmh: 58, waveHeight: 3.7, temperature: 27.9, status: SafetyLevel.warning),
      MarineBuoy(id: 'IN-BY-03', point: LatLng(9.4, 72.4), windKmh: 24, waveHeight: 1.3, temperature: 29.1, status: SafetyLevel.safe),
      MarineBuoy(id: 'IN-BY-19', point: LatLng(20.2, 91.2), windKmh: 71, waveHeight: 5.1, temperature: 27.2, status: SafetyLevel.danger),
      MarineBuoy(id: 'IN-BY-22', point: LatLng(6.3, 80.6), windKmh: 31, waveHeight: 1.8, temperature: 28.8, status: SafetyLevel.safe),
    ],
    boats: [
      MarineBoat(id: 'ORCA-204', point: LatLng(14.2, 75.3), heading: 30, speed: 8.4, status: SafetyLevel.safe),
      MarineBoat(id: 'ORCA-118', point: LatLng(10.2, 83.6), heading: 320, speed: 5.8, status: SafetyLevel.caution),
      MarineBoat(id: 'ORCA-091', point: LatLng(17.9, 88.1), heading: 265, speed: 4.2, status: SafetyLevel.warning),
      MarineBoat(id: 'ORCA-337', point: LatLng(7.8, 72.8), heading: 80, speed: 6.1, status: SafetyLevel.safe),
      MarineBoat(id: 'ORCA-402', point: LatLng(21.4, 86.8), heading: 190, speed: 3.4, status: SafetyLevel.danger),
    ],
    hazards: [
      MarineHazard(title: 'Storm warning', detail: 'Avoid open water east of Visakhapatnam.', point: LatLng(17.4, 84.9), severity: SafetyLevel.danger),
      MarineHazard(title: 'High waves', detail: 'Wave height expected above 4 m.', point: LatLng(13.6, 88.4), severity: SafetyLevel.warning),
      MarineHazard(title: 'Heavy rainfall', detail: 'Visibility may fall below 2 km.', point: LatLng(20.3, 90.0), severity: SafetyLevel.caution),
      MarineHazard(title: 'Unsafe fishing area', detail: 'Temporary exclusion zone.', point: LatLng(9.3, 84.1), severity: SafetyLevel.warning),
      MarineHazard(title: 'Navigation hazard', detail: 'Unlit marker reported.', point: LatLng(6.9, 78.2), severity: SafetyLevel.caution),
    ],
    cyclone: CycloneModel(
      name: 'ORCA-01',
      center: LatLng(16.7, 88.9),
      pressure: 948,
      windKmh: 145,
      category: 'SEVERE CYCLONIC STORM',
      forecastPath: [
        LatLng(16.7, 88.9),
        LatLng(17.5, 89.8),
        LatLng(18.6, 90.7),
        LatLng(20.0, 91.2),
        LatLng(21.8, 91.4),
      ],
    ),
  );
}