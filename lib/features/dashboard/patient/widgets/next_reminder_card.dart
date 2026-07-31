import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../data/patient_models.dart';

/// "Next Reminder" hero card on the patient home (Spec §6).
///
/// Surfaces the next pending reminder prominently, with large Done / Snooze
/// buttons. When all of today's reminders are handled, switches to a
/// success state.
class NextReminderCard extends StatelessWidget {
  const NextReminderCard({
    super.key,
    required this.reminder,
    required this.onDone,
    required this.onSnooze,
    required this.onSeeAll,
  });

  /// Null when there is no pending reminder right now.
  final PatientReminder? reminder;
  final VoidCallback onDone;
  final VoidCallback onSnooze;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (reminder == null) return _AllDone(onSeeAll: onSeeAll);

    final r = reminder!;
    final (icon, color, soft) = switch (r.kind) {
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.tr('Next reminder'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  minimumSize: const Size(0, 28),
                  textStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(context.tr('See all')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _humanWhen(context, r.scheduledAt),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onDone,
                    icon: const Icon(Icons.check_rounded, size: 22),
                    label: Text(context.tr('Done')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _humanWhen(BuildContext context, DateTime when) {
    final now = DateTime.now();
    final isToday = when.year == now.year &&
        when.month == now.month &&
        when.day == now.day;
    final h12 = when.hour == 0
        ? 12
        : (when.hour > 12 ? when.hour - 12 : when.hour);
    final m = when.minute.toString().padLeft(2, '0');
    final ampm = when.hour < 12 ? 'AM' : 'PM';
    return '${isToday ? context.tr('Today') : context.tr('Tomorrow')} · $h12:$m $ampm';
  }
}

class _AllDone extends StatelessWidget {
  const _AllDone({required this.onSeeAll});
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr("You're all set for now"),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.tr('No more reminders for today.'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Text(context.tr('See all')),
          ),
        ],
      ),
    );
  }
}
