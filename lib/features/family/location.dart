import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/family_models.dart' as fm;
import '../../services/family_service.dart';
import 'family_plan_store.dart';
import '../../models/user_model.dart';
import '../premium/premium_plans_screen.dart';
import 'subscription_page_clean.dart';

class FamilyLocationPage extends StatefulWidget {
  const FamilyLocationPage({super.key, required this.linkedUser});

  final fm.LinkedUser? linkedUser;

  @override
  State<FamilyLocationPage> createState() => _FamilyLocationPageState();
}

class _FamilyLocationPageState extends State<FamilyLocationPage> {
  static const _primary = Color(0xFF1976D2);
  static const _navy = Color(0xFF0F2A4D);
  static const _teal = Color(0xFF24B6A8);
  static const _green = Color(0xFF4CAF50);
  static const _red = Color(0xFFE53935);
  static const _orange = Color(0xFFFF9800);
  static const _shadow = Color(0x121976D2);

  final _distance = const Distance();
  final FamilyService _service = FamilyService();
  final MapController _mapController = MapController();

  static const _fallbackCenter = LatLng(41.3275, 19.8187);

  late List<fm.SafeZone> _zones;
  /// Caregiver device GPS — same role as [VolunteerMapTab] `_currentLocation`.
  LatLng _myLocation = _fallbackCenter;
  /// Linked elderly/patient position from Supabase (optional).
  LatLng? _patientLocation;
  bool _isInsideSafeZone = true;
  bool _showSatellite = false;
  bool _showHistory = false;
  bool _myGpsLive = false;
  bool _patientLive = false;
  bool _followLive = true;
  double _currentZoom = 14;
  String? _gpsError;
  String? _patientGpsError;
  Timer? _positionTimer;
  RealtimeChannel? _supabaseChannel;
  RealtimeChannel? _locationHistoryChannel;
  StreamSubscription<Position>? _myPosSub;
  DateTime? _lastPatientUpdateAt;
  String _patientLocationSource = 'waiting';
  Timer? _ageRefreshTimer;

  /// Trail built only from real Supabase-fed positions (volunteer map has no fake trail either).
  final List<_HistoryPoint> _history = [];

  @override
  void initState() {
    super.initState();
    _zones = List.from(widget.linkedUser?.safeZones ?? const []);
    final location = widget.linkedUser?.currentLocation;
    if (location != null) {
      _patientLocation = LatLng(location.latitude, location.longitude);
      _lastPatientUpdateAt = DateTime.now();
      _patientLive = true;
      _patientLocationSource = 'linked';
    }
    _recomputeSafety();
    FamilyPlanStore.instance.addListener(_onFamilyPlanChanged);
    _startMyGpsLikeVolunteer();
    _applyLiveTrackingForPlan();
    _ageRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    FamilyPlanStore.instance.removeListener(_onFamilyPlanChanged);
    _positionTimer?.cancel();
    _supabaseChannel?.unsubscribe();
    _locationHistoryChannel?.unsubscribe();
    _myPosSub?.cancel();
    _ageRefreshTimer?.cancel();
    super.dispose();
  }

  void _onFamilyPlanChanged() {
    if (!mounted) return;
    _trimHistoryToPlanCap();
    setState(() {});
    _applyLiveTrackingForPlan();
  }

  void _trimHistoryToPlanCap() {
    final cap = FamilyPlanStore.instance.plan.familyMaxLocationTrailPoints;
    while (_history.length > cap) {
      _history.removeAt(0);
    }
  }

  void _openSubscription() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PremiumPlansScreen(role: UserRole.family),
      ),
    );
  }

  /// Same live GPS pipeline as [VolunteerMapTab] (works on Windows desktop too).
  Future<void> _startMyGpsLikeVolunteer() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _gpsError = 'Turn on location services to see your live position.';
          _myGpsLive = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _gpsError = 'Location permission denied.';
          _myGpsLive = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _myLocation = LatLng(pos.latitude, pos.longitude);
        _myGpsLive = true;
        _gpsError = null;
      });
      _mapController.move(_myLocation, _currentZoom);

      _myPosSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (next) {
          if (!mounted) return;
          final point = LatLng(next.latitude, next.longitude);
          setState(() {
            _myLocation = point;
            _myGpsLive = true;
            _gpsError = null;
          });
          if (_followLive) {
            _mapController.move(point, _currentZoom);
          }
        },
        onError: (_) {
          if (!mounted) return;
          setState(() => _myGpsLive = false);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _gpsError = 'Live location unavailable on this device.';
        _myGpsLive = false;
      });
    }
  }

  LatLng get _safetyCheckPoint =>
      _patientLocation ?? _myLocation;

  void _recomputeSafety() {
    final inside = _computeInsideSafe(_safetyCheckPoint);
    if (!mounted) return;
    if (_isInsideSafeZone != inside) {
      setState(() => _isInsideSafeZone = inside);
    }
  }

  bool _computeInsideSafe(LatLng p) {
    if (_zones.isEmpty) return true;
    for (final zone in _zones) {
      final center = LatLng(zone.center.latitude, zone.center.longitude);
      final meters = _distance.as(LengthUnit.Meter, p, center);
      if (meters <= zone.radiusMeters) return true;
    }
    return false;
  }

  void _ingestPatientPosition(LatLng newPoint, {DateTime? serverAt}) {
    const eps = 2e-5;
    final prev = _patientLocation;
    final moved = prev == null ||
        (newPoint.latitude - prev.latitude).abs() > eps ||
        (newPoint.longitude - prev.longitude).abs() > eps;
    final nextStamp = serverAt ?? DateTime.now();
    final inZone = _computeInsideSafe(newPoint);
    if (!mounted) return;
    setState(() {
      _patientLocation = newPoint;
      _patientLive = true;
      _patientGpsError = null;
      _patientLocationSource = 'supabase';
      if (_lastPatientUpdateAt == null ||
          nextStamp.isAfter(_lastPatientUpdateAt!)) {
        _lastPatientUpdateAt = nextStamp;
      }
      _isInsideSafeZone = inZone;
      if (moved) {
        _history.add(
          _HistoryPoint(point: newPoint, at: nextStamp, inZone: inZone),
        );
        final cap = FamilyPlanStore.instance.plan.familyMaxLocationTrailPoints;
        while (_history.length > cap) {
          _history.removeAt(0);
        }
      }
    });
  }

  Future<void> _addSafeZoneAtPin() async {
    final tier = FamilyPlanStore.instance.plan;
    if (_zones.length >= tier.familyMaxSafeZones) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      final msg = tier == UserPlan.free
          ? 'Free includes ${tier.familyMaxSafeZones} safe zones — upgrade for more.'
          : tier == UserPlan.pro
              ? 'Pro supports ${tier.familyMaxSafeZones} zones — Premium expands the limit.'
              : 'Maximum of ${tier.familyMaxSafeZones} zones reached.';
      messenger?.showSnackBar(
        SnackBar(
          content: Text(msg),
          action: tier == UserPlan.premium
              ? null
              : SnackBarAction(label: 'View plans', onPressed: _openSubscription),
        ),
      );
      return;
    }

    final newZone = fm.SafeZone(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Pinned zone',
      center: fm.LatLng(
        _safetyCheckPoint.latitude,
        _safetyCheckPoint.longitude,
      ),
      radiusMeters: 120,
    );
    setState(() => _zones.add(newZone));
    _recomputeSafety();
    final uid = widget.linkedUser?.uid;
    if (uid != null) {
      await _service.saveSafeZone(elderlyUid: uid, zone: newZone);
    }
  }

  Future<void> _editSafeZone(fm.SafeZone zone) async {
    final controller = TextEditingController(text: zone.name);
    var radius = zone.radiusMeters;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Edit Safe Zone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Zone name'),
              ),
              const SizedBox(height: 12),
              Text('Radius: ${radius.toStringAsFixed(0)} m'),
              Slider(
                value: radius,
                min: 50,
                max: 400,
                divisions: 14,
                onChanged: (v) => setInner(() => radius = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (ok != true || controller.text.trim().isEmpty) return;
    final updated = fm.SafeZone(
      id: zone.id,
      name: controller.text.trim(),
      center: zone.center,
      radiusMeters: radius,
    );
    setState(() {
      final idx = _zones.indexWhere((z) => z.id == zone.id);
      if (idx != -1) _zones[idx] = updated;
    });
    _recomputeSafety();
    final uid = widget.linkedUser?.uid;
    if (uid != null) {
      await _service.saveSafeZone(elderlyUid: uid, zone: updated);
    }
  }

  Future<void> _deleteSafeZone(fm.SafeZone zone) async {
    setState(() => _zones.removeWhere((z) => z.id == zone.id));
    _recomputeSafety();
    final uid = widget.linkedUser?.uid;
    if (uid != null) {
      await _service.deleteSafeZone(elderlyUid: uid, zoneId: zone.id);
    }
  }

  /// Live Supabase realtime on `users` + `location_history` (similar cadence to
  /// volunteer GPS stream), backed by periodic poll for all tiers.
  Future<void> _applyLiveTrackingForPlan() async {
    final uid = widget.linkedUser?.uid;
    if (uid == null) {
      setState(() {
        _patientGpsError = 'No linked elderly account yet.';
        _patientLive = false;
      });
      return;
    }

    await _refreshFromSupabase();

    final tier = FamilyPlanStore.instance.plan;

    _supabaseChannel?.unsubscribe();
    _locationHistoryChannel?.unsubscribe();
    _supabaseChannel = null;
    _locationHistoryChannel = null;

    try {
      final client = Supabase.instance.client;
      _supabaseChannel = client
          .channel('public:users:elderly:$uid')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: uid,
            ),
            callback: (payload) {
              final row = payload.newRecord;
              if (row.isEmpty) return;
              if (!mounted) return;
              _ingestPatientFromUsersRow(row);
            },
          )
          .subscribe();
    } catch (_) {}

    try {
      final client = Supabase.instance.client;
      _locationHistoryChannel = client
          .channel('public:location_history:elderly:$uid')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'location_history',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'elderly_uid',
              value: uid,
            ),
            callback: (payload) {
              final row = payload.newRecord;
              if (row.isEmpty) return;
              if (!mounted) return;
              _ingestPatientFromLocationHistoryRow(row);
            },
          )
          .subscribe();
    } catch (_) {
      // Missing table/column/policy — users stream + polling still work.
    }

    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(
      tier.familyLocationPollInterval,
      (_) => _refreshFromSupabase(),
    );
  }

  void _ingestPatientFromUsersRow(Map<String, dynamic> row) {
    final lat = (row['latitude'] as num?)?.toDouble() ??
        (row['current_latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble() ??
        (row['current_longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    final ts = DateTime.tryParse(
      (row['updated_at'] ?? row['created_at'] ?? '').toString(),
    );
    _ingestPatientPosition(LatLng(lat, lng), serverAt: ts);
  }

  void _ingestPatientFromLocationHistoryRow(Map<String, dynamic> row) {
    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    final ts = DateTime.tryParse((row['created_at'] ?? '').toString());
    _ingestPatientPosition(LatLng(lat, lng), serverAt: ts);
  }

  Future<void> _refreshFromSupabase() async {
    final uid = widget.linkedUser?.uid;
    if (uid == null) return;
    try {
      final snap = await _service.fetchLatestLinkedUserLocationDetailed(uid);
      if (!mounted) return;
      if (snap == null) {
        if (_lastPatientUpdateAt == null) {
          setState(() {
            _patientGpsError =
                'No live location yet — waiting for ${widget.linkedUser?.fullName ?? 'patient'}\'s device.';
            _patientLive = false;
          });
        }
        return;
      }
      _ingestPatientPosition(
        LatLng(snap.latitude, snap.longitude),
        serverAt: snap.recordedAt,
      );
    } catch (_) {
      // Network blip — keep previous location, will retry next tick.
    }
  }

  String _patientAgeLabel() {
    if (_lastPatientUpdateAt == null) return 'Waiting…';
    final secs = DateTime.now().difference(_lastPatientUpdateAt!).inSeconds;
    if (secs < 5) return 'just now';
    if (secs < 60) return '${secs}s ago';
    final mins = secs ~/ 60;
    if (mins < 60) return '${mins}m ago';
    return '${mins ~/ 60}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final tier = FamilyPlanStore.instance.plan;
    final nearestDistance = _nearestDistanceMeters();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _liveHeroCard(nearestDistance, tier),
        if (_gpsError != null) ...[
          const SizedBox(height: 10),
          _card(
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: _orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _gpsError!,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
                TextButton(
                  onPressed: _startMyGpsLikeVolunteer,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
        if (_patientGpsError != null) ...[
          const SizedBox(height: 10),
          _card(
            child: Row(
              children: [
                const Icon(Icons.person_pin_circle_outlined, color: _primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _patientGpsError!,
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12.5),
                  ),
                ),
                TextButton(
                  onPressed: _applyLiveTrackingForPlan,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 380,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _myLocation,
                    initialZoom: _currentZoom,
                    minZoom: 3,
                    maxZoom: 19,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    onPositionChanged: (camera, hasGesture) {
                      _currentZoom = camera.zoom;
                      if (hasGesture && _followLive) {
                        setState(() => _followLive = false);
                      }
                    },
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
                      circles: _zones
                          .map(
                            (zone) => CircleMarker(
                              point: LatLng(
                                  zone.center.latitude, zone.center.longitude),
                              radius: zone.radiusMeters,
                              useRadiusInMeter: true,
                              color: _primary.withAlpha(20),
                              borderColor: _primary.withAlpha(130),
                              borderStrokeWidth: 2,
                            ),
                          )
                          .toList(),
                    ),
                    if (_showHistory)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _history.map((e) => e.point).toList(),
                            color: _primary.withAlpha(180),
                            strokeWidth: 3.5,
                            pattern: StrokePattern.dashed(segments: const [8, 6]),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        if (_patientLocation case final patient?)
                          Marker(
                            point: patient,
                            width: 30,
                            height: 30,
                            child: const _PatientLocationDot(),
                          ),
                        Marker(
                          point: _myLocation,
                          width: 28,
                          height: 28,
                          child: const _MyLocationDot(),
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

                // ─── Top status (volunteer-style live GPS banner) ─────
                Positioned(
                  left: 12,
                  right: 12,
                  top: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
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
                        child: Row(
                          children: [
                            Icon(
                              _myGpsLive
                                  ? Icons.gps_fixed_rounded
                                  : Icons.gps_off_rounded,
                              color: _myGpsLive ? _teal : const Color(0xFF6B7280),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _gpsError ??
                                    (_myGpsLive
                                        ? 'Your live location · updates as you move'
                                        : 'Looking for your location…'),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_patientLive) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _PulseDot(),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.linkedUser?.fullName ?? 'Patient'} · LIVE · ${_patientAgeLabel()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  top: 72,
                  child: Row(
                    children: [
                      const Spacer(),
                      // Map type toggle
                      _MapChip(
                        icon: _showSatellite
                            ? Icons.map_rounded
                            : Icons.satellite_alt_rounded,
                        label: _showSatellite ? 'Map' : 'Satellite',
                        onTap: () =>
                            setState(() => _showSatellite = !_showSatellite),
                      ),
                      const SizedBox(width: 6),
                      // History toggle
                      _MapChip(
                        icon: _showHistory
                            ? Icons.timeline_rounded
                            : Icons.history_rounded,
                        label: _showHistory ? 'Hide trail' : 'Trail',
                        active: _showHistory,
                        onTap: () =>
                            setState(() => _showHistory = !_showHistory),
                      ),
                    ],
                  ),
                ),

                // ─── Bottom: coordinates / safe-zone status ────────────
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 64,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isInsideSafeZone
                              ? Icons.shield_rounded
                              : Icons.warning_amber_rounded,
                          color: _isInsideSafeZone ? _green : _red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isInsideSafeZone
                                    ? 'In a safe zone'
                                    : 'Outside safe zones',
                                style: TextStyle(
                                  color: _isInsideSafeZone ? _green : _red,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                '${_myLocation.latitude.toStringAsFixed(5)}, ${_myLocation.longitude.toStringAsFixed(5)}',
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _followLive
                                ? _primary.withAlpha(30)
                                : const Color(0xFFEFF2F7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _followLive
                                    ? Icons.gps_fixed_rounded
                                    : Icons.gps_not_fixed_rounded,
                                color: _followLive
                                    ? _primary
                                    : const Color(0xFF6B7280),
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _followLive ? 'Following' : 'Free pan',
                                style: TextStyle(
                                  color: _followLive
                                      ? _primary
                                      : const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Bottom-right FABs ─────────────────────────────────
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'family_zoom_in',
                        backgroundColor: Colors.white,
                        foregroundColor: _primary,
                        elevation: 4,
                        onPressed: () {
                          final z = (_currentZoom + 1).clamp(3.0, 19.0);
                          _mapController.move(_myLocation, z);
                          _currentZoom = z;
                        },
                        tooltip: 'Zoom in',
                        child: const Icon(Icons.add_rounded),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'family_zoom_out',
                        backgroundColor: Colors.white,
                        foregroundColor: _primary,
                        elevation: 4,
                        onPressed: () {
                          final z = (_currentZoom - 1).clamp(3.0, 19.0);
                          _mapController.move(_myLocation, z);
                          _currentZoom = z;
                        },
                        tooltip: 'Zoom out',
                        child: const Icon(Icons.remove_rounded),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'family_recenter',
                        backgroundColor: _followLive ? _teal : Colors.white,
                        foregroundColor:
                            _followLive ? Colors.white : _teal,
                        elevation: 4,
                        onPressed: () {
                          setState(() => _followLive = true);
                          _mapController.move(_myLocation, 14);
                          _currentZoom = 14;
                        },
                        tooltip: 'Recenter on me',
                        child: const Icon(Icons.my_location_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_showHistory) ...[
          _modernSectionHeader(
            icon: Icons.history_rounded,
            title: 'Trail stops',
            subtitle: 'Toggle “Trail” on the map · tap a card to jump there',
          ),
          const SizedBox(height: 10),
          _historyStrip(),
          const SizedBox(height: 16),
        ],
        _modernSectionHeader(
          icon: Icons.shield_rounded,
          title: 'Safe zones',
          subtitle: _zones.isEmpty
              ? 'Up to ${tier.familyMaxSafeZones} zones on ${_planNick(tier)} · add radii around home or routines'
              : '${_zones.length}/${tier.familyMaxSafeZones} active · tap to focus on map',
          trailing: _tonalPillButton(
            label: 'Add',
            icon: Icons.add_location_alt_rounded,
            onTap: _addSafeZoneAtPin,
          ),
        ),
        const SizedBox(height: 10),
        if (_zones.isEmpty)
          _softEmptyZonesCard()
        else
          ..._zones.map(_safeZoneTileModern),
      ],
    );
  }

  String _planNick(UserPlan p) =>
      switch (p) {
        UserPlan.free => 'Free',
        UserPlan.pro => 'Pro',
        UserPlan.premium => 'Premium',
      };

  Widget _liveHeroCard(double nearestDistance, UserPlan tier) {
    final name = widget.linkedUser?.fullName ?? 'Loved one';
    final line2 = _myGpsLive
        ? 'Your position updates live on the map (like Volunteer).'
        : (_patientLive
            ? '${name} · live · ${_patientAgeLabel()} · ${_patientLocationSource}'
            : 'Turn on location to see yourself move in real time.');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2A4D),
            Color(0xFF1F5DA0),
            Color(0xFF24B6A8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(
              _isInsideSafeZone
                  ? Icons.verified_user_rounded
                  : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  line2,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_myGpsLive) ...[
                  Text(
                    'Teal dot = you (live GPS) · blue pulse = ${widget.linkedUser?.fullName ?? 'patient'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.67),
                      fontSize: 10.8,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  _zones.isEmpty
                      ? 'No zones — distance N/A'
                      : (_isInsideSafeZone
                          ? 'Inside a safe zone'
                          : 'Outside all zones · ${nearestDistance.toStringAsFixed(0)} m to nearest centre'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Refresh now',
                onPressed: () => _refreshFromSupabase(),
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _zones.isEmpty ? '—' : '${nearestDistance.toStringAsFixed(0)} m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modernSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                _teal.withValues(alpha: 0.18),
                _primary.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: _teal.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: _navy, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: _navy,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: _navy.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }

  Widget _tonalPillButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [_teal, _teal.withValues(alpha: 0.85)],
            ),
            boxShadow: [
              BoxShadow(
                color: _teal.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyStrip() {
    final entries = _history.reversed.toList();
    if (entries.isEmpty) {
      return _card(
        child: const Text(
          'Movements will appear here as we receive live updates.',
          style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
      );
    }
    final timeFmt = DateFormat('HH:mm');
    return SizedBox(
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final e = entries[i];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _mapController.move(e.point, 16);
                setState(() => _followLive = false);
              },
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: 168,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE3EAF3)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0E1A3A6B),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          e.inZone
                              ? Icons.check_circle_rounded
                              : Icons.warning_rounded,
                          size: 16,
                          color: e.inZone ? _green : _orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          e.inZone ? 'Safe' : 'Check',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: _navy,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      timeFmt.format(e.at),
                      style: TextStyle(
                        fontSize: 11,
                        color: _navy.withValues(alpha: 0.45),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${e.point.latitude.toStringAsFixed(4)}, ${e.point.longitude.toStringAsFixed(4)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _softEmptyZonesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EAF3)),
      ),
      child: Column(
        children: [
          Icon(Icons.shield_outlined, size: 36, color: _navy.withValues(alpha: 0.35)),
          const SizedBox(height: 10),
          Text(
            'No safe zones yet',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: _navy.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Use “Add” to drop a geofence on ${widget.linkedUser?.fullName ?? 'their'} current map pin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: _navy.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _safeZoneTileModern(fm.SafeZone zone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(18),
        shadowColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EAF3)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x101A3A6B),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 5,
                    color: _teal,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            zone.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _navy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _miniMeta(Icons.radio_button_unchecked_rounded,
                                  '${zone.radiusMeters.toStringAsFixed(0)} m radius'),
                              const SizedBox(width: 12),
                              _miniMeta(
                                Icons.place_outlined,
                                '${zone.center.latitude.toStringAsFixed(4)}, ${zone.center.longitude.toStringAsFixed(4)}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Show on map',
                        onPressed: () => _mapController.move(
                          LatLng(zone.center.latitude, zone.center.longitude),
                          16,
                        ),
                        icon: const Icon(Icons.map_rounded, color: _primary),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _editSafeZone(zone),
                        icon: const Icon(Icons.edit_rounded, color: _orange),
                      ),
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: () => _deleteSafeZone(zone),
                        icon: const Icon(Icons.delete_outline_rounded, color: _red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniMeta(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: _navy.withValues(alpha: 0.4)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _navy.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _nearestDistanceMeters() {
    if (_zones.isEmpty) return 0;
    var nearest = double.infinity;
    for (final zone in _zones) {
      final center = LatLng(zone.center.latitude, zone.center.longitude);
      final d = _distance.as(LengthUnit.Meter, _safetyCheckPoint, center);
      if (d < nearest) nearest = d;
    }
    return nearest.isFinite ? nearest : 0;
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: _shadow, blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: child,
    );
  }
}

class _HistoryPoint {
  const _HistoryPoint({
    required this.point,
    required this.at,
    required this.inZone,
  });

  final LatLng point;
  final DateTime at;
  final bool inZone;
}

/// Your live GPS pin — same styling as volunteer map self marker.
class _MyLocationDot extends StatelessWidget {
  const _MyLocationDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF24B6A8).withValues(alpha: 0.6),
            blurRadius: 14,
            spreadRadius: 4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF24B6A8),
        ),
      ),
    );
  }
}

class _PatientLocationDot extends StatefulWidget {
  const _PatientLocationDot();

  @override
  State<_PatientLocationDot> createState() => _PatientLocationDotState();
}

class _PatientLocationDotState extends State<_PatientLocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
        ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final v = _ctrl.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 14 + 18 * v,
              height: 14 + 18 * v,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2).withValues(alpha: (1 - v) * 0.4),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x441976D2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF1976D2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// White rounded chip used as a small map control (satellite toggle, etc.).
class _MapChip extends StatelessWidget {
  const _MapChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1976D2) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15,
                  color: active ? Colors.white : const Color(0xFF1976D2)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF1976D2),
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing indicator dot used in the LIVE pill.
class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8 + 0.2 * t),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.45 * (1 - t)),
                blurRadius: 6 + 4 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}