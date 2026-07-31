import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../models/family_models.dart' as family_models;
import '../../../../models/user_model.dart';
import '../../../../services/audio_service.dart';
import '../../../../screens/user/patient_nav.dart';
import '../../../../utils/care_bridge_layout.dart';
import '../../../family/chat.dart';
import '../data/patient_models.dart';
import '../data/patient_store.dart';
import '../screens/daily_content_screen.dart';
import '../screens/call_someone_screen.dart';
import '../screens/request_help_screen.dart';
import '../widgets/daily_content_card.dart';
import '../widgets/emergency_alert_flow.dart';
import '../widgets/enter_health_values_sheet.dart';
import '../widgets/health_status_card.dart';
import '../widgets/next_reminder_card.dart';
import '../widgets/premium_hero.dart';
import '../widgets/quick_action_tile.dart';
import '../widgets/section_title.dart';
import '../widgets/sos_button.dart';
import '../widgets/today_kpi_strip.dart';

/// Patient Home tab — the main safety control panel.
///
/// Layout (spec order):
///   Header  → Greeting + connected-to + status pills
///   HELP    → Giant SOS button
///   Quick   → 2×2: Call Family · Request Help · Reminders · Health Status
///   Today   → Next Reminder card (Done / Snooze)
///   Health  → Health Status card (Enter Health Values)
///   Content → Daily Content card (Read / Listen)
class HomeTab extends StatelessWidget {
  const HomeTab({
    super.key,
    required this.profile,
    required this.onOpenReminders,
    required this.onOpenHealth,
  });

  final UserModel? profile;
  final VoidCallback onOpenReminders;
  final VoidCallback onOpenHealth;

  String _firstName(UserModel? p) {
    final n = p?.fullName?.trim();
    if (n == null || n.isEmpty) return p?.email?.split('@').first ?? 'there';
    return n.split(' ').first;
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

  void _onCallFamily(BuildContext context, String familyName) {
    PatientNav.push(context, const CallSomeoneScreen());
  }

  Future<void> _openFamilyChat(
    BuildContext context, {
    required String familyName,
  }) async {
    if (familyName.trim().isEmpty ||
        familyName.toLowerCase().contains('no family linked')) {
      _toast(
        context,
        context.tr(
          'No family member is linked yet. Share your family link code from Profile.',
        ),
        bg: AppColors.warning,
      );
      return;
    }
    final linked = family_models.LinkedUser(
      uid: 'family-$familyName'.toLowerCase().replaceAll(' ', '-'),
      fullName: familyName,
      phoneNumber: '+355 69 000 0000',
      healthStatus: const family_models.HealthStatus(
        type: family_models.HealthStatusType.normal,
        label: 'Normal',
        description: 'No active alerts',
      ),
    );
    await PatientNav.push(
      context,
      FamilyChatScreen(linkedUser: linked),
    );
  }

  Future<void> _showCheckInActions(BuildContext context) async {
    final store = PatientStore.instance;
    final mood = store.dailyCheckInMood;
    if (mood != DailyCheckInMood.unwell) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(
                'Would you like to notify your family or request help?',
              ),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                store.addActivity(
                  type: ActivityType.familyCheckIn,
                  title: 'Family notified for wellbeing check',
                  subtitle: 'Patient reported feeling unwell.',
                );
                _toast(
                  context,
                  context.tr('Your family has been notified you may need help.'),
                );
              },
              icon: const Icon(Icons.family_restroom_rounded),
              label: Text(context.tr('Notify family')),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _onRequestHelp(context);
              },
              icon: const Icon(Icons.volunteer_activism_rounded),
              label: Text(context.tr('Request help')),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('Cancel')),
            ),
          ],
        ),
      ),
    );
  }

  void _onRequestHelp(BuildContext context) {
    PatientNav.push(context, const RequestHelpScreen());
  }

  Future<void> _onPickLanguage(BuildContext context) async {
    final store = PatientStore.instance;
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(context.tr('Choose language')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'en'),
            child: Text(
              '${store.language == 'en' ? '✓ ' : ''}${context.tr('English')}',
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'sq'),
            child: Text(
              '${store.language == 'sq' ? '✓ ' : ''}${context.tr('Albanian')}',
            ),
          ),
        ],
      ),
    );
    if (selected == null) return;
    store.setLanguage(selected);
    LocaleController.instance.setCode(selected);
    if (!context.mounted) return;
    _toast(
      context,
      context.tr(
        'Language set to {lang}.',
        {'lang': selected == 'sq' ? context.tr('Albanian') : context.tr('English')},
      ),
      bg: AppColors.primary,
    );
  }

  Future<void> _onToggleAudio(BuildContext context) async {
    final store = PatientStore.instance;
    store.toggleAudioMode();
    final msg = store.audioModeEnabled
        ? context.tr('Audio mode enabled.')
        : context.tr('Audio mode disabled.');
    if (store.audioModeEnabled) {
      AudioService.instance.speak(msg);
    } else {
      AudioService.instance.stop();
    }
    _toast(
      context,
      msg,
      bg: AppColors.primary,
      icon: Icons.headphones_rounded,
    );
  }

  void _onEnterHealthValues(BuildContext context) {
    EnterHealthValuesSheet.show(context);
  }

  void _toast(
    BuildContext context,
    String message, {
    Color bg = AppColors.success,
    IconData icon = Icons.check_circle_rounded,
  }) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(
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
                message,
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


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PatientStore.instance,
      builder: (context, _) {
        final store = PatientStore.instance;
        final next = store.nextReminder;
        final pendingMeds = store.pendingMedicationCount;

        return SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: CareBridgeLayout.tabScreenPadding(context),
                children: [
              // ── 1. PREMIUM HERO ────────────────────────────────────────────
              PatientPremiumHero(
                firstName: _firstName(profile),
                connectedFamilyName: store.displayFamilyName,
                overallStatus: store.overallStatus,
                audioEnabled: store.audioModeEnabled,
                onTapAudio: () => _onToggleAudio(context),
                onTapLanguage: () => _onPickLanguage(context),
              ),
              const SizedBox(height: 16),

              // ── 2. TODAY AT A GLANCE — KPI STRIP ───────────────────────────
              TodayKpiStrip(
                store: store,
                onOpenHealth: onOpenHealth,
                onOpenReminders: onOpenReminders,
              ),
              if (store.showEmergencyStatusBanner) ...[
                const SizedBox(height: 16),
                _EmergencyActiveBanner(
                  onDismiss: () => store.dismissEmergencyBanner(),
                  canClear: store.canClearEmergencyAlert,
                  minutesLeft: store.canClearEmergencyAlert
                      ? 0
                      : ((store.emergencyCanClearAt!
                                      .difference(DateTime.now())
                                      .inSeconds +
                                  59) ~/
                              60)
                          .clamp(1, 60),
                  onClear: () {
                    store.clearEmergencyAlert();
                    _toast(
                      context,
                      context.tr('Emergency alert cleared'),
                      bg: AppColors.success,
                    );
                  },
                ),
              ],
              const SizedBox(height: 20),

              // ── 2. HELP BUTTON ─────────────────────────────────────────────
              SosButton(
                onPressed: () => EmergencyAlertFlow.run(context),
                onLongPressConfirmed: () => EmergencyAlertFlow.run(
                  context,
                  requireConfirmation: false,
                ),
                isEmergencyActive: store.showEmergencyStatusBanner,
              ),
              const SizedBox(height: 24),

              // ── 3. QUICK ACTIONS ───────────────────────────────────────────
              SectionTitle(context.tr('Quick actions')),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.22,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  QuickActionTile(
                    icon: Icons.phone_in_talk_rounded,
                    label: context.tr('Call family'),
                    metric: context.tr('One-tap call'),
                    color: AppColors.primary,
                    softColor: AppColors.primarySoft,
                    onTap: () =>
                        _onCallFamily(context, store.displayFamilyName),
                  ),
                  QuickActionTile(
                    icon: Icons.volunteer_activism_rounded,
                    label: context.tr('Request help'),
                    metric: context.tr('Ask a volunteer'),
                    color: AppColors.accentTeal,
                    softColor: AppColors.accentTealSoft,
                    onTap: () => _onRequestHelp(context),
                  ),
                  QuickActionTile(
                    icon: Icons.medication_rounded,
                    label: context.tr('My reminders'),
                    metric: pendingMeds == 0
                        ? context.tr('All done today')
                        : context.tr('{count} left today', {'count': '$pendingMeds'}),
                    color: AppColors.accentPurple,
                    softColor: AppColors.accentPurpleSoft,
                    onTap: onOpenReminders,
                  ),
                  QuickActionTile(
                    icon: Icons.favorite_rounded,
                    label: context.tr('Health status'),
                    metric: store.vitals.heartRate != null
                        ? '${store.vitals.heartRate} bpm'
                        : context.tr('Tap to record'),
                    color: AppColors.accentPink,
                    softColor: AppColors.accentPinkSoft,
                    onTap: onOpenHealth,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DailyCheckInCard(
                onSelectMood: (mood) async {
                  store.setDailyCheckIn(mood);
                  final msg = switch (mood) {
                    DailyCheckInMood.good => context.tr(
                        'Great to hear that you feel good today.',
                      ),
                    DailyCheckInMood.okay => context.tr(
                        'Thank you for checking in. We are here for you.',
                      ),
                    DailyCheckInMood.unwell => context.tr(
                        'Thanks for letting us know. We can help right away.',
                      ),
                  };
                  _toast(context, msg, bg: AppColors.primary);
                  if (mood == DailyCheckInMood.unwell) {
                    await _showCheckInActions(context);
                  }
                },
              ),
              const SizedBox(height: 18),
              _FamilyConnectionCard(
                familyName: store.displayFamilyName,
                relationship: context.tr('Family member'),
                onCall: () => _onCallFamily(context, store.displayFamilyName),
                onMessage: () => _openFamilyChat(
                  context,
                  familyName: store.displayFamilyName,
                ),
                onOkay: () {
                  store.addActivity(
                    type: ActivityType.familyCheckIn,
                    title: 'Family check-in sent',
                    subtitle: 'Patient confirmed they are okay.',
                  );
                  _toast(
                    context,
                    context.tr('Your family has been notified that you are okay.'),
                    bg: AppColors.success,
                  );
                },
              ),
              const SizedBox(height: 18),
              _RoutineCard(
                tasks: store.todayRoutine,
                onToggle: store.toggleRoutineTask,
              ),
              const SizedBox(height: 24),

              // ── 4. NEXT REMINDER ───────────────────────────────────────────
              SectionTitle(context.tr('Next reminder')),
              const SizedBox(height: 8),
              NextReminderCard(
                reminder: next,
                onDone: () {
                  if (next != null) store.markReminderDone(next.id);
                  _toast(context, context.tr('Marked as done.'));
                },
                onSnooze: () {
                  if (next != null) {
                    _offerSnooze(context, reminderId: next.id);
                  }
                },
                onSeeAll: onOpenReminders,
              ),
              const SizedBox(height: 24),

              // ── 5. HEALTH STATUS ───────────────────────────────────────────
              SectionTitle(context.tr('Health status')),
              const SizedBox(height: 8),
              HealthStatusCard(
                vitals: store.vitals,
                status: store.healthStatus,
                onEnterValues: () => _onEnterHealthValues(context),
              ),
              const SizedBox(height: 24),

              // ── 6. DAILY CONTENT ───────────────────────────────────────────
              SectionTitle(context.tr('Daily content')),
              const SizedBox(height: 8),
              DailyContentCard(
                tip: store.dailyTip,
                onRead: () =>
                    PatientNav.push(context, const DailyContentScreen()),
                onListen: () => _onToggleAudio(context),
              ),
              const SizedBox(height: 24),
              _RecentActivitySection(
                activities: store.recentActivities.take(5).toList(),
              ),
            ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmergencyActiveBanner extends StatelessWidget {
  const _EmergencyActiveBanner({
    required this.onDismiss,
    required this.canClear,
    required this.minutesLeft,
    required this.onClear,
  });

  final VoidCallback onDismiss;
  final bool canClear;
  final int minutesLeft;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.tr('Emergency alert active'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.emergencySoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.emergency.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.notifications_active_rounded, color: AppColors.emergency),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      'Emergency alert sent. Your family and helpers were notified.',
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: canClear ? onClear : null,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: Text(
                      canClear
                          ? context.tr('Remove alert')
                          : context.tr(
                              'You can remove this alert in {m} min',
                              {'m': '$minutesLeft'},
                            ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          canClear ? AppColors.success : AppColors.textMuted,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.textSecondary,
              tooltip: context.tr('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Daily check-in card with strong visual feedback: each mood is a
/// large rounded tile with its own color and emoji-like icon. Tapping a
/// tile animates a "selected" check-pill with confirmation text directly
/// inside the card so the user sees that something happened — even before
/// the toast at the bottom appears.
class _DailyCheckInCard extends StatelessWidget {
  const _DailyCheckInCard({required this.onSelectMood});
  final ValueChanged<DailyCheckInMood> onSelectMood;

  static const _moods = [
    (
      DailyCheckInMood.good,
      Icons.sentiment_very_satisfied_rounded,
      'I feel good',
      Color(0xFF2E7D32), // green
      Color(0xFF66BB6A),
    ),
    (
      DailyCheckInMood.okay,
      Icons.sentiment_satisfied_rounded,
      'I feel okay',
      Color(0xFFFB8C00), // amber
      Color(0xFFFFB74D),
    ),
    (
      DailyCheckInMood.unwell,
      Icons.sentiment_dissatisfied_rounded,
      'I do not feel well',
      Color(0xFFE53935), // red
      Color(0xFFEF5350),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PatientStore.instance,
      builder: (context, _) {
        final store = PatientStore.instance;
        final selected = store.dailyCheckInMood;
        final selectedAt = store.dailyCheckInAt;
        return Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D133A63),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1F5DA0), Color(0xFF24B6A8)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Daily check-in'),
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          context.tr('How are you feeling today?'),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              for (final m in _moods) ...[
                _MoodTile(
                  mood: m.$1,
                  icon: m.$2,
                  label: context.tr(m.$3),
                  primary: m.$4,
                  light: m.$5,
                  isSelected: selected == m.$1,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onSelectMood(m.$1);
                  },
                ),
                const SizedBox(height: 8),
              ],
              AnimatedSize(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                child: selected == null
                    ? const SizedBox.shrink()
                    : _SelectedMoodConfirmation(
                        mood: selected,
                        at: selectedAt,
                        onChange: () {
                          HapticFeedback.selectionClick();
                          PatientStore.instance.clearDailyCheckIn();
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MoodTile extends StatefulWidget {
  const _MoodTile({
    required this.mood,
    required this.icon,
    required this.label,
    required this.primary,
    required this.light,
    required this.isSelected,
    required this.onTap,
  });
  final DailyCheckInMood mood;
  final IconData icon;
  final String label;
  final Color primary;
  final Color light;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_MoodTile> createState() => _MoodTileState();
}

class _MoodTileState extends State<_MoodTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 130),
    lowerBound: 0,
    upperBound: 0.06,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.isSelected;
    return AnimatedBuilder(
      animation: _press,
      builder: (context, child) =>
          Transform.scale(scale: 1 - _press.value, child: child),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) => _press.reverse(),
        onTapCancel: () => _press.reverse(),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
                    colors: [widget.primary, widget.light],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: selected ? null : widget.light.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? widget.primary
                  : widget.primary.withValues(alpha: 0.30),
              width: selected ? 2 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: widget.primary.withValues(alpha: 0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : widget.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.icon,
                  color: selected ? Colors.white : widget.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 240),
                  style: GoogleFonts.inter(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                  child: Text(widget.label),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                  border: Border.all(
                    color: selected
                        ? Colors.white
                        : widget.primary.withValues(alpha: 0.40),
                    width: 1.5,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          key: const ValueKey('check'),
                          color: widget.primary,
                          size: 18,
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedMoodConfirmation extends StatelessWidget {
  const _SelectedMoodConfirmation({
    required this.mood,
    required this.at,
    required this.onChange,
  });
  final DailyCheckInMood mood;
  final DateTime? at;
  final VoidCallback onChange;

  ({String message, Color color}) _confirmFor(BuildContext context) {
    switch (mood) {
      case DailyCheckInMood.good:
        return (
          message: context.tr(
              'Awesome — your family will see that you are feeling great today.'),
          color: const Color(0xFF2E7D32),
        );
      case DailyCheckInMood.okay:
        return (
          message: context.tr(
              'Thanks for letting us know. We are here if anything changes.'),
          color: const Color(0xFFFB8C00),
        );
      case DailyCheckInMood.unwell:
        return (
          message: context.tr(
              'We are sorry. Tap below to notify family or request help.'),
          color: const Color(0xFFE53935),
        );
    }
  }

  String _timeLabel(BuildContext context) {
    if (at == null) return '';
    final h = at!.hour.toString().padLeft(2, '0');
    final m = at!.minute.toString().padLeft(2, '0');
    return ' · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final c = _confirmFor(context);
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: c.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: c.color, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${c.message}${_timeLabel(context)}',
              style: GoogleFonts.inter(
                color: c.color,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: c.color,
            ),
            child: Text(
              context.tr('Change'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FamilyConnectionCard extends StatelessWidget {
  const _FamilyConnectionCard({
    required this.familyName,
    required this.relationship,
    required this.onCall,
    required this.onMessage,
    required this.onOkay,
  });
  final String familyName;
  final String relationship;
  final VoidCallback onCall;
  final VoidCallback onMessage;
  final VoidCallback onOkay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Family connection'),
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '$familyName • $relationship',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('Last contacted today'),
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call_rounded),
                  label: Text(context.tr('Call')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.message_rounded),
                  label: Text(context.tr('Message')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onOkay,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(context.tr('Send I am okay')),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.tasks, required this.onToggle});
  final List<RoutineTask> tasks;
  final ValueChanged<RoutineTaskKind> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Today\'s routine'),
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (final task in tasks) ...[
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onToggle(task.kind),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: task.completed ? AppColors.successSoft : AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      task.completed
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: task.completed ? AppColors.success : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr(task.label),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.activities});
  final List<PatientActivity> activities;

  IconData _iconFor(ActivityType t) => switch (t) {
        ActivityType.reminderDone => Icons.check_circle_rounded,
        ActivityType.reminderSnoozed => Icons.snooze_rounded,
        ActivityType.healthEntered => Icons.favorite_rounded,
        ActivityType.helpRequested => Icons.volunteer_activism_rounded,
        ActivityType.familyCheckIn => Icons.family_restroom_rounded,
        ActivityType.emergencyAlert => Icons.emergency_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(context.tr('Recent activity')),
        const SizedBox(height: 8),
        if (activities.isEmpty)
          Text(
            context.tr('No recent activity yet.'),
            style: GoogleFonts.inter(color: AppColors.textSecondary),
          )
        else
          for (final a in activities) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(_iconFor(a.type), color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(a.title),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                        if (a.subtitle != null)
                          Text(
                            context.tr(a.subtitle!),
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
      ],
    );
  }
}
