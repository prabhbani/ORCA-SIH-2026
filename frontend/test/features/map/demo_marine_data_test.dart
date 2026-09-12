import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orca_app/features/map/domain/entities/demo_marine_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses the isolated demo marine contract without mixing production data', () async {
    final raw = await rootBundle.loadString('assets/demo/sample_marine_data.json');
    final data = DemoMarineData.fromJson(jsonDecode(raw) as Map<String, dynamic>);

    expect(data.demo, isTrue);
    expect(data.zones, hasLength(3));
    expect(data.vessels, hasLength(3));
    expect(data.probes, hasLength(4));
    expect(data.route.geometry, hasLength(5));
    expect(data.route.geometry.first.latitude, closeTo(9.9667, 0.0001));
    expect(data.currentDirection, equals('E'));
    expect(data.updates, isNotEmpty);
  });
}
