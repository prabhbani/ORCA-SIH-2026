import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/orca_theme.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../repositories/live_marine_map_repository.dart';
import '../../../../repositories/marine_weather_repository.dart';

enum _MarineLayer { wind, waves, temperature, cyclone, rain, water, hazards, pfz }

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
  double _forecastIndex = 0;
  String? _selectedTitle;
  LiveMarineMapData? _liveData;
  List<LiveMarinePoint> _gridPoints = const [];
  LatLng? _lastMapPoint;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _liveRefreshTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) ref.invalidate(liveMarineMapProvider);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGrid());
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
            options: MapOptions(
              initialCenter: const LatLng(14.5, 82.0),
              initialZoom: 4.8,
              minZoom: 3.5,
              maxZoom: 12,
              onTap: (tapPosition, point) {
                setState(() => _lastMapPoint = point);
                _probeMapPoint(point);
              },
            ),
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
              AnimatedBuilder(
                animation: _motion,
                builder: (context, child) => PolylineLayer(polylines: [..._windStreamlines(), ..._pfzLines()]),
              ),
              MarkerLayer(markers: _liveMarkers()),
            ],
          ),
          _buildTopBar(),
          _buildLiveStatus(),
          _buildLeftControls(),
          _buildRightRail(),
          _buildBottomTimeline(),
          _buildCoordinateReadout(),
          _buildAiButton(),
          if (_selectedTitle != null) _buildSelectionPanel(),
        ],
      ),
    );
  }

  List<CircleMarker> _weatherFields() {
    if (_layer == _MarineLayer.rain || _layer == _MarineLayer.water || _layer == _MarineLayer.cyclone || _layer == _MarineLayer.hazards || _layer == _MarineLayer.pfz) {
      return const [];
    }
    final colors = switch (_layer) {
      _MarineLayer.temperature => [Colors.blue, Colors.teal, Colors.orange, Colors.red],
      _MarineLayer.rain => [Colors.blue, Colors.cyan, Colors.indigo, Colors.purple],
      _ => [const Color(0xFF063B75), const Color(0xFF00BBD4), const Color(0xFF52B848), const Color(0xFFFFB300)],
    };
    final fields = (_gridPoints.isNotEmpty ? _gridPoints : (_liveData?.points ?? const <LiveMarinePoint>[]))
        .where((point) => point.windKnots != null || point.waveHeight != null)
        .map((point) => (point.point, 220000 + ((point.windKnots ?? 0) * 6500)))
        .toList(growable: false);
    return List.generate(fields.length, (index) {
      final field = fields[index];
      final intensity = 0.12 + ((((_gridPoints.isNotEmpty ? _gridPoints[index].windKnots : _liveData?.points[index].windKnots) ?? 0) / 40).clamp(0.0, 0.22));
      return CircleMarker(point: field.$1, radius: field.$2, useRadiusInMeter: true, color: colors[index.clamp(0, colors.length - 1)].withValues(alpha: intensity), borderColor: colors[index.clamp(0, colors.length - 1)].withValues(alpha: 0.28), borderStrokeWidth: 1.4);
    });
  }

  List<Polyline> _windStreamlines() {
    final points = _gridPoints.isNotEmpty ? _gridPoints : (_liveData?.points ?? const <LiveMarinePoint>[]);
    return points.where((point) => point.windKnots != null && point.windDirectionDegrees != null).expand((point) {
      final direction = (point.windDirectionDegrees! + 180) * math.pi / 180;
      final speed = point.windKnots!;
      final length = 0.10 + (speed.clamp(0, 60) / 600);
      final phase = (_motion.value * length) - (length / 2);
      final dLat = math.cos(direction) * length;
      final dLon = math.sin(direction) * length / math.cos(point.point.latitude * math.pi / 180);
      return <Polyline>[
        Polyline(points: [LatLng(point.point.latitude - dLat + phase, point.point.longitude - dLon + phase), LatLng(point.point.latitude + dLat + phase, point.point.longitude + dLon + phase)], color: Colors.white.withValues(alpha: 0.72), strokeWidth: 1.2),
      ];
    }).toList(growable: false);
  }

  List<Polyline> _pfzLines() {
    if (_layer != _MarineLayer.pfz) return const [];
    return (_liveData?.pfzLines ?? const <LivePfzLine>[]).map((line) => Polyline(points: line.points, color: const Color(0xFFFFD447), strokeWidth: 3, pattern: StrokePattern.dashed(segments: [8, 5]))).toList(growable: false);
  }

  List<Marker> _liveMarkers() {
    final markers = <Marker>[];
    for (final vessel in _liveData?.vessels ?? const <LiveVessel>[]) {
      final color = vessel.sos ? const Color(0xFFFF4D5D) : (vessel.online ? const Color(0xFF42D392) : Colors.grey);
      markers.add(Marker(
        point: vessel.point,
        width: 54,
        height: 54,
        child: GestureDetector(
          onTap: () => _showDetails(vessel.vesselId, 'ORCA BOX ${vessel.deviceId}\n${vessel.sos ? 'SOS ACTIVE' : vessel.online ? 'ONLINE' : 'OFFLINE'}\nSpeed ${vessel.speedKnots?.toStringAsFixed(1) ?? 'N/A'} kn  |  Battery ${vessel.battery?.toStringAsFixed(0) ?? 'N/A'}%'),
          child: Transform.rotate(
            angle: (vessel.heading ?? 0) * math.pi / 180,
            child: Icon(vessel.sos ? Icons.sos : Icons.navigation, color: color, size: 25),
          ),
        ),
      ));
    }
    for (final point in (_gridPoints.isNotEmpty ? _gridPoints : (_liveData?.points ?? const <LiveMarinePoint>[]))) {
      markers.add(Marker(point: point.point, width: 18, height: 18, child: GestureDetector(onTap: () => _selectPoint(point), child: const Icon(Icons.circle, color: Colors.white70, size: 9))));
    }
    for (final alert in _liveData?.alerts ?? const <LiveMarineAlert>[]) {
      if (alert.point == null) continue;
      markers.add(Marker(point: alert.point!, width: 46, height: 46, child: GestureDetector(onTap: () => _showDetails(alert.title, '${alert.source}\n${alert.message}'), child: AnimatedBuilder(animation: _pulse, builder: (context, child) => Transform.scale(scale: 0.94 + (_pulse.value * 0.1), child: child), child: Icon(Icons.warning_rounded, color: _statusColor(alert.severity), size: 28)))));
    }
    return markers;
  }

  Future<void> _loadGrid() async {
    final grid = await LiveMarineMapRepository(ref.read(dioProvider)).loadGrid();
    if (mounted && grid.isNotEmpty) setState(() => _gridPoints = grid);
  }

  Future<void> _probeMapPoint(LatLng point) async {
    final result = await LiveMarineMapRepository(ref.read(dioProvider)).probe(point.latitude, point.longitude);
    if (!mounted) return;
    if (result == null) {
      _showDetails('LOCATION UNAVAILABLE', 'No live marine measurement was returned for this coordinate.');
      return;
    }
    _selectPoint(result);
  }

  Future<void> _locateUser() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _showDetails('LOCATION', 'Location services are disabled on this device.');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _showDetails('LOCATION', 'Location permission was not granted.');
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    final point = LatLng(position.latitude, position.longitude);
    _mapController.move(point, 8);
    setState(() => _lastMapPoint = point);
    await _probeMapPoint(point);
  }

  void _selectPoint(LiveMarinePoint point) {
    setState(() {
      _selectedTitle = '${point.point.latitude.toStringAsFixed(2)}° N, ${point.point.longitude.toStringAsFixed(2)}° E\nWind ${point.windKnots?.toStringAsFixed(1) ?? 'N/A'} kn  |  Gust ${point.gustKnots?.toStringAsFixed(1) ?? 'N/A'} kn\nWaves ${point.waveHeight?.toStringAsFixed(1) ?? 'N/A'} m  |  SST ${point.temperature?.toStringAsFixed(1) ?? 'N/A'} C';
    });
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
    const items = <(IconData, _MarineLayer)>[
      (Icons.air, _MarineLayer.wind),
      (Icons.waves, _MarineLayer.waves),
      (Icons.device_thermostat, _MarineLayer.temperature),
      (Icons.warning_amber, _MarineLayer.hazards),
      (Icons.radar, _MarineLayer.pfz),
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
      (Icons.search, 'Search', _openSearch),
      (Icons.my_location, 'Current location', _locateUser),
      (Icons.home_outlined, 'Return to Indian Ocean', () => _mapController.move(const LatLng(14.5, 82), 4.8)),
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
                onTap: _openLayerSheet,
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

  Widget _buildBottomTimeline() {
    final forecast = _liveData?.forecast ?? const <LiveForecastPoint>[];
    return Positioned(left: 14, right: 14, bottom: 14, child: _GlassPanel(child: Row(children: [IconButton(tooltip: _playing ? 'Pause wind animation' : 'Play wind animation', onPressed: () { setState(() => _playing = !_playing); if (_playing) { _motion.repeat(); } else { _motion.stop(); } }, icon: Icon(_playing ? Icons.pause : Icons.play_arrow, color: Colors.white)), Text(forecast.isEmpty ? 'LIVE' : 'FORECAST', style: const TextStyle(fontSize: 10, color: Colors.white70)), Expanded(child: forecast.isEmpty ? Container(height: 4, decoration: BoxDecoration(color: OrcaTheme.accent.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(4))) : Slider(value: _forecastIndex.clamp(0, (forecast.length - 1).toDouble()), max: (forecast.length - 1).toDouble(), activeColor: OrcaTheme.accent, inactiveColor: Colors.white24, onChanged: (value) => setState(() => _forecastIndex = value))), Text(forecast.isEmpty ? 'AUTO 2M' : (forecast[_forecastIndex.round().clamp(0, forecast.length - 1)].time.toLocal().toString().substring(11, 16)), style: const TextStyle(fontSize: 9, color: Colors.white54)), const SizedBox(width: 8), IconButton(tooltip: 'Reset view', onPressed: () => _mapController.move(const LatLng(14.5, 82), 4.8), icon: const Icon(Icons.explore, color: OrcaTheme.accent, size: 18))])));
  }

  Future<void> _openSearch() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: const Text('Search map'), content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Latitude, longitude or place name')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Go'))]));
    if (!mounted || value == null) return;
    final parts = value.split(',').map((part) => double.tryParse(part.trim())).toList();
    if (parts.length == 2 && parts[0] != null && parts[1] != null && parts[0]!.abs() <= 90 && parts[1]!.abs() <= 180) {
      final point = LatLng(parts[0]!, parts[1]!);
      _mapController.move(point, 7.0);
      setState(() => _lastMapPoint = point);
      await _probeMapPoint(point);
    } else {
      final matches = await LiveMarineMapRepository(ref.read(dioProvider)).search(value);
      if (!mounted) return;
      if (matches.isEmpty) {
        _showDetails('SEARCH UNAVAILABLE', 'No ORCA Box geocoding result was returned. Try coordinates such as 14.5, 82.0.');
        return;
      }
      final match = matches.first;
      _mapController.move(match.point, 8.0);
      setState(() => _lastMapPoint = match.point);
      _showDetails('SEARCH RESULT', '${match.name}\nSource: ${match.source}');
      await _probeMapPoint(match.point);
    }
  }

  void _openLayerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF071B35),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            _layerTile(_MarineLayer.wind, Icons.air, 'Wind vectors', 'Live ORCA marine data'),
            _layerTile(_MarineLayer.waves, Icons.waves, 'Wave height', 'Live ORCA marine data'),
            _layerTile(_MarineLayer.temperature, Icons.device_thermostat, 'Sea surface temperature', 'Live ORCA marine data'),
            _layerTile(_MarineLayer.rain, Icons.water_drop, 'Rainfall', 'Available in location details; grid overlay is not connected', available: false),
            _layerTile(_MarineLayer.cyclone, Icons.cyclone, 'Cyclone tracks', 'No authoritative track geometry is currently returned by ORCA Box', available: false),
            _layerTile(_MarineLayer.hazards, Icons.warning_amber, 'Marine warnings', 'Official ORCA alerts'),
            _layerTile(_MarineLayer.pfz, Icons.radar, 'Potential Fishing Zones', 'Official INCOIS PFZ when returned by backend'),
          ],
        ),
      ),
    );
  }

  Widget _layerTile(_MarineLayer layer, IconData icon, String title, String subtitle, {bool available = true}) => ListTile(leading: Icon(icon, color: available && _layer == layer ? OrcaTheme.accent : Colors.white70), title: Text(title, style: const TextStyle(color: Colors.white)), subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)), trailing: available ? null : const Text('UNAVAILABLE', style: TextStyle(fontSize: 10, color: Colors.orange)), onTap: () { Navigator.pop(context); if (available) { setState(() => _layer = layer); } else { _showDetails('$title UNAVAILABLE', subtitle); } });

  Widget _buildCoordinateReadout() => Positioned(left: 14, bottom: 82, child: _GlassPanel(child: Text(_lastMapPoint == null ? 'Tap map to inspect coordinates' : '${_lastMapPoint!.latitude.toStringAsFixed(3)}°, ${_lastMapPoint!.longitude.toStringAsFixed(3)}°', style: const TextStyle(fontSize: 10, color: Colors.white70))));

  Widget _buildAiButton() => Positioned(right: 18, bottom: 82, child: FloatingActionButton.small(heroTag: 'orca-map-ai', tooltip: 'Ask ORCA AI about this map location', backgroundColor: OrcaTheme.accent, onPressed: () => context.go('/ai'), child: const Icon(Icons.auto_awesome, color: Color(0xFF061827))));

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
