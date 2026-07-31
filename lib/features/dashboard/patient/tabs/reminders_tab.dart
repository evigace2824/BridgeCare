import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../screens/user/patient_nav.dart';
import '../../../../utils/care_bridge_layout.dart';
import '../data/patient_models.dart';
import '../data/patient_store.dart';
import '../screens/add_reminder_screen.dart';
import '../widgets/reminder_card.dart';
import '../widgets/section_title.dart';

enum _ReminderFilter { all, today, upcoming, completed }

/// Full reminders tab — reads from [PatientStore].
class RemindersTab extends StatefulWidget {
  const RemindersTab({super.key});

  @override
  State<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<RemindersTab> {
  _ReminderFilter _filter = _ReminderFilter.today;

  void _toast(
    BuildContext context,
    String msg, {
    Color bg = AppColors.success,
    IconData icon = Icons.check_circle_rounded,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _kindLabel(BuildContext context, ReminderKind k) {
    return switch (k) {
      ReminderKind.medication => context.tr('Medication'),
      ReminderKind.appointment => context.tr('Appointment'),
      ReminderKind.dailyTask => context.tr('Daily task'),
    };
  }

  static String _timeLabel(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    final dayLabel = day == today
        ? context.tr('Today')
        : day == today.add(const Duration(days: 1))
            ? context.tr('Tomorrow')
            : '${dt.month}/${dt.day}';
    final timeLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: dt.hour, minute: dt.minute),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '$dayLabel · $timeLabel';
  }

  Future<void> _offerSnooze(
    BuildContext context, {
    required String reminderId,
  }) async {
    const minutes = 15;
    PatientStore.instance
        .snoozeReminder(reminderId, Duration(minutes: minutes));
    _toast(
      context,
      context.tr('Snoozed for {n} minutes.', {'n': '$minutes'}),
      bg: AppColors.warning,
      icon: Icons.snooze_rounded,
    );
  }

  List<PatientReminder> _todaysReminders(List<PatientReminder> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return all.where((r) {
      final d = DateTime(r.scheduledAt.year, r.scheduledAt.month,
          r.scheduledAt.day);
      return d == today;
    }).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  List<PatientReminder> _forFilter(List<PatientReminder> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isToday(PatientReminder r) {
      final d = DateTime(
        r.scheduledAt.year,
        r.scheduledAt.month,
        r.scheduledAt.day,
      );
      return d == today;
    }

    switch (_filter) {
      case _ReminderFilter.all:
        return List<PatientReminder>.of(all);
      case _ReminderFilter.today:
        return all.where(isToday).toList();
      case _ReminderFilter.upcoming:
        return all.where((r) => r.scheduledAt.isAfter(now) && !isToday(r)).toList();
      case _ReminderFilter.completed:
        return all.where((r) => r.state == ReminderState.done).toList();
    }
  }

  String _groupDateLabel(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return context.tr('Today');
    if (day == today.add(const Duration(days: 1))) return context.tr('Tomorrow');
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PatientStore.instance,
      builder: (context, _) {
        final reminders = PatientStore.instance.reminders;
        final filtered = _forFilter(reminders)
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        final today = _todaysReminders(reminders);

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: CareBridgeLayout.tabScreenPadding(context),
            children: [
              Text(
                context.tr('My Reminders'),
                style: GoogleFonts.inter(
                  fontSize: PatientText.titleL,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('Medications and appointments for today.'),
                style: GoogleFonts.inter(
                  fontSize: PatientText.bodyM,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      PatientNav.push(context, const AddReminderScreen()),
                  icon: const Icon(Icons.add_rounded, size: 24),
                  label: Text(context.tr('+ Add a new reminder')),
                  style: ElevatedButton.styleFrom(
                    textStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: context.tr('All'),
                    selected: _filter == _ReminderFilter.all,
                    onTap: () => setState(() => _filter = _ReminderFilter.all),
                  ),
                  _FilterChip(
                    label: context.tr('Today'),
                    selected: _filter == _ReminderFilter.today,
                    onTap: () => setState(() => _filter = _ReminderFilter.today),
                  ),
                  _FilterChip(
                    label: context.tr('Upcoming'),
                    selected: _filter == _ReminderFilter.upcoming,
                    onTap: () => setState(() => _filter = _ReminderFilter.upcoming),
                  ),
                  _FilterChip(
                    label: context.tr('Completed'),
                    selected: _filter == _ReminderFilter.completed,
                    onTap: () => setState(() => _filter = _ReminderFilter.completed),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MedicationProgressCard(
                done: PatientStore.instance.todayReminderDone,
                total: PatientStore.instance.todayReminderTotal,
              ),
              const SizedBox(height: 16),
              SectionTitle(context.tr('Today')),
              const SizedBox(height: 8),
              if ((_filter == _ReminderFilter.today ? today : filtered).isEmpty)
                _EmptyState(
                  onAddReminder: () =>
                      PatientNav.push(context, const AddReminderScreen()),
                )
              else
                for (var i = 0;
                    i < (_filter == _ReminderFilter.today ? today : filtered).length;
                    i++) ...[
                  if (_filter == _ReminderFilter.upcoming &&
                      (i == 0 ||
                          _groupDateLabel(
                                context,
                                filtered[i - 1].scheduledAt,
                              ) !=
                              _groupDateLabel(context, filtered[i].scheduledAt)))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 6),
                      child: Text(
                        _groupDateLabel(context, filtered[i].scheduledAt),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ReminderCard(
                    kind: (_filter == _ReminderFilter.today ? today : filtered)[i].kind,
                    kindLabel: _kindLabel(
                      context,
                      (_filter == _ReminderFilter.today ? today : filtered)[i].kind,
                    ),
                    title: (_filter == _ReminderFilter.today ? today : filtered)[i].title,
                    timeLabel: _timeLabel(
                      context,
                      (_filter == _ReminderFilter.today ? today : filtered)[i].scheduledAt,
                    ),
                    state: (_filter == _ReminderFilter.today ? today : filtered)[i].state,
                    isMissed: (_filter == _ReminderFilter.today ? today : filtered)[i]
                            .state ==
                        ReminderState.pending &&
                        (_filter == _ReminderFilter.today ? today : filtered)[i]
                            .scheduledAt
                            .isBefore(DateTime.now()),
                    onDone: () {
                      PatientStore.instance.markReminderDone(
                        (_filter == _ReminderFilter.today ? today : filtered)[i].id,
                      );
                      _toast(context, context.tr('Marked as done.'));
                    },
                    onSnooze: () => _offerSnooze(
                      context,
                      reminderId:
                          (_filter == _ReminderFilter.today ? today : filtered)[i].id,
                    ),
                  ),
                  if (i != (_filter == _ReminderFilter.today ? today : filtered).length - 1)
                    const SizedBox(height: 10),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddReminder});
  final VoidCallback onAddReminder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              context.tr("You're all done for today!"),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onAddReminder,
            child: Text(context.tr('Add reminder')),
          ),
        ],
      ),
    );
  }
}

class _MedicationProgressCard extends StatelessWidget {
  const _MedicationProgressCard({required this.done, required this.total});
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final complete = total > 0 && done >= total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr("Today's reminder progress"),
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('{done} of {total} completed', {
              'done': '$done',
              'total': '$total',
            }),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 350),
            tween: Tween(begin: 0, end: progress),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: AppColors.border,
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Text(
              complete
                  ? context.tr('Great job! You are all set for today.')
                  : context.tr('Keep going, you are doing great.'),
              key: ValueKey(complete),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: complete ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
