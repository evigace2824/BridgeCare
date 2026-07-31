import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/family_models.dart';
import '../../services/family_service.dart';
import 'family_plan_store.dart';
import 'subscription_page_clean.dart';

class FamilyReportPage extends StatefulWidget {
  const FamilyReportPage({super.key, required this.linkedUser});

  final LinkedUser? linkedUser;

  @override
  State<FamilyReportPage> createState() => _FamilyReportPageState();
}

class _FamilyReportPageState extends State<FamilyReportPage> {
  static const _primary = Color(0xFF1976D2);
  static const _red = Color(0xFFE53935);
  static const _green = Color(0xFF4CAF50);
  static const _orange = Color(0xFFFF9800);
  static const _shadow = Color(0x121976D2);

  WeeklyReport? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = widget.linkedUser?.uid ?? '';
      final svc = FamilyService();
      final report = uid.isNotEmpty ? await svc.fetchWeeklyReport(uid) : _mockReport();
      if (mounted) {
        setState(() {
          _report = report;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _report = _mockReport();
          _loading = false;
        });
      }
    }
  }

  WeeklyReport _mockReport() {
    final now = DateTime.now();
    return WeeklyReport(
      heartRateData: List.generate(
        7,
        (i) => VitalReading(
          value: 65 + (i % 4) * 5.0,
          timestamp: now.subtract(Duration(days: 6 - i)),
        ),
      ),
      bloodPressureData: List.generate(
        7,
        (i) => VitalReading(
          value: 115 + (i % 3) * 7.0,
          secondaryValue: 75 + (i % 2) * 5.0,
          timestamp: now.subtract(Duration(days: 6 - i)),
        ),
      ),
      missedMedicationCount: 3,
      takenMedicationCount: 11,
      missedAppointmentsCount: 1,
      medications: const [
        MedicationSummary(name: 'Aspirin 100mg', takenCount: 5, missedCount: 2),
        MedicationSummary(name: 'Metformin 500mg', takenCount: 6, missedCount: 1),
      ],
    );
  }

  void _openPlans() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SubscriptionPage(
          currentPlan: FamilyPlanStore.instance.plan,
          onPlanSelected: FamilyPlanStore.instance.setPlan,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _primary));
    }
    final r = _report!;
    return AnimatedBuilder(
      animation: FamilyPlanStore.instance,
      builder: (context, _) {
        final tier = FamilyPlanStore.instance.plan;
        final charts = tier.familyWeeklyVitalChartsUnlocked;
        return Stack(
          children: [
            Positioned(
              top: -46,
              left: -30,
              child: IgnorePointer(
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primary.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -44,
              bottom: 34,
              child: IgnorePointer(
                child: Container(
                  width: 230,
                  height: 230,
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
            SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                    Icon(Icons.ssid_chart_rounded, size: 18, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Weekly trend report with adherence and reminders at a glance.',
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
                    const Icon(Icons.bar_chart_rounded, color: _primary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weekly Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            '${DateFormat('MMM d').format(DateTime.now().subtract(const Duration(days: 7)))} – ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                          if (!charts) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Free shows summaries · Pro unlocks weekly trend charts',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _primary.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (r.heartRateData.isNotEmpty) ...[
                _sectionLabel('Heart Rate — This Week'),
                if (charts)
                  _card(
                    child: SizedBox(
                      height: 140,
                      child: _BarChart(readings: r.heartRateData, color: _red),
                    ),
                  )
                else
                  _chartsLockedCard(body: 'See heart‑rate highs and lows for each day this week.'),
                const SizedBox(height: 14),
              ],
              if (r.bloodPressureData.isNotEmpty) ...[
                _sectionLabel('Blood Pressure — This Week'),
                if (charts)
                  _card(
                    child: SizedBox(
                      height: 140,
                      child: _BarChart(readings: r.bloodPressureData, color: _primary),
                    ),
                  )
                else
                  _chartsLockedCard(body: 'BP trends help you spot drifting readings before appointments.'),
                const SizedBox(height: 14),
              ],
              _sectionLabel('Missed Reminders'),
              Row(
                children: [
                  _summaryTile(Icons.medication_rounded, 'Medication', r.missedMedicationCount, _red),
                  const SizedBox(width: 12),
                  _summaryTile(Icons.calendar_today_rounded, 'Appointments', r.missedAppointmentsCount, _orange),
                ],
              ),
              const SizedBox(height: 14),
              _sectionLabel('Medication Tracking'),
              if (r.medications.isEmpty)
                _card(
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'No medication data.',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                      ),
                    ),
                  ),
                )
              else
                Column(children: r.medications.map(_medRow).toList()),
            ],
          ),
        )]);
      },
    );
  }

  Widget _chartsLockedCard({required String body}) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: _primary.withValues(alpha: 0.85)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Trend charts (Pro)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF1A1A2E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.35)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openPlans,
              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
              label: const Text('Unlock with Pro or Premium'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
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
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 2),
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

  Widget _summaryTile(IconData icon, String label, int value, Color color) => Expanded(
        child: _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 10),
              Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      );

  Widget _medRow(MedicationSummary m) {
    final total = m.takenCount + m.missedCount;
    final pct = total > 0 ? m.takenCount / total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: _shadow, blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              _pill('${m.takenCount} taken', _green),
              const SizedBox(width: 6),
              _pill('${m.missedCount} missed', _red),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: _red.withAlpha(30),
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      );
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.readings, required this.color});

  final List<VitalReading> readings;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _BarChartPainter(readings: readings, color: color),
        child: const SizedBox.expand(),
      );
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.readings, required this.color});

  final List<VitalReading> readings;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;
    final values = readings.map((r) => r.value).toList();
    final maxV = values.reduce((a, b) => a > b ? a : b) * 1.15;
    final bw = (size.width / readings.length) * 0.55;
    final gap = (size.width / readings.length) * 0.45;
    final labelH = 22.0;
    final chartH = size.height - labelH;

    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final bgPaint = Paint()
      ..color = color.withAlpha(20)
      ..style = PaintingStyle.fill;
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);

    for (var i = 0; i < readings.length; i++) {
      final x = i * (bw + gap) + gap / 2;
      final bh = (values[i] / maxV) * chartH;
      final y = chartH - bh;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 0, bw, chartH), const Radius.circular(4)),
        bgPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, bw, bh), const Radius.circular(4)),
        barPaint,
      );
      tp.text = TextSpan(
        text: DateFormat('E').format(readings[i].timestamp),
        style: TextStyle(fontSize: 9, color: color.withAlpha(150), fontWeight: FontWeight.w600),
      );
      tp.layout();
      tp.paint(canvas, Offset(x + bw / 2 - tp.width / 2, chartH + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}
