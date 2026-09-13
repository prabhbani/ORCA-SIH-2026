import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/theme/orca_theme.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../repositories/live_marine_map_repository.dart';
import '../../../../repositories/marine_weather_repository.dart';

enum _MarineLayer { wind, waves, temperature, cyclone, rain, water, hazards }

final liveMarineMapProvider = FutureProvider.autoDispose<LiveMarineMapData>((ref) {
  return LiveMarineMapRepository(ref.watch(dioProvider)).load();
});

class MarineSafetyMapScreen extends ConsumerStatefulWidget {
  const MarineSafetyMapScreen({super.key});

  @override
  ConsumerState<MarineSafetyMapScreen> createState() => _MarineSafetyMapScreenState();
}

class _MarineSafetyMapScreenState extends ConsumerState<MarineSafetyMapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _motion;
  late final AnimationController _pulse;
  Timer? _liveRefreshTimer;
  _MarineLayer _layer = _MarineLayer.wind;
  bool _playing = true;
  String? _selectedTitle;
  LiveMarineMapData? _liveData;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _liveRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) ref.invalidate(liveMarineMapProvider);
    });
  }

  @override
  void dispose() {
    _motion.dispose();
    _pulse.dispose();
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveState = ref.watch(liveMarineMapProvider);
    _liveData = liveState.valueOrNull;
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: const LatLng(14.5, 82.0), initialZoom: 4.8, minZoom: 3.5, maxZoom: 9),
            children: [
              TileLayer(
                urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.orca.orca_app',
                maxZoom: 18,
              ),
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_only_labels/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.orca.orca_app',
                tileBuilder: (context, tileWidget, tile) => Opacity(opacity: 0.7, child: tileWidget),
              ),
              CircleLayer(circles: _weatherFields()),
              PolylineLayer(polylines: _windStreamlines()),
              MarkerLayer(markers: _liveMarkers()),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([_motion, _pulse]),
                builder: (context, child) => CustomPaint(
                  painter: _MarineAtmospherePainter(
                    progress: _motion.value,
                    cycloneProgress: _pulse.value,
                    layer: _layer,
                  ),
                ),
              ),
            ),
          ),
          _buildTopBar(),
          _buildLiveStatus(),
          _buildLeftControls(),
          _buildRightRail(),
          _buildBottomTimeline(),
          if (_selectedTitle != null) _buildSelectionPanel(),
        ],
      ),
    );
  }

  List<CircleMarker> _weatherFields() {
    final colors = switch (_layer) {
      _MarineLayer.temperature => [Colors.blue, Colors.teal, Colors.orange, Colors.red],
      _MarineLayer.rain => [Colors.blue, Colors.cyan, Colors.indigo, Colors.purple],
      _ => [const Color(0xFF063B75), const Color(0xFF00BBD4), const Color(0xFF52B848), const Color(0xFFFFB300)],
    };
    final fields = (_liveData?.points ?? const <LiveMarinePoint>[])
        .where((point) => point.windKnots != null || point.waveHeight != null)
        .map((point) => (point.point, 220000 + ((point.windKnots ?? 0) * 6500)))
        .toList(growable: false);
    return List.generate(fields.length, (index) {
      final field = fields[index];
      final intensity = 0.12 + (((_liveData?.points[index].windKnots ?? 0) / 40).clamp(0.0, 0.22));
      return CircleMarker(point: field.$1, radius: field.$2, useRadiusInMeter: true, color: colors[index.clamp(0, colors.length - 1)].withValues(alpha: intensity), borderColor: colors[index.clamp(0, colors.length - 1)].withValues(alpha: 0.28), borderStrokeWidth: 1.4);
    });
  }

  List<Polyline> _windStreamlines() {
    return (_liveData?.points ?? const <LiveMarinePoint>[]).where((point) => point.windKnots != null).expand((point) {
      final drift = 0.08 + ((point.windKnots ?? 0) / 220);
      final phase = _motion.value * drift;
      return <Polyline>[
        Polyline(points: [point.point, LatLng(point.point.latitude + 0.18, point.point.longitude + phase), LatLng(point.point.latitude + 0.34, point.point.longitude + (phase * 1.8))], color: Colors.white.withValues(alpha: 0.72), strokeWidth: 1.2),
      ];
    }).toList(growable: false);
  }

  List<Marker> _liveMarkers() {
    final markers = <Marker>[];
    for (final alert in _liveData?.alerts ?? const <LiveMarineAlert>[]) {
      if (alert.point == null) continue;
      markers.add(Marker(point: alert.point!, width: 46, height: 46, child: GestureDetector(onTap: () => _showDetails(alert.title, '${alert.source}\n${alert.message}'), child: AnimatedBuilder(animation: _pulse, builder: (context, child) => Transform.scale(scale: 0.94 + (_pulse.value * 0.1), child: child), child: Icon(Icons.warning_rounded, color: _statusColor(alert.severity), size: 28)))));
    }
    return markers;
  }

  Color _statusColor(SafetyLevel status) => switch (status) { SafetyLevel.safe => const Color(0xFF42D392), SafetyLevel.caution => const Color(0xFFFFC247), SafetyLevel.warning => const Color(0xFFFF8A3D), SafetyLevel.danger => const Color(0xFFFF4D5D) };

  void _showDetails(String title, String detail) => setState(() => _selectedTitle = '$title\n$detail');

  Widget _buildLiveStatus() {
    final live = _liveData;
    final isLive = live?.status == 'LIVE';
    return Positioned(
      top: 76,
      left: 14,
      child: _GlassPanel(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 9, color: isLive ? const Color(0xFF42D392) : Colors.orange),
            const SizedBox(width: 6),
            Text(isLive ? 'LIVE MARINE DATA' : (live?.status ?? 'CONNECTING TO ORCA BOX'), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
            if (isLive) ...[
              const SizedBox(width: 8),
              Text('${live!.points.length} GRID POINTS', style: const TextStyle(fontSize: 9, color: Colors.white60)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final items = <(IconData, _MarineLayer)>[
      (Icons.air, _MarineLayer.wind),
      (Icons.waves, _MarineLayer.waves),
      (Icons.device_thermostat, _MarineLayer.temperature),
      (Icons.cyclone, _MarineLayer.cyclone),
      (Icons.water_drop, _MarineLayer.rain),
      (Icons.opacity, _MarineLayer.water),
      (Icons.warning_amber, _MarineLayer.hazards),
    ];
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 14, left: 72, right: 72),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _GlassPanel(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in items)
                    _LayerButton(
                      icon: item.$1,
                      selected: _layer == item.$2,
                      onTap: () => setState(() => _layer = item.$2),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftControls() {
    final actions = <(IconData, String, VoidCallback)>[
      (Icons.search, 'Search', () => _showDetails('SEARCH', 'Fishing zones, vessels, buoys and coordinates')),
      (Icons.my_location, 'Recenter', () => _mapController.move(const LatLng(14.5, 82), 4.8)),
      (Icons.add, 'Zoom in', () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 0.7)),
      (Icons.remove, 'Zoom out', () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 0.7)),
    ];
    return Positioned(
      left: 14,
      top: 100,
      child: SafeArea(
        child: _GlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in actions)
                _RailButton(icon: action.$1, label: action.$2, onTap: action.$3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightRail() {
    final legendLabel = _layer == _MarineLayer.temperature
        ? '10-40 C'
        : _layer == _MarineLayer.waves
            ? '0-10 m'
            : '0-120';
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 86, right: 14),
          child: Column(
            children: [
              _RailButton(
                icon: Icons.layers,
                label: 'Layers',
                onTap: () => _showDetails('MAP LAYERS', 'Satellite  Wind  Temperature  Rain  Waves  Cyclone  Boats  Buoys'),
              ),
              const SizedBox(height: 18),
              _GlassPanel(
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 126,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF0753A5), Color(0xFF00C9D7), Color(0xFF55BE47), Color(0xFFFFD447), Color(0xFFFF3F3F)],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(legendLabel, style: const TextStyle(fontSize: 9, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomTimeline() => Positioned(left: 14, right: 14, bottom: 14, child: _GlassPanel(child: Row(children: [IconButton(tooltip: _playing ? 'Pause live wind flow' : 'Animate live wind flow', onPressed: () { setState(() => _playing = !_playing); if (_playing) { _motion.repeat(); } else { _motion.stop(); } }, icon: Icon(_playing ? Icons.pause : Icons.play_arrow, color: Colors.white)), const Text('LIVE', style: TextStyle(fontSize: 10, color: Colors.white70)), Expanded(child: Container(height: 4, decoration: BoxDecoration(color: OrcaTheme.accent.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(4)))), const SizedBox(width: 8), const Text('AUTO REFRESH 2M', style: TextStyle(fontSize: 9, color: Colors.white54)), const SizedBox(width: 8), const Icon(Icons.gps_fixed, color: OrcaTheme.accent, size: 18)])));

  Widget _buildSelectionPanel() => Positioned(left: 14, right: 14, bottom: 78, child: _GlassPanel(child: Row(children: [const Icon(Icons.info_outline, color: OrcaTheme.accent), const SizedBox(width: 10), Expanded(child: Text(_selectedTitle!, style: const TextStyle(fontSize: 12, height: 1.35, color: Colors.white))), IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => setState(() => _selectedTitle = null))])));
}

class _GlassPanel extends StatelessWidget {
  final Widget child;
  const _GlassPanel({required this.child});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xDD071B35), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withValues(alpha: 0.14)), boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18)]), child: child);
}

class _LayerButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _LayerButton({required this.icon, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(tooltip: 'Weather layer', onPressed: onTap, icon: Icon(icon, color: selected ? OrcaTheme.accent : Colors.white70, size: 20), style: IconButton.styleFrom(backgroundColor: selected ? OrcaTheme.accent.withValues(alpha: 0.18) : Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
}

class _RailButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RailButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => IconButton(tooltip: label, onPressed: onTap, icon: Icon(icon, color: Colors.white, size: 21));
}

class _MarineAtmospherePainter extends CustomPainter {
  final double progress;
  final double cycloneProgress;
  final _MarineLayer layer;
  const _MarineAtmospherePainter({required this.progress, required this.cycloneProgress, required this.layer});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final strength = layer == _MarineLayer.wind ? 1.0 : 0.34;
    for (var i = 0; i < 150; i++) {
      final x = ((i * 97.0) % (size.width + 80)) - 40;
      final y = ((i * 53.0) % (size.height + 40)) - 20;
      final drift = (progress * (18 + (i % 5) * 4)) % 42;
      final bend = math.sin(i * 0.72) * 13;
      paint.color = Colors.white.withValues(alpha: (0.16 + ((i % 4) * 0.045)) * strength);
      paint.strokeWidth = 0.8 + ((i % 3) * 0.3);
      final path = ui.Path()..moveTo(x + drift, y)..quadraticBezierTo(x + 12 + drift, y + bend, x + 31 + drift, y + bend + 3);
      canvas.drawPath(path, paint);
    }
    if (layer == _MarineLayer.cyclone) {
      final center = Offset(size.width * 0.68, size.height * 0.42);
      final cyclonePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.white.withValues(alpha: 0.26);
      for (var i = 0; i < 28; i++) {
        final angle = (i * 0.32) + (cycloneProgress * math.pi * 2);
        final radius = 30 + (i * 5.0);
        canvas.drawArc(Rect.fromCircle(center: center, radius: radius), angle, 1.7, false, cyclonePaint);
      }
    }
  }
  @override
  bool shouldRepaint(_MarineAtmospherePainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.cycloneProgress != cycloneProgress || oldDelegate.layer != layer;
}