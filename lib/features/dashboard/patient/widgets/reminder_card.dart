import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../widgets/carebridge/care_bridge_card.dart';
import '../data/patient_models.dart';

export '../data/patient_models.dart' show ReminderKind, ReminderState;

/// Single today's-reminder card with Done / Snooze actions, used on Home and
/// Reminders tabs. Big icon, large legible time, single-tap action buttons.
///
/// In v1 [onDone] / [onSnooze] simply mutate local state passed by the parent
/// (mock data). In v2 they'll write to a `reminders` Supabase table and
/// trigger the 12-hour escalation logic from the spec's Section 7.2.
class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.kind,
    required this.title,
    required this.kindLabel,
    required this.timeLabel,
    required this.state,
    required this.onDone,
    required this.onSnooze,
    this.isMissed = false,
  });

  final ReminderKind kind;
  final String title;
  final String kindLabel;
  final String timeLabel;
  final ReminderState state;
  final VoidCallback onDone;
  final VoidCallback onSnooze;
  final bool isMissed;

  @override
  Widget build(BuildContext context) {
    final (icon, accent, accentSoft) = switch (kind) {
      ReminderKind.medication => (
        Icons.medication_rounded,
        AppColors.accentPurple,
        AppColors.accentPurpleSoft,
      ),
      ReminderKind.appointment => (
        Icons.event_rounded,
        AppColors.accentTeal,
        AppColors.accentTealSoft,
      ),
      ReminderKind.dailyTask => (
        Icons.task_alt_rounded,
        AppColors.primary,
        AppColors.primarySoft,
      ),
    };

    final isDone = state == ReminderState.done;

    return Container(
      decoration: isMissed
          ? BoxDecoration(
              border: Border(
                left: BorderSide(color: AppColors.emergency, width: 4),
              ),
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      child: CareBridgeCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: PatientText.bodyL,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kindLabel,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeLabel,
                      style: GoogleFonts.inter(
                        fontSize: PatientText.bodyM,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDone) _StatusChip.done(),
            ],
          ),
          if (state == ReminderState.pending && !isMissed) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: onDone,
                      icon: const Icon(Icons.check_rounded, size: 22),
                      label: Text(context.tr('Done')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.inter(
                          fontSize: PatientText.bodyL,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: onSnooze,
                      icon: const Icon(Icons.snooze_rounded, size: 22),
                      label: Text(context.tr('Snooze')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(
                          color: AppColors.warning,
                          width: 1.4,
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: PatientText.bodyL,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.icon,
    required this.fg,
    required this.bg,
  });

  final String label;
  final IconData icon;
  final Color fg;
  final Color bg;

  factory _StatusChip.done() => const _StatusChip(
        label: 'Completed',
        icon: Icons.check_circle_rounded,
        fg: AppColors.success,
        bg: AppColors.successSoft,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 6),
          Text(
            context.tr(label),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
