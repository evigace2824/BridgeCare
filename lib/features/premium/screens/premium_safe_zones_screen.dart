import 'package:flutter/material.dart';

import '../../../models/family_models.dart';
import '../../family/family_plan_store.dart';

/// Premium safe zones overview and management entry.
class PremiumSafeZonesScreen extends StatefulWidget {
  const PremiumSafeZonesScreen({super.key, this.linkedUser});

  final LinkedUser? linkedUser;

  @override
  State<PremiumSafeZonesScreen> createState() => _PremiumSafeZonesScreenState();
}

class _PremiumSafeZonesScreenState extends State<PremiumSafeZonesScreen> {
  late List<SafeZone> _zones;

  @override
  void initState() {
    super.initState();
    _zones = List.from(widget.linkedUser?.safeZones ?? []);
    if (_zones.isEmpty) {
      _zones = [
        const SafeZone(
          id: '1',
          name: 'Home',
          center: LatLng(41.3275, 19.8187),
          radiusMeters: 200,
        ),
        const SafeZone(
          id: '2',
          name: 'Pharmacy',
          center: LatLng(41.3300, 19.8200),
          radiusMeters: 80,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final cap = FamilyPlanStore.instance.plan.familyMaxSafeZones;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text('Safe zones'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: _zones.length < cap
          ? FloatingActionButton.extended(
              onPressed: _addZone,
              backgroundColor: const Color(0xFF7C3AED),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add zone'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1B74E4).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF1B74E4)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Using ${_zones.length} of $cap zones. Get notified on enter/exit.',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._zones.map(_zoneCard),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Open Location tab for live map & editing'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.map_rounded),
            label: const Text('Open live map on Location tab'),
          ),
        ],
      ),
    );
  }

  Widget _zoneCard(SafeZone z) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.place_rounded, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(z.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  'Radius ${z.radiusMeters.round()} m · ${z.center.latitude.toStringAsFixed(4)}, ${z.center.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Switch(
            value: true,
            onChanged: (_) {},
            activeThumbColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  void _addZone() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add safe zone',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Zone name',
                  hintText: 'e.g. Grandmother\'s house',
                ),
                onSubmitted: (name) {
                  if (name.trim().isEmpty) return;
                  setState(() {
                    _zones.add(SafeZone(
                      id: 'z_${DateTime.now().millisecondsSinceEpoch}',
                      name: name.trim(),
                      center: const LatLng(41.328, 19.819),
                      radiusMeters: 150,
                    ));
                  });
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Pin exact location on the Location tab map.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
