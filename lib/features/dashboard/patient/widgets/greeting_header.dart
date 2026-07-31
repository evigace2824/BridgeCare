import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../utils/care_bridge_layout.dart';

/// Top-of-home header for the patient dashboard. Shows:
///
/// - Greeting + first name ("Good morning, Maria")
/// - Two compact info pills: "Connected to: Arben" and "Status: Safe"
/// - Two small header icon buttons for **Audio mode** and **Language**
///   (Spec §7.15 / §7.16) — placeholder onTap callbacks for now.
///
/// Designed deliberately quiet so the SOS button below is the visual focal
/// point of the screen.
class GreetingHeader extends StatefulWidget {
  const GreetingHeader({
    super.key,
    required this.name,
    required this.connectedFamilyName,
    this.status = PatientStatus.allGood,
    this.onTapAudio,
    this.onTapLanguage,
    this.audioEnabled = false,
  });

  final String name;
  final String? connectedFamilyName;
  final PatientStatus status;
  final VoidCallback? onTapAudio;
  final VoidCallback? onTapLanguage;
  final bool audioEnabled;

  @override
  State<GreetingHeader> createState() => _GreetingHeaderState();
}

class _GreetingHeaderState extends State<GreetingHeader> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _scheduleNextTick();
  }

  void _scheduleNextTick() {
    final now = DateTime.now();
    final msUntilNextMinute =
        (60 - now.second) * 1000 - now.millisecond;
    _ticker?.cancel();
    _ticker = Timer(Duration(milliseconds: msUntilNextMinute), () {
      if (!mounted) return;
      setState(() {});
      _scheduleNextTick();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/bridgecare_logo.png',
              height: 28,
              semanticLabel: 'BridgeCare',
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr(_greeting(now)),
                style: GoogleFonts.inter(
                  fontSize: PatientText.bodyL,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            _HeaderIconButton(
              icon: Icons.headphones_rounded,
              tooltip: context.tr('Audio mode'),
              onTap: widget.onTapAudio,
              active: widget.audioEnabled,
            ),
            const SizedBox(width: 6),
            _HeaderIconButton(
              icon: Icons.translate_rounded,
              tooltip: context.tr('Language'),
              onTap: widget.onTapLanguage,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.name,
          style: GoogleFonts.inter(
            fontSize: PatientText.titleL,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.connectedFamilyName != null)
              _InfoPill(
                icon: Icons.family_restroom_rounded,
                label: context.tr(
                  'Connected to: {name}',
                  {'name': widget.connectedFamilyName!},
                ),
                fg: AppColors.primary,
                bg: AppColors.primarySoft,
              ),
            _StatusPill(status: widget.status),
          ],
        ),
      ],
    );
  }
}

enum PatientStatus { allGood, actionNeeded, emergency }

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final PatientStatus status;

  @override
  Widget build(BuildContext context) {
    final (icon, label, fg, bg) = switch (status) {
      PatientStatus.allGood => (
        Icons.verified_rounded,
        'Status: Safe',
        AppColors.success,
        AppColors.successSoft,
      ),
      PatientStatus.actionNeeded => (
        Icons.notifications_active_rounded,
        'Status: Needs attention',
        AppColors.warning,
        AppColors.warningSoft,
      ),
      PatientStatus.emergency => (
        Icons.priority_high_rounded,
        'Status: Emergency',
        AppColors.emergency,
        AppColors.emergencySoft,
      ),
    };
    return _InfoPill(
      icon: icon,
      label: context.tr(label),
      fg: fg,
      bg: bg,
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
  });

  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: active ? AppColors.primarySoft : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: SizedBox(
              width: CareBridgeLayout.minTouchTarget,
              height: CareBridgeLayout.minTouchTarget,
              child: Center(
                child: Icon(
                  icon,
                  color: active ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
