import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/family_models.dart';

/// Premium smart alerts with priority escalation.
class PremiumAlertsScreen extends StatefulWidget {
  const PremiumAlertsScreen({super.key, this.linkedUser});

  final LinkedUser? linkedUser;

  @override
  State<PremiumAlertsScreen> createState() => _PremiumAlertsScreenState();
}

class _PremiumAlertsScreenState extends State<PremiumAlertsScreen> {
  final List<_SmartAlert> _alerts = [];

  @override
  void initState() {
    super.initState();
    _seed();
  }

  void _seed() {
    final user = widget.linkedUser;
    _alerts.addAll([
      _SmartAlert(
        title: 'Medication reminder missed',
        body: 'Morning dose not confirmed by ${user?.fullName ?? 'patient'}',
        severity: AlertSeverity.warning,
        time: DateTime.now().subtract(const Duration(hours: 2)),
        aiInsight: 'Premium AI: similar pattern last Tuesday — consider a call.',
      ),
      _SmartAlert(
        title: 'Heart rate elevation',
        body: 'HR peaked at 98 bpm during afternoon rest',
        severity: AlertSeverity.info,
        time: DateTime.now().subtract(const Duration(hours: 5)),
        aiInsight: 'Within your custom threshold; no SOS triggered.',
      ),
      _SmartAlert(
        title: 'Safe zone exit',
        body: 'Left "Home" geofence for 12 minutes',
        severity: AlertSeverity.warning,
        time: DateTime.now().subtract(const Duration(days: 1)),
        aiInsight: 'Returned safely. Premium logs full trail.',
      ),
      _SmartAlert(
        title: 'Weekly wellness',
        body: 'All vitals stable — great week overall',
        severity: AlertSeverity.info,
        time: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text('Smart alerts'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length,
        itemBuilder: (_, i) => _card(_alerts[i]),
      ),
    );
  }

  Widget _card(_SmartAlert a) {
    final color = switch (a.severity) {
      AlertSeverity.critical => const Color(0xFFDC2626),
      AlertSeverity.warning => const Color(0xFFF59E0B),
      AlertSeverity.info => const Color(0xFF1B74E4),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.notifications_active_rounded, color: color, size: 22),
        ),
        title: Text(a.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        subtitle: Text(
          DateFormat('MMM d · HH:mm').format(a.time),
          style: const TextStyle(fontSize: 11),
        ),
        children: [
          Text(a.body, style: const TextStyle(fontSize: 13, height: 1.4)),
          if (a.aiInsight != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 18, color: Color(0xFF7C3AED)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a.aiInsight!,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Acknowledge'),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_rounded, size: 16),
                label: const Text('Share with doctor'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmartAlert {
  _SmartAlert({
    required this.title,
    required this.body,
    required this.severity,
    required this.time,
    this.aiInsight,
  });

  final String title;
  final String body;
  final AlertSeverity severity;
  final DateTime time;
  final String? aiInsight;
}
