import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../data/patient_models.dart';
import '../data/patient_store.dart';

/// "Today at a glance" — horizontal strip of vivid stat cards above the fold.
/// Shows: heart rate, reminders progress, mood streak, daily routine progress,
/// and steps (placeholder when wearable not connected).
class TodayKpiStrip extends StatelessWidget {
  const TodayKpiStrip({
    super.key,
    required this.store,
    required this.onOpenHealth,
    required this.onOpenReminders,
  });

  final PatientStore store;
  final VoidCallback onOpenHealth;
  final VoidCallback onOpenReminders;

  @override
  Widget build(BuildContext context) {
    final hr = store.vitals.heartRate;
    final hrStatus = store.healthStatus;
    final pendingMeds = store.pendingMedicationCount;
    final totalToday = store.todayMedicationTotal;
    final doneMeds = store.todayMedicationDone;

    final routineDone = store.todayRoutine.where((t) => t.completed).length;
    final routineTotal = store.todayRoutine.length;

    final mood = store.dailyCheckInMood;
    final String moodLabel;
    final Color moodColor;
    final IconData moodIcon;
    switch (mood) {
      case DailyCheckInMood.good:
        moodLabel = 'Feeling good';
        moodColor = const Color(0xFF2F9E44);
        moodIcon = Icons.sentiment_very_satisfied_rounded;
        break;
      case DailyCheckInMood.okay:
        moodLabel = 'Feeling okay';
        moodColor = const Color(0xFFF08C00);
        moodIcon = Icons.sentiment_satisfied_rounded;
        break;
      case DailyCheckInMood.unwell:
        moodLabel = 'Not great';
        moodColor = const Color(0xFFD63031);
        moodIcon = Icons.sentiment_dissatisfied_rounded;
        break;
      case null:
        moodLabel = 'Tap to check in';
        moodColor = AppColors.primary;
        moodIcon = Icons.mood_rounded;
        break;
    }

    final stepsValue = store.wearableLastSteps;
    final spo2 = store.wearableLastSpO2;

    return SizedBox(
      height: 116,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        children: [
          _KpiCard(
            label: context.tr('Heart rate'),
            value: hr != null ? '$hr' : '--',
            unit: 'bpm',
            icon: Icons.favorite_rounded,
            gradient: _statusGradient(hrStatus),
            footer: _statusFooter(context, hrStatus),
            onTap: onOpenHealth,
          ),
          const SizedBox(width: 10),
          _KpiCard(
            label: context.tr('Reminders'),
            value: '$doneMeds/$totalToday',
            unit: context.tr('today'),
            icon: Icons.medication_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
            ),
            footer: pendingMeds == 0
                ? context.tr('All done')
                : context.tr('{count} left', {'count': '$pendingMeds'}),
            progress: totalToday == 0 ? null : doneMeds / totalToday,
            onTap: onOpenReminders,
          ),
          const SizedBox(width: 10),
          _KpiCard(
            label: context.tr('Mood'),
            value: '',
            unit: '',
            icon: moodIcon,
            gradient: LinearGradient(colors: [moodColor, moodColor.withValues(alpha: 0.75)]),
            customCenter: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                context.tr(moodLabel),
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            footer: context.tr('Daily check-in'),
          ),
          const SizedBox(width: 10),
          _KpiCard(
            label: context.tr('Routine'),
            value: '$routineDone/$routineTotal',
            unit: context.tr('done'),
            icon: Icons.task_alt_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF0891B2), Color(0xFF22C7E5)],
            ),
            footer: routineDone == routineTotal
                ? context.tr('All set')
                : context.tr('Keep going'),
            progress: routineTotal == 0 ? null : routineDone / routineTotal,
          ),
          const SizedBox(width: 10),
          _KpiCard(
            label: context.tr('Steps'),
            value: stepsValue != null ? '$stepsValue' : '--',
            unit: context.tr('today'),
            icon: Icons.directions_walk_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
            ),
            footer: stepsValue != null
                ? context.tr('Connected wearable')
                : context.tr('Connect wearable'),
            onTap: onOpenHealth,
          ),
          const SizedBox(width: 10),
          _KpiCard(
            label: context.tr('Oxygen'),
            value: spo2 != null ? spo2.toStringAsFixed(0) : '--',
            unit: '% SpO₂',
            icon: Icons.bubble_chart_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF3B5BDB), Color(0xFF6080F0)],
            ),
            footer: spo2 != null
                ? context.tr('Stable')
                : context.tr('Tap to record'),
            onTap: onOpenHealth,
          ),
        ],
      ),
    );
  }

  LinearGradient _statusGradient(HealthStatus s) {
    switch (s) {
      case HealthStatus.normal:
        return const LinearGradient(colors: [Color(0xFF2F9E44), Color(0xFF51CF66)]);
      case HealthStatus.warning:
        return const LinearGradient(colors: [Color(0xFFF08C00), Color(0xFFFFB446)]);
      case HealthStatus.emergency:
        return const LinearGradient(colors: [Color(0xFFD63031), Color(0xFFFF6B6B)]);
      case HealthStatus.unknown:
        return const LinearGradient(colors: [Color(0xFF3B5BDB), Color(0xFF6080F0)]);
    }
  }

  String _statusFooter(BuildContext context, HealthStatus s) {
    switch (s) {
      case HealthStatus.normal:
        return context.tr('Normal');
      case HealthStatus.warning:
        return context.tr('Watch closely');
      case HealthStatus.emergency:
        return context.tr('Critical');
      case HealthStatus.unknown:
        return context.tr('Tap to record');
    }
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.gradient,
    required this.footer,
    this.onTap,
    this.progress,
    this.customCenter,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final LinearGradient gradient;
  final String footer;
  final VoidCallback? onTap;
  final double? progress;
  final Widget? customCenter;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 148,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient.colors.last.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (customCenter != null)
                customCenter!
              else
                RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: -0.6,
                        ),
                      ),
                      if (unit.isNotEmpty)
                        TextSpan(
                          text: '  $unit',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              const Spacer(),
              if (progress != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                footer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
