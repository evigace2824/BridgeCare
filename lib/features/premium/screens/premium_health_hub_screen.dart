import 'package:flutter/material.dart';

import '../../../models/family_models.dart';
import '../../family/health.dart';

/// Full premium health monitoring hub — opens deep health view.
class PremiumHealthHubScreen extends StatelessWidget {
  const PremiumHealthHubScreen({super.key, this.linkedUser});

  final LinkedUser? linkedUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text('Health monitoring'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Health')),
                    body: FamilyHealthPage(linkedUser: linkedUser),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.open_in_full_rounded, size: 18),
            label: const Text('Full health tab'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _hero(linkedUser),
          const SizedBox(height: 16),
          _vitalTile(
            'Heart rate',
            linkedUser?.heartRateHistory.isNotEmpty == true
                ? '${linkedUser!.heartRateHistory.last.value} bpm'
                : '72 bpm',
            'Normal range',
            Icons.favorite_rounded,
            const Color(0xFFE53935),
          ),
          _vitalTile(
            'Blood pressure',
            _bpLabel(linkedUser),
            'Last reading',
            Icons.monitor_heart_outlined,
            const Color(0xFF185FA5),
          ),
          _vitalTile(
            'Medication',
            _medLabel(linkedUser),
            'Weekly summary',
            Icons.medication_liquid_rounded,
            const Color(0xFF10B981),
          ),
          _vitalTile(
            'Activity',
            '${linkedUser?.reminders.length ?? 0} reminders tracked',
            'Wearable sync',
            Icons.directions_walk_rounded,
            const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: Text(linkedUser?.fullName ?? 'Health'),
                        backgroundColor: Colors.white,
                      ),
                      body: FamilyHealthPage(linkedUser: linkedUser),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.insights_rounded),
              label: const Text('Open full health dashboard'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF185FA5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero(LinkedUser? user) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF185FA5), Color(0xFF42A5F5)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Text(
              (user?.fullName ?? 'C').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Care recipient',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  user?.healthStatus.label ?? 'Monitoring active',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: Color(0xFFFFB300), size: 28),
        ],
      ),
    );
  }

  static String _bpLabel(LinkedUser? user) {
    if (user?.bloodPressureHistory.isNotEmpty != true) return '120/80';
    final v = user!.bloodPressureHistory.last;
    final d = v.secondaryValue;
    return d != null ? '${v.value.round()}/${d.round()}' : '${v.value.round()}';
  }

  static String _medLabel(LinkedUser? user) {
    if (user == null || user.reminders.isEmpty) return 'On track';
    final done = user.reminders.where((r) => r.status == ReminderStatus.done).length;
    return '$done of ${user.reminders.length} completed';
  }

  Widget _vitalTile(
    String title,
    String value,
    String sub,
    IconData icon,
    Color color,
  ) {
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: color)),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}
