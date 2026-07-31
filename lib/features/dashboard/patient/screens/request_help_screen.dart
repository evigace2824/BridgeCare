import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../utils/user_feedback.dart';
import '../../../../widgets/carebridge/care_bridge_status_badge.dart';
import '../data/patient_models.dart';
import '../data/patient_store.dart';
import '../widgets/help_category_card.dart';

/// Full Request Help flow — local state always works; Supabase sync when
/// `assistance_requests` exists (§11).
class RequestHelpScreen extends StatefulWidget {
  const RequestHelpScreen({super.key});

  @override
  State<RequestHelpScreen> createState() => _RequestHelpScreenState();
}

class _RequestHelpScreenState extends State<RequestHelpScreen> {
  // Step 0 = pick kind, 1 = pick when, 2 = success
  int _step = 0;
  AssistanceRequestKind? _selectedKind;
  AssistanceRequestWhen _selectedWhen = AssistanceRequestWhen.today;
  DateTime? _customDate;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _pickKind(AssistanceRequestKind k) {
    setState(() {
      _selectedKind = k;
      _step = 1;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final syncMsg = context.tr(
      'Saved on this device. Could not sync to the cloud.',
    );
    setState(() => _submitting = true);
    final synced = await PatientStore.instance.submitAssistanceRequest(
      kind: _selectedKind!,
      when: _selectedWhen,
      customDate: _customDate,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _step = 2;
      _submitting = false;
    });
    if (!synced && Supabase.instance.client.auth.currentUser != null) {
      UserFeedback.showWarning(context, syncMsg);
    }
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null) return;
    setState(() {
      _customDate = picked;
      _selectedWhen = AssistanceRequestWhen.customDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: _step < 2
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  if (_step == 1) {
                    setState(() => _step = 0);
                  } else {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        title: Text(
          context.tr('Request Help'),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: _step == 0
              ? _Step1PickKind(onSelect: _pickKind)
              : _step == 1
                  ? _Step2PickWhen(
                      kind: _selectedKind!,
                      selectedWhen: _selectedWhen,
                      customDate: _customDate,
                      noteCtrl: _noteCtrl,
                      submitting: _submitting,
                      onWhenChanged: (w) =>
                          setState(() => _selectedWhen = w),
                      onPickDate: _pickCustomDate,
                      onSubmit: _submit,
                    )
                  : _Step3Success(
                      kind: _selectedKind!,
                      onDone: () => Navigator.pop(context),
                    ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — pick task type
// ---------------------------------------------------------------------------
class _Step1PickKind extends StatelessWidget {
  const _Step1PickKind({required this.onSelect});
  final void Function(AssistanceRequestKind) onSelect;

  @override
  Widget build(BuildContext context) {
    final tasks = <(AssistanceRequestKind, IconData, String, String)>[
      (
        AssistanceRequestKind.buyMedicine,
        Icons.medication_rounded,
        context.tr('Buy medicine'),
        context.tr('Need someone to help buy your medicine'),
      ),
      (
        AssistanceRequestKind.grocery,
        Icons.shopping_cart_rounded,
        context.tr('Grocery shopping'),
        context.tr('Help picking up groceries'),
      ),
      (
        AssistanceRequestKind.doctorAppointment,
        Icons.local_hospital_rounded,
        context.tr('Doctor appointment'),
        context.tr('Accompany to a medical visit'),
      ),
      (
        AssistanceRequestKind.transportation,
        Icons.directions_car_rounded,
        context.tr('Transportation'),
        context.tr('Help with transport to an appointment'),
      ),
      (
        AssistanceRequestKind.houseHelp,
        Icons.cleaning_services_rounded,
        context.tr('House help'),
        context.tr('Everyday errands and household help'),
      ),
      (
        AssistanceRequestKind.talkToSomeone,
        Icons.forum_rounded,
        context.tr('Talk to someone'),
        context.tr('A friendly volunteer can call and talk with you'),
      ),
      (
        AssistanceRequestKind.other,
        Icons.help_outline_rounded,
        context.tr('Other'),
        context.tr('Describe what you need in the next step'),
      ),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          context.tr('Request Help'),
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('Choose what you need help with.'),
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.tr(
            'A volunteer will be notified as soon as you send the request.',
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 22),
        for (final t in tasks) ...[
          HelpCategoryCard(
            icon: t.$2,
            title: t.$3,
            subtitle: t.$4,
            onTap: () => onSelect(t.$1),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — when + note
// ---------------------------------------------------------------------------
class _Step2PickWhen extends StatelessWidget {
  const _Step2PickWhen({
    required this.kind,
    required this.selectedWhen,
    required this.customDate,
    required this.noteCtrl,
    required this.submitting,
    required this.onWhenChanged,
    required this.onPickDate,
    required this.onSubmit,
  });

  final AssistanceRequestKind kind;
  final AssistanceRequestWhen selectedWhen;
  final DateTime? customDate;
  final TextEditingController noteCtrl;
  final bool submitting;
  final void Function(AssistanceRequestWhen) onWhenChanged;
  final VoidCallback onPickDate;
  final VoidCallback onSubmit;

  String _dateLabel(BuildContext context) {
    if (customDate == null) return context.tr('Choose date');
    final d = customDate!;
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final kindTitle = switch (kind) {
      AssistanceRequestKind.buyMedicine => context.tr('Buy medicine'),
      AssistanceRequestKind.grocery => context.tr('Grocery shopping'),
      AssistanceRequestKind.doctorAppointment => context.tr('Doctor appointment'),
      AssistanceRequestKind.transportation => context.tr('Transportation'),
      AssistanceRequestKind.houseHelp => context.tr('House help'),
      AssistanceRequestKind.talkToSomeone => context.tr('Talk to someone'),
      AssistanceRequestKind.other => context.tr('Other help'),
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kindTitle,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('When do you need help?'),
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _WhenTile(
            label: context.tr('Today'),
            icon: Icons.today_rounded,
            selected: selectedWhen == AssistanceRequestWhen.today,
            onTap: () => onWhenChanged(AssistanceRequestWhen.today),
          ),
          const SizedBox(height: 10),
          _WhenTile(
            label: context.tr('Tomorrow'),
            icon: Icons.event_rounded,
            selected: selectedWhen == AssistanceRequestWhen.tomorrow,
            onTap: () => onWhenChanged(AssistanceRequestWhen.tomorrow),
          ),
          const SizedBox(height: 10),
          _WhenTile(
            label: _dateLabel(context),
            icon: Icons.calendar_month_rounded,
            selected: selectedWhen == AssistanceRequestWhen.customDate,
            onTap: onPickDate,
          ),
          const SizedBox(height: 22),
          Text(
            context.tr('Notes (optional)'),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: context.tr('Any details for the volunteer…'),
              hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: submitting ? null : onSubmit,
              icon: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(context.tr('Send request')),
              style: ElevatedButton.styleFrom(
                textStyle: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhenTile extends StatelessWidget {
  const _WhenTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 — success / status
// ---------------------------------------------------------------------------
class _Step3Success extends StatelessWidget {
  const _Step3Success({
    required this.kind,
    required this.onDone,
  });

  final AssistanceRequestKind kind;
  final VoidCallback onDone;

  String _kindTitle(BuildContext context) => switch (kind) {
        AssistanceRequestKind.buyMedicine => context.tr('Buy medicine'),
        AssistanceRequestKind.grocery => context.tr('Grocery shopping'),
        AssistanceRequestKind.doctorAppointment => context.tr('Doctor appointment'),
        AssistanceRequestKind.transportation => context.tr('Transportation'),
        AssistanceRequestKind.houseHelp => context.tr('House help'),
        AssistanceRequestKind.talkToSomeone => context.tr('Talk to someone'),
        AssistanceRequestKind.other => context.tr('Other help'),
      };

  @override
  Widget build(BuildContext context) {
    final kindTitle = _kindTitle(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 52,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            context.tr('Request sent!'),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr(
              'Your request has been sent to available volunteers.',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Request: {type}',
              {'type': kindTitle},
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 28),
          _StatusBadge(state: AssistanceRequestState.pending),
          const SizedBox(height: 10),
          Text(
            context.tr(
              'You and your family will be notified when a volunteer accepts.',
            ),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: onDone,
              child: Text(context.tr('Back to home')),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});
  final AssistanceRequestState state;

  @override
  Widget build(BuildContext context) {
    final (label, color, soft) = switch (state) {
      AssistanceRequestState.pending => (
        context.tr('Pending — waiting for a volunteer'),
        AppColors.warning,
        AppColors.warningSoft,
      ),
      AssistanceRequestState.accepted => (
        context.tr('Accepted by a volunteer'),
        AppColors.success,
        AppColors.successSoft,
      ),
      AssistanceRequestState.completed => (
        context.tr('Completed'),
        AppColors.primary,
        AppColors.primarySoft,
      ),
      AssistanceRequestState.cancelled => (
        context.tr('Cancelled'),
        AppColors.textMuted,
        AppColors.border,
      ),
    };
    return Center(
      child: CareBridgeStatusBadge(
        label: label,
        color: color,
        backgroundColor: soft,
        leadingDot: true,
      ),
    );
  }
}
