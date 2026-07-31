import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/volunteer_models.dart';
import '../data/volunteer_store.dart';
import '../widgets/task_card.dart';
import '../widgets/volunteer_theme.dart';

class VolunteerMapTab extends StatefulWidget {
  const VolunteerMapTab({super.key});

  @override
  State<VolunteerMapTab> createState() => _VolunteerMapTabState();
}

class _VolunteerMapTabState extends State<VolunteerMapTab> {
  static const _fallbackCenter = LatLng(41.3275, 19.8187); // Tirana
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  LatLng _currentLocation = _fallbackCenter;
  bool _liveTracking = false;
  bool _showSatellite = false;
  String? _gpsError;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _gpsError = 'Turn on location services to see live position.');
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _gpsError = 'Location permission denied.');
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _liveTracking = true;
        _gpsError = null;
      });
      _mapController.move(_currentLocation, 14);

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (pos) {
          if (!mounted) return;
          setState(() {
            _currentLocation = LatLng(pos.latitude, pos.longitude);
            _liveTracking = true;
          });
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _liveTracking = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gpsError = 'Live location unavailable on this device.';
        _liveTracking = false;
      });
    }
  }

  /// Compute a deterministic lat/lng for a task around the volunteer's current
  /// location, scaled by `distanceKm`, so the markers appear realistic even
  /// without a real backend feed.
  LatLng _taskLocation(VolunteerTask t) {
    if (t.latitude != null && t.longitude != null) {
      return LatLng(t.latitude!, t.longitude!);
    }
    final hash = t.id.hashCode;
    // bearing (0..2π) derived from the high bits of the id hash
    final bearing = ((hash & 0xFFFF) / 0xFFFF) * 2 * math.pi;
    final dxKm = t.distanceKm * math.cos(bearing);
    final dyKm = t.distanceKm * math.sin(bearing);
    // ~111.32 km per 1° latitude. Longitude scales by cos(lat).
    final dLat = dyKm / 111.32;
    final dLng = dxKm / (111.32 * math.cos(_currentLocation.latitude * math.pi / 180));
    return LatLng(
      _currentLocation.latitude + dLat,
      _currentLocation.longitude + dLng,
    );
  }

  void _recenter() {
    _mapController.move(_currentLocation, 14);
  }

  void _openTask(VolunteerTask task) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: VolunteerTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: VolunteerTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            VolunteerTaskCard(task: task),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VolunteerStore.instance,
      builder: (context, _) {
        final s = VolunteerStore.instance;
        final allTasks = s.openAssistanceNearby;

        final tasksWithLoc = [
          for (final t in allTasks)
            (t, _taskLocation(t)),
        ];

        // Filter by radius using actual distance from current location.
        final visible = tasksWithLoc
            .where((tuple) {
              final meters = _distance.as(LengthUnit.Meter, _currentLocation, tuple.$2);
              return meters <= s.maxRadiusKm * 1000;
            })
            .toList();

        return Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation,
                initialZoom: 14,
                minZoom: 3,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: _showSatellite
                      ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                      : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.carebridge.app',
                  maxZoom: 19,
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentLocation,
                      radius: s.maxRadiusKm * 1000,
                      useRadiusInMeter: true,
                      color: VolunteerTheme.brandAccent.withValues(alpha: 0.10),
                      borderColor: VolunteerTheme.brandAccent.withValues(alpha: 0.45),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (final tuple in visible)
                      Marker(
                        point: tuple.$2,
                        width: 44,
                        height: 56,
                        child: GestureDetector(
                          onTap: () => _openTask(tuple.$1),
                          child: _TaskMarker(task: tuple.$1),
                        ),
                      ),
                    Marker(
                      point: _currentLocation,
                      width: 28,
                      height: 28,
                      child: const _SelfMarker(),
                    ),
                  ],
                ),
                const RichAttributionWidget(
                  showFlutterMapAttribution: false,
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap'),
                  ],
                ),
              ],
            ),
            // Top controls: layer toggle + radius
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F0F2540),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _liveTracking
                              ? Icons.gps_fixed_rounded
                              : Icons.gps_off_rounded,
                          color: _liveTracking
                              ? VolunteerTheme.brandAccent
                              : VolunteerTheme.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _gpsError != null
                                ? _gpsError!
                                : (_liveTracking
                                    ? 'Live location · ${visible.length} tasks within ${s.maxRadiusKm.toStringAsFixed(0)} km'
                                    : 'Looking for your location…'),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: VolunteerTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: _showSatellite ? 'Map view' : 'Satellite',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            _showSatellite
                                ? Icons.map_rounded
                                : Icons.satellite_alt_rounded,
                            color: VolunteerTheme.brandPrimary,
                          ),
                          onPressed: () =>
                              setState(() => _showSatellite = !_showSatellite),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Recenter FAB
            Positioned(
              right: 14,
              bottom: 240,
              child: FloatingActionButton.small(
                heroTag: 'volunteer_recenter',
                backgroundColor: Colors.white,
                foregroundColor: VolunteerTheme.brandPrimary,
                onPressed: _recenter,
                tooltip: 'Recenter on me',
                child: const Icon(Icons.my_location_rounded),
              ),
            ),
            // Bottom carousel + radius slider
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _bottomSheet(visible.map((e) => e.$1).toList(), s),
            ),
          ],
        );
      },
    );
  }

  Widget _bottomSheet(List<VolunteerTask> tasks, VolunteerStore s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: const BoxDecoration(
        color: VolunteerTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F0F2540),
            blurRadius: 18,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: VolunteerTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Nearby tasks',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: VolunteerTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${tasks.length} found',
                style: const TextStyle(
                  fontSize: 12,
                  color: VolunteerTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 168,
            child: tasks.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No tasks within radius. Increase the search radius below.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: VolunteerTheme.textSecondary),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final t = tasks[i];
                      return SizedBox(
                        width: 280,
                        child: GestureDetector(
                          onTap: () =>
                              _mapController.move(_taskLocation(t), 16),
                          child: VolunteerTaskCard(task: t, compact: true),
                        ),
                      );
                    },
                  ),
          ),
          Row(
            children: [
              const Icon(Icons.radar_rounded,
                  size: 16, color: VolunteerTheme.brandPrimary),
              const SizedBox(width: 6),
              const Text(
                'Radius',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: VolunteerTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${s.maxRadiusKm.toStringAsFixed(0)} km',
                style: const TextStyle(
                  color: VolunteerTheme.brandAccent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            value: s.maxRadiusKm,
            min: 1,
            max: 25,
            divisions: 24,
            activeColor: VolunteerTheme.brandAccent,
            label: '${s.maxRadiusKm.toStringAsFixed(0)} km',
            onChanged: s.setMaxRadius,
          ),
        ],
      ),
    );
  }
}

class _SelfMarker extends StatelessWidget {
  const _SelfMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: VolunteerTheme.brandAccent.withValues(alpha: 0.6),
            blurRadius: 14,
            spreadRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: VolunteerTheme.brandAccent,
        ),
      ),
    );
  }
}

class _TaskMarker extends StatelessWidget {
  const _TaskMarker({required this.task});
  final VolunteerTask task;

  @override
  Widget build(BuildContext context) {
    final color = VolunteerTheme.colorForUrgency(task.urgency);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            VolunteerTheme.iconForKind(task.kind),
            color: Colors.white,
            size: 18,
          ),
        ),
        // Pin tail
        CustomPaint(
          size: const Size(14, 10),
          painter: _PinTailPainter(color),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  _PinTailPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
