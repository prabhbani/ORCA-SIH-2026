import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/demo_marine_data.dart';

/// Local-only demo repository. It is loaded only while the app's demo switch is on.
final demoMarineDataProvider = FutureProvider<DemoMarineData>((ref) async {
  final raw = await rootBundle.loadString('assets/demo/sample_marine_data.json');
  final data = DemoMarineData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  if (!data.demo) {
    throw const FormatException('Demo marine data must be marked DEMO');
  }
  return data;
});
