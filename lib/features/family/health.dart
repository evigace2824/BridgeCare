import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../services/health_service.dart';
import '../../models/family_models.dart';
import '../../services/family_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'family_plan_store.dart';
import 'premium_spotlight.dart';
import '../../models/user_model.dart';
import '../premium/premium_plans_screen.dart';

// ─── Palette ──────────────────────────────────────────────────────────────────

class _Pal {
  static const blue = Color(0xFF185FA5);
  static const blueSoft = Color(0xFFE6F1FB);
  static const blueLight = Color(0xFFB5D4F4);
  static const red = Color(0xFFE24B4A);
  static const redSoft = Color(0xFFFCEBEB);
  static const green = Color(0xFF3B6D11);
  static const greenSoft = Color(0xFFEAF3DE);
  static const amber = Color(0xFF854F0B);
  static const amberSoft = Color(0xFFFAEEDA);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
  static const shadow = Color(0x10185FA5);
}

// ─── Entry point ──────────────────────────────────────────────────────────────

class FamilyHealthPage extends StatefulWidget {
  final LinkedUser? linkedUser;
  const FamilyHealthPage({super.key, required this.linkedUser});

  @override
  State<FamilyHealthPage> createState() => _FamilyHealthPageState();
}

class _FamilyHealthPageState extends State<FamilyHealthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.linkedUser?.healthStatus;
    final statusColor = status?.type == HealthStatusType.emergency
        ? _Pal.red
        : status?.type == HealthStatusType.warning
        ? _Pal.amber
        : _Pal.green;
    final statusBg = status?.type == HealthStatusType.emergency
        ? _Pal.redSoft
        : status?.type == HealthStatusType.warning
        ? _Pal.amberSoft
        : _Pal.greenSoft;

    return Stack(
      children: [
        Positioned(
          top: -40,
          left: -24,
          child: IgnorePointer(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _Pal.blue.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -40,
          bottom: 30,
          child: IgnorePointer(
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF24B6A8).withValues(alpha: 0.11),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.92),
                    const Color(0xFFEAF4FF).withValues(alpha: 0.9),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.linkedUser != null) ...[
                    Row(
                      children: [
                        _Avatar(name: widget.linkedUser!.fullName),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.linkedUser!.fullName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _Pal.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: statusColor,
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          status?.label ?? 'Normal',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (widget.linkedUser!.lastSeen != null)
                                    Text(
                                      'Seen ${_sinceLabel(widget.linkedUser!.lastSeen!)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: _Pal.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _PulseBadge(),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  TabBar(
                    controller: _tabCtrl,
                    labelColor: _Pal.blue,
                    unselectedLabelColor: _Pal.textSecondary,
                    indicatorColor: _Pal.blue,
                    indicatorWeight: 2.5,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.monitor_heart_rounded, size: 16),
                        text: 'Vitals',
                      ),
                      Tab(
                        icon: Icon(Icons.bar_chart_rounded, size: 16),
                        text: 'Report',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _VitalsTab(linkedUser: widget.linkedUser),
                  _ReportsTab(linkedUser: widget.linkedUser),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _sinceLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ─── Pulse badge ──────────────────────────────────────────────────────────────

class _PulseBadge extends StatefulWidget {
  @override
  State<_PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _a = Tween<double>(begin: 1.0, end: 0.35).animate(_c);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _Pal.greenSoft,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _a,
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _Pal.green,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          'Live',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _Pal.green,
          ),
        ),
      ],
    ),
  );
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2)
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: _Pal.blueSoft,
      borderRadius: BorderRadius.circular(21),
    ),
    alignment: Alignment.center,
    child: Text(
      initials,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _Pal.blue,
      ),
    ),
  );
}

// ─── Vitals Tab ───────────────────────────────────────────────────────────────

enum _VitalStatus { normal, warning, emergency, unknown }

class _VitalsTab extends StatefulWidget {
  final LinkedUser? linkedUser;
  const _VitalsTab({required this.linkedUser});
  @override
  State<_VitalsTab> createState() => _VitalsTabState();
}

class _VitalsTabState extends State<_VitalsTab> {
  List<VitalReading> _hr = [];
  List<VitalReading> _bp = [];
  bool _loading = true;
  DateTime? _loadedAt;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final uid =
          widget.linkedUser?.uid ??
          Supabase.instance.client.auth.currentUser?.id ??
          '';
      if (uid.isNotEmpty) {
        final svc = HealthService();
        final hrRaw = await svc.getHeartRates(uid);
        final bpRaw = await svc.getBloodPressures(uid);
        if (mounted)
          setState(() {
            _hr = hrRaw
                .map(
                  (e) => VitalReading(
                    value: e.value.toDouble(),
                    timestamp: e.timestamp,
                    unit: 'bpm',
                  ),
                )
                .toList();
            _bp = bpRaw
                .map(
                  (e) => VitalReading(
                    value: e.value.toDouble(),
                    secondaryValue: e.secondaryValue?.toDouble(),
                    timestamp: e.timestamp,
                    unit: 'mmHg',
                  ),
                )
                .toList();
            _loading = false;
            _loadedAt = DateTime.now();
          });
      } else {
        _mockData();
      }
    } catch (_) {
      _mockData();
    }
  }

  void _mockData() {
    final now = DateTime.now();
    if (mounted)
      setState(() {
        _hr = List.generate(
          7,
          (i) => VitalReading(
            value: 68.0 + (i % 3) * 4,
            timestamp: now.subtract(Duration(days: 6 - i)),
            unit: 'bpm',
          ),
        );
        _bp = List.generate(
          7,
          (i) => VitalReading(
            value: 118.0 + (i % 3) * 6,
            secondaryValue: 76.0 + (i % 2) * 4,
            timestamp: now.subtract(Duration(days: 6 - i)),
            unit: 'mmHg',
          ),
        );
        _loading = false;
        _loadedAt = DateTime.now();
      });
  }

  VitalReading? get _latestHR => _hr.isNotEmpty ? _hr.last : null;
  _VitalStatus _hrStatus(double? v) {
    if (v == null) return _VitalStatus.unknown;
    if (v < 50 || v > 120) return _VitalStatus.emergency;
    if (v < 60 || v > 100) return _VitalStatus.warning;
    return _VitalStatus.normal;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
        child: CircularProgressIndicator(color: _Pal.blue, strokeWidth: 2),
      );

    final hrStatus = _hrStatus(_latestHR?.value);

    return RefreshIndicator(
      color: _Pal.blue,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          _SectionLabel('Current Vitals'),
          Row(
            children: [
              Expanded(
                child: _VitalCard(
                  label: 'Heart Rate',
                  value: _latestHR != null
                      ? _latestHR!.value.toStringAsFixed(0)
                      : '—',
                  unit: 'bpm',
                  icon: Icons.favorite_rounded,
                  iconColor: _Pal.red,
                  iconBg: _Pal.redSoft,
                  status: hrStatus,
                  timestamp: _latestHR?.timestamp,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_hr.isNotEmpty) ...[
            _SectionLabel('Heart Rate — 7 Day Trend'),
            _ChartCard(
              readings: _hr,
              color: _Pal.red,
              unit: 'bpm',
              normalMin: 60,
              normalMax: 100,
            ),
            const SizedBox(height: 16),
          ],

          const FamilyPremiumSpotlight(
            variant: SpotlightVariant.large,
            angle: SpotlightAngle.health,
          ),
          const SizedBox(height: 16),

          _SectionLabel('Normal Ranges'),
          _Card(
            child: Column(
              children: [
                _RangeRow(
                  icon: Icons.favorite_rounded,
                  iconColor: _Pal.red,
                  iconBg: _Pal.redSoft,
                  title: 'Heart Rate',
                  range: '60 – 100 bpm',
                  current: _latestHR?.value,
                  min: 60,
                  max: 100,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_loadedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Last refreshed at ${DateFormat('HH:mm').format(_loadedAt!)} · Pull down to refresh',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: _Pal.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Reports Tab ──────────────────────────────────────────────────────────────

class _ReportsTab extends StatefulWidget {
  final LinkedUser? linkedUser;
  const _ReportsTab({required this.linkedUser});
  @override
  State<_ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<_ReportsTab> {
  WeeklyReport? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final uid = widget.linkedUser?.uid ?? '';
      final svc = FamilyService();
      final report = uid.isNotEmpty
          ? await svc.fetchWeeklyReport(uid)
          : _mockReport();
      if (mounted)
        setState(() {
          _report = report;
          _loading = false;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _report = _mockReport();
          _loading = false;
        });
    }
  }

  WeeklyReport _mockReport() {
    final now = DateTime.now();
    return WeeklyReport(
      heartRateData: List.generate(
        7,
        (i) => VitalReading(
          value: 65.0 + (i % 4) * 5,
          timestamp: now.subtract(Duration(days: 6 - i)),
        ),
      ),
      bloodPressureData: List.generate(
        7,
        (i) => VitalReading(
          value: 115.0 + (i % 3) * 7,
          secondaryValue: 75.0 + (i % 2) * 5,
          timestamp: now.subtract(Duration(days: 6 - i)),
        ),
      ),
      missedMedicationCount: 3,
      takenMedicationCount: 11,
      missedAppointmentsCount: 1,
      medications: const [
        MedicationSummary(name: 'Aspirin 100mg', takenCount: 5, missedCount: 2),
        MedicationSummary(
          name: 'Metformin 500mg',
          takenCount: 6,
          missedCount: 1,
        ),
        MedicationSummary(
          name: 'Lisinopril 10mg',
          takenCount: 7,
          missedCount: 0,
        ),
      ],
    );
  }

  void _openPlans() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PremiumPlansScreen(role: UserRole.family),
      ),
    );
  }

  Widget _reportsLockedTrendGate() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: _Pal.blue.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Weekly graphs (Premium)',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _Pal.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Free summarizes the week; Premium unlocks interactive trend charts & reports.',
            style: TextStyle(
              fontSize: 13,
              color: _Pal.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openPlans,
              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
              label: const Text('Upgrade for charts'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Center(
        child: CircularProgressIndicator(color: _Pal.blue, strokeWidth: 2),
      );
    final r = _report!;
    final total = r.missedMedicationCount + r.takenMedicationCount;
    final adherence = total > 0 ? r.takenMedicationCount / total : 0.0;
    final weekStart = DateTime.now().subtract(const Duration(days: 7));

    return RefreshIndicator(
      color: _Pal.blue,
      onRefresh: _load,
      child: AnimatedBuilder(
        animation: FamilyPlanStore.instance,
        builder: (context, _) {
          final charts =
              FamilyPlanStore.instance.plan.familyWeeklyVitalChartsUnlocked;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: [
              _Card(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _Pal.blueSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: _Pal.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Weekly Health Report',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _Pal.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _Pal.textSecondary,
                            ),
                          ),
                          if (!charts) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Summaries only on Free — upgrade unlocks trend graphs.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _Pal.blue.withValues(alpha: 0.82),
                                height: 1.25,
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

              _SectionLabel('At a Glance'),
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      value: '${(adherence * 100).round()}%',
                      label: 'Adherence',
                      color: adherence >= 0.8
                          ? _Pal.green
                          : adherence >= 0.6
                          ? _Pal.amber
                          : _Pal.red,
                      bg: adherence >= 0.8
                          ? _Pal.greenSoft
                          : adherence >= 0.6
                          ? _Pal.amberSoft
                          : _Pal.redSoft,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiCard(
                      value: '${r.missedMedicationCount}',
                      label: 'Missed doses',
                      color: r.missedMedicationCount == 0
                          ? _Pal.green
                          : _Pal.red,
                      bg: r.missedMedicationCount == 0
                          ? _Pal.greenSoft
                          : _Pal.redSoft,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiCard(
                      value: '${r.missedAppointmentsCount}',
                      label: 'Missed appts.',
                      color: r.missedAppointmentsCount == 0
                          ? _Pal.green
                          : _Pal.amber,
                      bg: r.missedAppointmentsCount == 0
                          ? _Pal.greenSoft
                          : _Pal.amberSoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (r.heartRateData.isNotEmpty) ...[
                _SectionLabel('Heart Rate — This Week'),
                if (charts)
                  _Card(
                    child: SizedBox(
                      height: 160,
                      child: _BarChart(
                        readings: r.heartRateData,
                        color: _Pal.red,
                        unit: 'bpm',
                        normalMin: 60,
                        normalMax: 100,
                      ),
                    ),
                  )
                else
                  _reportsLockedTrendGate(),
                const SizedBox(height: 16),
              ],

              _SectionLabel('Medication Tracking'),
              if (r.medications.isEmpty)
                _Card(
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'No medication data recorded this week.',
                        style: TextStyle(
                          color: _Pal.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...r.medications.map(_medRow),
            ],
          );
        },
      ),
    );
  }

  Widget _medRow(MedicationSummary m) {
    final pct = m.total > 0 ? m.takenCount / m.total : 0.0;
    final statusColor = pct >= 0.8
        ? _Pal.green
        : pct >= 0.5
        ? _Pal.amber
        : _Pal.red;
    return _Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _Pal.blueSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  size: 16,
                  color: _Pal.blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  m.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _Pal.textPrimary,
                  ),
                ),
              ),
              _Pill(
                '${m.takenCount} taken',
                color: _Pal.green,
                bg: _Pal.greenSoft,
              ),
              if (m.missedCount > 0) ...[
                const SizedBox(width: 5),
                _Pill(
                  '${m.missedCount} missed',
                  color: _Pal.red,
                  bg: _Pal.redSoft,
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 7,
                    backgroundColor: _Pal.border,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(pct * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared layout helpers ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 2),
    child: Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: _Pal.blue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _Pal.blue,
            letterSpacing: 0.1,
          ),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  const _Card({required this.child, this.margin});
  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withValues(alpha: 0.97), const Color(0xFFF2F7FC)],
      ),
      border: Border.all(
        color: _Pal.border.withValues(alpha: 0.75),
        width: 0.8,
      ),
      boxShadow: const [
        BoxShadow(color: _Pal.shadow, blurRadius: 12, offset: Offset(0, 4)),
      ],
    ),
    child: Padding(padding: const EdgeInsets.all(14), child: child),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _Pill(this.label, {required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _Pal.blueSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _Pal.blueLight, width: 0.5),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline_rounded, color: _Pal.blue, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF0C447C),
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Vital card ───────────────────────────────────────────────────────────────

class _VitalCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color iconColor, iconBg;
  final _VitalStatus status;
  final DateTime? timestamp;

  const _VitalCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.status,
    this.timestamp,
  });

  Color get _sColor => switch (status) {
    _VitalStatus.normal => _Pal.green,
    _VitalStatus.warning => _Pal.amber,
    _VitalStatus.emergency => _Pal.red,
    _VitalStatus.unknown => _Pal.textSecondary,
  };
  Color get _sBg => switch (status) {
    _VitalStatus.normal => _Pal.greenSoft,
    _VitalStatus.warning => _Pal.amberSoft,
    _VitalStatus.emergency => _Pal.redSoft,
    _VitalStatus.unknown => const Color(0xFFF4F4F4),
  };
  String get _sLabel => switch (status) {
    _VitalStatus.normal => 'Normal',
    _VitalStatus.warning => 'Warning',
    _VitalStatus.emergency => 'Emergency',
    _VitalStatus.unknown => 'No data',
  };

  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 15),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _sBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _sLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _sColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: _Pal.textSecondary),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: status == _VitalStatus.emergency
                ? _Pal.red
                : status == _VitalStatus.warning
                ? _Pal.amber
                : _Pal.textPrimary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          unit,
          style: const TextStyle(fontSize: 10, color: _Pal.textSecondary),
        ),
        if (timestamp != null) ...[
          const SizedBox(height: 6),
          Text(
            DateFormat('MMM d, HH:mm').format(timestamp!),
            style: const TextStyle(fontSize: 10, color: _Pal.textSecondary),
          ),
        ],
      ],
    ),
  );
}

// ─── KPI tile ─────────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String value, label;
  final Color color, bg;
  const _KpiCard({
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: _Pal.textSecondary),
        ),
      ],
    ),
  );
}

// ─── Range row with mini progress bar ────────────────────────────────────────

class _RangeRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, range;
  final double? current, min, max;
  const _RangeRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.range,
    this.current,
    required this.min,
    required this.max,
  });
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: iconColor, size: 14),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: _Pal.textSecondary),
            ),
            if (current != null) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value:
                      ((current! - (min! - 20)) / ((max! + 20) - (min! - 20)))
                          .clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: _Pal.border,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(width: 10),
      Text(
        range,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: iconColor,
        ),
      ),
    ],
  );
}

// ─── Chart card (sparkline + stats) ──────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  final List<VitalReading> readings;
  final Color color;
  final String unit;
  final double normalMin, normalMax;
  final bool showSecondary;
  const _ChartCard({
    required this.readings,
    required this.color,
    required this.unit,
    required this.normalMin,
    required this.normalMax,
    this.showSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final vals = readings.map((r) => r.value).toList();
    final minV = vals.reduce(math.min);
    final maxV = vals.reduce(math.max);
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    return _Card(
      child: Column(
        children: [
          SizedBox(
            height: 110,
            child: _SmoothedLineChart(
              readings: readings,
              color: color,
              showSecondary: showSecondary,
              normalMin: normalMin,
              normalMax: normalMax,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 0.5,
            color: _Pal.border,
            margin: const EdgeInsets.only(bottom: 12),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCell('Min', '${minV.toStringAsFixed(0)} $unit'),
              _StatCell('Avg', '${avg.toStringAsFixed(0)} $unit'),
              _StatCell('Max', '${maxV.toStringAsFixed(0)} $unit'),
              _StatCell('Days', '${readings.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label, value;
  const _StatCell(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _Pal.textPrimary,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: _Pal.textSecondary),
      ),
    ],
  );
}

// ─── Smoothed bezier line chart with normal-range band ───────────────────────

class _SmoothedLineChart extends StatelessWidget {
  final List<VitalReading> readings;
  final Color color;
  final bool showSecondary;
  final double normalMin, normalMax;
  const _SmoothedLineChart({
    required this.readings,
    required this.color,
    required this.showSecondary,
    required this.normalMin,
    required this.normalMax,
  });
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SmoothedLinePainter(
      readings: readings,
      color: color,
      showSecondary: showSecondary,
      normalMin: normalMin,
      normalMax: normalMax,
    ),
    child: const SizedBox.expand(),
  );
}

class _SmoothedLinePainter extends CustomPainter {
  final List<VitalReading> readings;
  final Color color;
  final bool showSecondary;
  final double normalMin, normalMax;
  _SmoothedLinePainter({
    required this.readings,
    required this.color,
    required this.showSecondary,
    required this.normalMin,
    required this.normalMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.length < 2) return;
    final values = readings.map((r) => r.value).toList();
    final secValues = showSecondary
        ? readings.map((r) => r.secondaryValue ?? 0.0).toList()
        : <double>[];
    final allValues = [...values, if (showSecondary) ...secValues];
    final dataMin = allValues.reduce(math.min) - 8;
    final dataMax = allValues.reduce(math.max) + 8;
    final range = (dataMax - dataMin).clamp(1.0, double.infinity);
    const labelH = 18.0;
    final chartH = size.height - labelH;

    double xOf(int i) => (i / (readings.length - 1)) * size.width;
    double yOf(double v) => chartH - ((v - dataMin) / range) * chartH;

    // Normal band
    final bandY1 = yOf(normalMax.clamp(dataMin, dataMax));
    final bandY2 = yOf(normalMin.clamp(dataMin, dataMax));
    canvas.drawRect(
      Rect.fromLTRB(0, bandY1, size.width, bandY2),
      Paint()..color = color.withAlpha(15),
    );
    _drawDashed(
      canvas,
      Offset(0, bandY1),
      Offset(size.width, bandY1),
      Paint()
        ..color = color.withAlpha(55)
        ..strokeWidth = 1,
    );

    Path smoothPath(List<double> vals) {
      final p = Path();
      for (int i = 0; i < vals.length; i++) {
        final x = xOf(i);
        final y = yOf(vals[i]);
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          final px = xOf(i - 1);
          final py = yOf(vals[i - 1]);
          final cpx = (px + x) / 2;
          p.cubicTo(cpx, py, cpx, y, x, y);
        }
      }
      return p;
    }

    void drawFill(List<double> vals, Color c) {
      final fill = smoothPath(vals);
      fill.lineTo(size.width, chartH);
      fill.lineTo(0, chartH);
      fill.close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.withAlpha(55), c.withAlpha(0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)),
      );
    }

    void drawStroke(List<double> vals, Color c) {
      canvas.drawPath(
        smoothPath(vals),
        Paint()
          ..color = c
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drawFill(values, color);
    if (showSecondary && secValues.isNotEmpty)
      drawFill(secValues, color.withAlpha(80));
    drawStroke(values, color);
    if (showSecondary && secValues.isNotEmpty)
      drawStroke(secValues, color.withAlpha(160));

    final dotFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotRing = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (int i = 0; i < values.length; i++) {
      final x = xOf(i);
      final y = yOf(values[i]);
      canvas.drawCircle(Offset(x, y), 5, dotRing);
      canvas.drawCircle(Offset(x, y), 3.5, dotFill);
    }

    final tp = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i < readings.length; i++) {
      final x = xOf(i);
      tp.text = TextSpan(
        text: DateFormat('E').format(readings[i].timestamp).substring(0, 1),
        style: TextStyle(
          fontSize: 9,
          color: color.withAlpha(140),
          fontWeight: FontWeight.w600,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartH + 4));
    }
  }

  void _drawDashed(Canvas c, Offset s, Offset e, Paint p) {
    const dash = 5.0, gap = 4.0;
    final total = (e.dx - s.dx).abs();
    double drawn = 0;
    while (drawn < total) {
      c.drawLine(
        Offset(s.dx + drawn, s.dy),
        Offset(s.dx + math.min(drawn + dash, total), e.dy),
        p,
      );
      drawn += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}

// ─── Bar chart (Reports tab) ──────────────────────────────────────────────────

class _BarChart extends StatelessWidget {
  final List<VitalReading> readings;
  final Color color;
  final String unit;
  final double normalMin, normalMax;
  const _BarChart({
    required this.readings,
    required this.color,
    required this.unit,
    required this.normalMin,
    required this.normalMax,
  });
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BarChartPainter(
      readings: readings,
      color: color,
      normalMax: normalMax,
    ),
    child: const SizedBox.expand(),
  );
}

class _BarChartPainter extends CustomPainter {
  final List<VitalReading> readings;
  final Color color;
  final double normalMax;
  _BarChartPainter({
    required this.readings,
    required this.color,
    required this.normalMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;
    final values = readings.map((r) => r.value).toList();
    final maxV = (values.reduce(math.max) * 1.18).clamp(1.0, double.infinity);
    const labelH = 20.0;
    final chartH = size.height - labelH;
    final slot = size.width / readings.length;
    final bw = slot * 0.5;
    final off = (slot - bw) / 2;
    final tp = TextPainter(textDirection: ui.TextDirection.ltr);

    // Normal-max guideline
    final gy = chartH - (normalMax / maxV) * chartH;
    canvas.drawLine(
      Offset(0, gy),
      Offset(size.width, gy),
      Paint()
        ..color = color.withAlpha(50)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );

    for (int i = 0; i < readings.length; i++) {
      final x = i * slot + off;
      final bh = (values[i] / maxV) * chartH;
      final y = chartH - bh;
      final isHigh = values[i] > normalMax;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, bw, chartH),
          const Radius.circular(4),
        ),
        Paint()..color = color.withAlpha(15),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, bw, bh),
          const Radius.circular(4),
        ),
        Paint()..color = isHigh ? color.withAlpha(200) : color,
      );

      if (bh > 18) {
        tp.text = TextSpan(
          text: values[i].toStringAsFixed(0),
          style: TextStyle(
            fontSize: 8,
            color: color.withAlpha(180),
            fontWeight: FontWeight.w700,
          ),
        );
        tp.layout();
        tp.paint(canvas, Offset(x + bw / 2 - tp.width / 2, y - 12));
      }

      tp.text = TextSpan(
        text: DateFormat('E').format(readings[i].timestamp).substring(0, 1),
        style: TextStyle(
          fontSize: 9,
          color: color.withAlpha(140),
          fontWeight: FontWeight.w600,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(x + bw / 2 - tp.width / 2, chartH + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}
