import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/cache/cache_service.dart';
import '../../../../core/offline/connectivity_watcher.dart';
import '../../../../core/theme/orca_theme.dart';
import '../../../../core/theme/verdict_colors.dart';
import '../../../../core/widgets/orca_app_bar.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../advisory/presentation/providers/advisory_provider.dart';
import '../../../navigate/domain/entities/route_check.dart';
import '../../../navigate/presentation/providers/navigate_provider.dart';
import '../providers/map_provider.dart';
import '../utils/route_geometry.dart';
import '../widgets/layer_selector_dialog.dart';
import '../widgets/probe_bottom_sheet.dart';

enum _LocationStatus { unavailable, locating, ready, cached, denied }

/// Interactive Ocean Map Screen with Tap Probe and Live Data Layers (§8).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _locationPulseController;
  LatLng _currentLocation = const LatLng(AppConfig.defaultLat, AppConfig.defaultLon);
  LatLng? _probedLocation;
  _LocationStatus _locationStatus = _LocationStatus.unavailable;
  double _mapZoom = 9.0;

  @override
  void initState() {
    super.initState();
    _locationPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    restoreLastKnownZone(ref);
    _restoreLastKnownLocation();
  }

  @override
  void dispose() {
    _locationPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final probedSnapshotState = ref.watch(probedZoneProvider);
    final layers = ref.watch(mapLayersProvider);
    final baseUrl = ref.watch(baseUrlProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final advisory = ref.watch(advisoryProvider).valueOrNull;
    final routeState = ref.watch(navigateProvider).valueOrNull;
    final routePoints = RouteGeometry.validPoints(routeState?.check?.legs);
    final routeColor = routeState?.advisory == null
      ? OrcaTheme.accent
      : VerdictColors.fromVerdict(routeState!.advisory!.level);
    final locationColor = advisory == null
      ? OrcaTheme.accent
      : VerdictColors.fromVerdict(advisory.verdict);

    return Scaffold(
      appBar: OrcaAppBar(
        title: 'OCEAN MAP & PROBE',
        subtitle: 'Tap ocean to probe live conditions',
        actions: [
          IconButton(
            icon: const Icon(Icons.layers_outlined, color: OrcaTheme.textPrimary),
            tooltip: 'Data Layers',
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) => const LayerSelectorDialog(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // FlutterMap interactive view
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 9.0,
              minZoom: 4.0,
              maxZoom: 16.0,
              onPositionChanged: (camera, _) {
                if (mounted && (camera.zoom - _mapZoom).abs() > 0.2) {
                  setState(() => _mapZoom = camera.zoom);
                }
              },
              onTap: (tapPosition, point) {
                setState(() {
                  _probedLocation = point;
                });
                probeCoordinate(ref, point.latitude, point.longitude);
              },
            ),
            children: [
              // OpenStreetMap Nautical Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.orca.orca_app',
              ),
              ...layers.where((layer) => layer.isEnabled && layer.tileUrl.contains('{z}')).map(
                (layer) => TileLayer(
                  urlTemplate: layer.tileUrl.startsWith('http')
                      ? layer.tileUrl
                      : '$baseUrl${layer.tileUrl}',
                  userAgentPackageName: 'com.orca.orca_app',
                  tileBuilder: (context, tileWidget, tile) => Opacity(
                    opacity: 0.62,
                    child: tileWidget,
                  ),
                ),
              ),

              if (FeatureFlags.safeCorridorEnabled && routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      color: routeColor,
                      strokeWidth: 7,
                      borderColor: Colors.black54,
                      borderStrokeWidth: 2,
                      pattern: const StrokePattern.solid(),
                    ),
                  ],
                ),

              Scalebar(
                alignment: Alignment.bottomRight,
                padding: EdgeInsets.only(
                  right: 14,
                  bottom: probedSnapshotState != null ? 244 : 16,
                ),
                lineColor: Colors.white,
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 3)],
                ),
              ),

              // Markers layer (Current vessel location + Probed pin)
              MarkerLayer(
                markers: [
                  // Vessel Position Marker
                  if (_locationStatus == _LocationStatus.ready ||
                      _locationStatus == _LocationStatus.cached)
                    Marker(
                      point: _currentLocation,
                      width: 64,
                      height: 64,
                      child: Semantics(
                        label: _locationStatus == _LocationStatus.cached
                          ? 'Last known location'
                          : 'Current location',
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (FeatureFlags.guardianRingEnabled)
                              AnimatedBuilder(
                                animation: _locationPulseController,
                                builder: (context, child) {
                                  final pulse = Curves.easeInOut.transform(
                                    _locationPulseController.value,
                                  );
                                  return Transform.scale(
                                    scale: 0.92 + (pulse * 0.18),
                                    child: Opacity(
                                      opacity: 0.72 - (pulse * 0.42),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: locationColor.withValues(alpha: 0.65),
                                      width: 2,
                                    ),
                                    color: locationColor.withValues(alpha: 0.12),
                                  ),
                                ),
                              ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: OrcaTheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: locationColor, width: 2),
                              ),
                              child: Icon(
                                Icons.navigation,
                                color: locationColor,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Probed Spot Pin
                  if (_probedLocation != null)
                    Marker(
                      point: _probedLocation!,
                      width: 44,
                      height: 44,
                      child: const Icon(
                        Icons.location_on,
                        color: VerdictColors.noGo,
                        size: 38,
                      ),
                    ),
                  ..._buildRouteMarkers(
                    routePoints,
                    routeState?.check,
                    routeState?.advisory,
                  ),
                ],
              ),
            ],
          ),

          // Top Info Banner: Tap instruction
          Positioned(
            top: 10,
            left: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: OrcaTheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: OrcaTheme.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    _locationStatus == _LocationStatus.ready
                        ? Icons.my_location
                        : Icons.touch_app,
                    size: 16,
                    color: OrcaTheme.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                        _locationStatus == _LocationStatus.ready
                          ? 'You are here. Tap the sea to probe conditions.'
                          : _locationStatus == _LocationStatus.cached
                            ? 'Last known location shown. Tap recenter to refresh.'
                            : 'Tap the location button to find you, or probe the map.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: OrcaTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Connection and authoritative advisory status.
          Positioned(
            top: 58,
            left: 14,
            right: 14,
            child: Row(
              children: [
                _StatusChip(
                  icon: isOnline ? Icons.cloud_done : Icons.cloud_off,
                  label: isOnline ? 'ONLINE' : 'OFFLINE',
                  color: isOnline ? VerdictColors.go : VerdictColors.caution,
                ),
                if (advisory != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusChip(
                      icon: VerdictColors.iconForVerdict(advisory.verdict),
                      label: 'SAFETY: ${advisory.verdict.toUpperCase()}',
                      color: VerdictColors.fromVerdict(advisory.verdict),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Touch-friendly map controls.
          Positioned(
            top: 98,
            left: 14,
            child: _CompassControl(
              onPressed: () => _mapController.rotate(0),
            ),
          ),

          // Touch-friendly map controls.
          Positioned(
            top: 98,
            right: 14,
            child: Column(
              children: [
                _MapControl(
                  icon: Icons.add,
                  label: 'Zoom in',
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  ),
                ),
                const SizedBox(height: 8),
                _MapControl(
                  icon: Icons.remove,
                  label: 'Zoom out',
                  onPressed: () => _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  ),
                ),
                const SizedBox(height: 8),
                _MapControl(
                  icon: Icons.my_location,
                  label: 'Recenter map',
                  onPressed: _locateVessel,
                ),
              ],
            ),
          ),

          // Compact legend for the supplied advisory state and user marker.
          Positioned(
            left: 14,
            bottom: probedSnapshotState != null ? 242 : 16,
            child: _MapLegend(
              locationColor: locationColor,
              isCached: _locationStatus == _LocationStatus.cached,
              showRoute: FeatureFlags.safeCorridorEnabled && routePoints.length > 1,
            ),
          ),

          if (FeatureFlags.safeCorridorEnabled && routePoints.length > 1)
            Positioned(
              right: 14,
              bottom: probedSnapshotState != null ? 242 : 16,
              child: _RouteSummary(
                points: routePoints,
                color: routeColor,
                verdict: routeState?.advisory?.level,
              ),
            ),

          // Bottom Probe Sheet when spot is selected
          if (probedSnapshotState != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: probedSnapshotState.when(
                data: (snapshot) => snapshot != null
                    ? ProbeBottomSheet(
                        snapshot: snapshot,
                        onClose: () {
                          setState(() {
                            _probedLocation = null;
                          });
                          ref.read(probedZoneProvider.notifier).state = null;
                        },
                      )
                    : const SizedBox.shrink(),
                loading: () => Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: OrcaTheme.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: OrcaTheme.accent, strokeWidth: 2.5),
                        SizedBox(width: 14),
                        Text(
                          'Probing ocean spot conditions...',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                error: (error, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: OrcaTheme.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: VerdictColors.critical),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          error.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () {
                          ref.read(probedZoneProvider.notifier).state = null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _locateVessel() async {
    if (mounted) {
      setState(() => _locationStatus = _LocationStatus.locating);
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationStatus(_LocationStatus.unavailable);
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setLocationStatus(_LocationStatus.denied);
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (position.latitude < -90 ||
          position.latitude > 90 ||
          position.longitude < -180 ||
          position.longitude > 180) {
        _setLocationStatus(_LocationStatus.unavailable);
        return;
      }

      final location = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _currentLocation = location;
        _locationStatus = _LocationStatus.ready;
      });
      await ref.read(cacheServiceProvider).put('last_known_location', <String, dynamic>{
        'lat': location.latitude,
        'lon': location.longitude,
      });
      _mapController.move(location, 11.0);
    } catch (_) {
      _setLocationStatus(_LocationStatus.unavailable);
    }
  }

  void _setLocationStatus(_LocationStatus status) {
    if (mounted) {
      setState(() => _locationStatus = status);
    }
  }

  List<Marker> _buildRouteMarkers(
    List<LatLng> points,
    RouteCheckEntity? check,
    RouteAdvisoryEntity? advisory,
  ) {
    if (!FeatureFlags.safeCorridorEnabled || points.length < 2) {
      return const <Marker>[];
    }

    final markers = <Marker>[];
    for (var index = 0; index < points.length; index++) {
      final isEndpoint = index == 0 || index == points.length - 1;
      final showLabel = isEndpoint || _mapZoom >= 8;
      final label = index == 0
          ? 'START'
          : index == points.length - 1
              ? 'DESTINATION'
              : check?.detourWaypoint?.name ?? 'STOP ${index + 1}';

      markers.add(
        Marker(
          point: points[index],
          width: showLabel ? 86 : 42,
          height: showLabel ? 62 : 42,
          child: GestureDetector(
            onTap: () => _showWaypointDetails(index, points, check, advisory),
            child: _RouteStopMarker(
              number: index + 1,
              label: showLabel ? label : null,
              color: index == points.length - 1 ? routeColorFor(advisory) : OrcaTheme.accent,
            ),
          ),
        ),
      );
    }

    for (var index = 0; index < points.length - 1; index++) {
      final start = points[index];
      final end = points[index + 1];
      markers.add(
        Marker(
          point: LatLng(
            (start.latitude + end.latitude) / 2,
            (start.longitude + end.longitude) / 2,
          ),
          width: 28,
          height: 28,
          child: AnimatedBuilder(
            animation: _locationPulseController,
            builder: (context, child) {
              final phase = (_locationPulseController.value + (index * 0.19)) % 1.0;
              final emphasis = Curves.easeInOut.transform(phase);
              return Opacity(
                opacity: 0.52 + (emphasis * 0.42),
                child: Transform.scale(
                  scale: 0.86 + (emphasis * 0.16),
                  child: child,
                ),
              );
            },
            child: Transform.rotate(
              angle: RouteGeometry.bearingRadians(start, end),
              child: Icon(Icons.arrow_upward, color: routeColorFor(advisory), size: 22),
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Future<void> _showWaypointDetails(
    int index,
    List<LatLng> points,
    RouteCheckEntity? check,
    RouteAdvisoryEntity? advisory,
  ) async {
    final previousDistance = index == 0 ? null : RouteGeometry.distanceKm(points[index - 1], points[index]);
    final sampledPoint = advisory != null && index < advisory.points.length
        ? advisory.points[index]
        : null;
    final name = index == 0
        ? 'Route start'
        : index == points.length - 1
            ? 'Route destination'
            : check?.detourWaypoint?.name ?? 'Route stop ${index + 1}';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: OrcaTheme.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                index == 0 ? 'Origin' : index == points.length - 1 ? 'Destination' : 'Supplied route waypoint',
                style: const TextStyle(color: OrcaTheme.textSecondary, fontSize: 12),
              ),
              if (previousDistance != null) ...[
                const SizedBox(height: 12),
                Text('Leg distance: ${previousDistance.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white)),
              ],
              if (sampledPoint != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(VerdictColors.iconForVerdict(sampledPoint.state), color: VerdictColors.fromVerdict(sampledPoint.state), size: 18),
                    const SizedBox(width: 8),
                    Text(sampledPoint.state.toUpperCase(), style: TextStyle(color: VerdictColors.fromVerdict(sampledPoint.state), fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(sampledPoint.why, style: const TextStyle(color: OrcaTheme.textSecondary, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restoreLastKnownLocation() async {
    final cached = ref.read(cacheServiceProvider).get('last_known_location');
    final lat = (cached?.data['lat'] as num?)?.toDouble();
    final lon = (cached?.data['lon'] as num?)?.toDouble();
    if (lat == null ||
        lon == null ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _currentLocation = LatLng(lat, lon);
      _locationStatus = _LocationStatus.cached;
    });
  }
}

class _MapControl extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _MapControl({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: OrcaTheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: OrcaTheme.textPrimary, size: 22),
          ),
        ),
      ),
    );
  }
}

Color routeColorFor(RouteAdvisoryEntity? advisory) {
  return advisory == null ? OrcaTheme.accent : VerdictColors.fromVerdict(advisory.level);
}

class _CompassControl extends StatelessWidget {
  final VoidCallback onPressed;

  const _CompassControl({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Reset map to north up',
      child: Material(
        color: OrcaTheme.surface.withValues(alpha: 0.94),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 46,
            height: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.navigation, color: VerdictColors.noGo, size: 22),
                Text('N', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteStopMarker extends StatelessWidget {
  final int number;
  final String? label;
  final Color color;

  const _RouteStopMarker({required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 5)],
          ),
          alignment: Alignment.center,
          child: Text('$number', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
        ),
        if (label != null)
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            color: OrcaTheme.surface.withValues(alpha: 0.92),
            child: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

class _RouteSummary extends StatelessWidget {
  final List<LatLng> points;
  final Color color;
  final String? verdict;

  const _RouteSummary({required this.points, required this.color, required this.verdict});

  @override
  Widget build(BuildContext context) {
    var totalKm = 0.0;
    for (var index = 1; index < points.length; index++) {
      totalKm += RouteGeometry.distanceKm(points[index - 1], points[index]);
    }

    return Container(
      width: 164,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: OrcaTheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.7)),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: color, size: 16),
              const SizedBox(width: 6),
              const Text('ROUTE ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 6),
          Text('Total: ${totalKm.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text('${points.length} supplied stops', style: const TextStyle(color: OrcaTheme.textSecondary, fontSize: 10)),
          if (verdict != null)
            Text(
              'Transit: ${verdict!.toUpperCase()}',
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          const Text('Return leg unavailable', style: TextStyle(color: OrcaTheme.textMuted, fontSize: 9)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: OrcaTheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final Color locationColor;
  final bool isCached;
  final bool showRoute;

  const _MapLegend({
    required this.locationColor,
    required this.isCached,
    required this.showRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: OrcaTheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OrcaTheme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.my_location, color: locationColor, size: 14),
          const SizedBox(width: 5),
          Text(
            isCached ? 'LAST KNOWN' : 'YOU',
            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Container(width: 10, height: 10, color: VerdictColors.noGo),
          const SizedBox(width: 5),
          const Text(
            'PROBE',
            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          if (showRoute) ...[
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward, color: OrcaTheme.accent, size: 14),
            const SizedBox(width: 4),
            const Text(
              'ROUTE',
              style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
