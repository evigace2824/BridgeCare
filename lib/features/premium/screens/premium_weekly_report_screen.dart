import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/family_models.dart';
import '../../family/family_plan_store.dart';

/// Premium weekly health & activity report.
class PremiumWeeklyReportScreen extends StatelessWidget {
  const PremiumWeeklyReportScreen({super.key, this.linkedUser});

  final LinkedUser? linkedUser;

  @override
  Widget build(BuildContext context) {
    final user = linkedUser;
    final now = DateTime.now();
    final weekLabel = DateFormat('MMM d').format(now.subtract(const Duration(days: 7))) +
        ' – ' +
        DateFormat('MMM d, yyyy').format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text('Weekly report'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF185FA5), Color(0xFF42A5F5)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('PREMIUM',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                    const Spacer(),
                    const Icon(Icons.picture_as_pdf_outlined,
                        color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? 'Care recipient',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(weekLabel,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (FamilyPlanStore.instance.plan.familyWeeklyVitalChartsUnlocked)
            _metricGrid(user)
          else
            const Text('Upgrade to Premium to unlock charts.'),
          const SizedBox(height: 16),
          _insightCard(
            'Medication adherence',
            _adherenceLabel(user),
            Icons.medication_rounded,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          _insightCard(
            'Activity trend',
            'Daily steps averaged 4,200 — stable vs last week',
            Icons.directions_walk_rounded,
            const Color(0xFF1B74E4),
          ),
          const SizedBox(height: 10),
          _insightCard(
            'BridgeCare recommendation',
            'Schedule a wellness check-in — vitals are within normal range.',
            Icons.lightbulb_rounded,
            const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF export — connect backend to enable download'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Export PDF report'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricGrid(LinkedUser? user) {
    final hr = user?.heartRateHistory.isNotEmpty == true
        ? user!.heartRateHistory.last.value
        : 72;
    final done = user?.reminders.where((r) => r.status == ReminderStatus.done).length ?? 0;
    final total = user?.reminders.length ?? 0;
    return Row(
      children: [
        Expanded(child: _metric('Heart rate', '$hr bpm', Icons.favorite_rounded, Colors.red)),
        const SizedBox(width: 10),
        Expanded(child: _metric('Tasks done', '$done/$total', Icons.task_alt_rounded, Colors.teal)),
        const SizedBox(width: 10),
        Expanded(
            child: _metric('Status', user?.healthStatus.label ?? 'Stable',
                Icons.check_circle_rounded, Colors.green)),
      ],
    );
  }

  static String _adherenceLabel(LinkedUser? user) {
    if (user == null || user.reminders.isEmpty) {
      return '92% on schedule this week';
    }
    final done = user.reminders.where((r) => r.status == ReminderStatus.done).length;
    final pct = ((done / user.reminders.length) * 100).round();
    return '$pct% on schedule this week';
  }

  Widget _metric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _insightCard(String title, String body, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
