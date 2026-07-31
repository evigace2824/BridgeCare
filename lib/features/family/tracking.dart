import 'package:flutter/material.dart';

import '../../models/family_models.dart';

class FamilyTrackingPage extends StatefulWidget {
  const FamilyTrackingPage({super.key, required this.linkedUser});

  final LinkedUser? linkedUser;

  @override
  State<FamilyTrackingPage> createState() => _FamilyTrackingPageState();
}

class _FamilyTrackingPageState extends State<FamilyTrackingPage> {
  static const _primary = Color(0xFF1976D2);
  static const _green = Color(0xFF4CAF50);
  static const _orange = Color(0xFFFF9800);
  static const _red = Color(0xFFE53935);
  static const _shadow = Color(0x121976D2);

  int _selectedWindow = 0;
  bool _showRiskOnly = false;

  String get _windowLabel => switch (_selectedWindow) {
        0 => 'Today',
        1 => 'This week',
        _ => 'This month',
      };

  @override
  Widget build(BuildContext context) {
    final user = widget.linkedUser;
    final heartRate = (user != null && user.heartRateHistory.isNotEmpty)
        ? user.heartRateHistory.last.value
        : 72.0;
    final riskLevel = heartRate > 100 ? 'High' : heartRate < 60 ? 'Low' : 'Normal';
    final riskColor = riskLevel == 'High'
        ? _red
        : riskLevel == 'Low'
            ? _orange
            : _green;

    return Stack(
      children: [
        Positioned(
          left: -26,
          top: -34,
          child: IgnorePointer(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primary.withValues(alpha: 0.13),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -44,
          bottom: 40,
          child: IgnorePointer(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF24B6A8).withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.96),
                const Color(0xFFEAF4FF).withValues(alpha: 0.93),
              ],
            ),
            border: Border.all(color: _primary.withValues(alpha: 0.18)),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_graph_rounded, size: 18, color: Color(0xFF1565C0)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Risk timeline updates continuously based on latest vitals and activity.',
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF35566F),
                    height: 1.26,
                  ),
                ),
              ),
            ],
          ),
        ),
        _card(
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _primary.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.insights_rounded, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tracking Insights',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user?.fullName ?? 'Patient'} • $_windowLabel',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                child: ChoiceChip(
                  label: Text(i == 0 ? 'Today' : i == 1 ? 'Week' : 'Month'),
                  selected: _selectedWindow == i,
                  onSelected: (_) => setState(() => _selectedWindow = i),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show risk events only'),
          value: _showRiskOnly,
          onChanged: (v) => setState(() => _showRiskOnly = v),
        ),
        const SizedBox(height: 8),
        _sectionLabel('Key Metrics'),
        Row(
          children: [
            Expanded(
              child: _metricTile(
                icon: Icons.favorite_rounded,
                label: 'Heart Rate',
                value: '${heartRate.round()} bpm',
                color: _red,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile(
                icon: Icons.shield_rounded,
                label: 'Risk Level',
                value: riskLevel,
                color: riskColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _sectionLabel('Timeline'),
        ..._events()
            .where((e) => !_showRiskOnly || e.isRisk)
            .map(
              (e) => _card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: e.color.withAlpha(18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(e.icon, color: e.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(e.subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                    Text(e.time, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
            ),
      ],
    )]);
  }

  List<_TrackingEvent> _events() {
    return const [
      _TrackingEvent(
        icon: Icons.location_on_rounded,
        title: 'Entered safe zone',
        subtitle: 'Patient returned home area',
        time: '08:42',
        color: _green,
        isRisk: false,
      ),
      _TrackingEvent(
        icon: Icons.notification_important_rounded,
        title: 'Medication overdue',
        subtitle: 'Morning reminder delayed 25m',
        time: '09:15',
        color: _orange,
        isRisk: true,
      ),
      _TrackingEvent(
        icon: Icons.directions_walk_rounded,
        title: 'Movement detected',
        subtitle: '3,124 steps by midday',
        time: '12:03',
        color: _primary,
        isRisk: false,
      ),
      _TrackingEvent(
        icon: Icons.warning_amber_rounded,
        title: 'Elevated heart rate',
        subtitle: '102 bpm recorded after activity',
        time: '14:20',
        color: _red,
        isRisk: true,
      ),
    ];
  }

  Widget _metricTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1565C0)),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsetsGeometry? margin}) {
    return Container(
      margin: margin,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.97),
            const Color(0xFFF2F7FC),
          ],
        ),
        border: Border.all(color: _primary.withValues(alpha: 0.10)),
        boxShadow: const [BoxShadow(color: _shadow, blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

class _TrackingEvent {
  const _TrackingEvent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
    required this.isRisk,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;
  final bool isRisk;
}
