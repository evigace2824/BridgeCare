import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../data/patient_models.dart';

/// Premium gradient hero card for the patient home tab.
///
/// Displays:
/// - BridgeCare logo + greeting + first name
/// - Connected-family pill + status pill
/// - Compact audio-mode and language quick toggles
/// - Live time/date pill
class PatientPremiumHero extends StatelessWidget {
  const PatientPremiumHero({
    super.key,
    required this.firstName,
    required this.connectedFamilyName,
    required this.overallStatus,
    required this.audioEnabled,
    required this.onTapAudio,
    required this.onTapLanguage,
  });

  final String firstName;
  final String? connectedFamilyName;
  final PatientOverallStatus overallStatus;
  final bool audioEnabled;
  final VoidCallback onTapAudio;
  final VoidCallback onTapLanguage;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    if (h < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${_weekdayShort(now.weekday)}, ${_monthShort(now.month)} ${now.day}';

    final (statusIcon, statusLabel, statusColor) = switch (overallStatus) {
      PatientOverallStatus.safe => (
          Icons.verified_rounded,
          'You are safe',
          const Color(0xFF51CF66)
        ),
      PatientOverallStatus.needsAttention => (
          Icons.notifications_active_rounded,
          'Needs attention',
          const Color(0xFFFFB446)
        ),
      PatientOverallStatus.emergency => (
          Icons.priority_high_rounded,
          'Emergency active',
          const Color(0xFFFF8585)
        ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ─── Brand row above the hero (separate from the gradient) ───
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EDFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    'assets/bridgecare_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'BridgeCare',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Care · Connect · Calm',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Color(0xFF3B5BDB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dateLabel,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF2A46B0),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ─── Gradient hero card ───
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B3A8A),
                Color(0xFF4F46E5),
                Color(0xFF7C5BFF),
                Color(0xFFB388FF),
              ],
              stops: [0.0, 0.45, 0.78, 1.0],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.40),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -28,
                top: -32,
                child: _bgBubble(140, Colors.white.withValues(alpha: 0.10)),
              ),
              Positioned(
                right: 70,
                bottom: -34,
                child: _bgBubble(96, Colors.white.withValues(alpha: 0.07)),
              ),
              Positioned(
                left: -20,
                bottom: -22,
                child: _bgBubble(80, Colors.white.withValues(alpha: 0.06)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(_greeting()),
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statusBadge(statusIcon, context.tr(statusLabel),
                          statusColor),
                      if (connectedFamilyName != null &&
                          connectedFamilyName!.isNotEmpty)
                        _glassPill(
                          Icons.family_restroom_rounded,
                          context.tr(
                            'With {name}',
                            {'name': connectedFamilyName!},
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _SmoothQuickToggle(
                          icon: audioEnabled
                              ? Icons.headphones_rounded
                              : Icons.headphones_outlined,
                          label: audioEnabled
                              ? context.tr('Audio on')
                              : context.tr('Audio mode'),
                          active: audioEnabled,
                          onTap: onTapAudio,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SmoothQuickToggle(
                          icon: Icons.translate_rounded,
                          label: context.tr('Language'),
                          active: false,
                          onTap: onTapLanguage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bgBubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _glassPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String _weekdayShort(int weekday) {
    const map = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    return map[weekday] ?? '';
  }

  String _monthShort(int m) {
    const map = {
      1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr', 5: 'May', 6: 'Jun',
      7: 'Jul', 8: 'Aug', 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dec',
    };
    return map[m] ?? '';
  }
}

/// Quick toggle button on the hero that animates color, border, icon tint and
/// gives a satisfying scale + haptic on press. Replaces the previous abrupt
/// `Material + InkWell` version that snapped between states.
class _SmoothQuickToggle extends StatefulWidget {
  const _SmoothQuickToggle({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SmoothQuickToggle> createState() => _SmoothQuickToggleState();
}

class _SmoothQuickToggleState extends State<_SmoothQuickToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 140),
    lowerBound: 0.0,
    upperBound: 0.06,
  );

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _press.forward();
  void _onTapUp(TapUpDetails _) => _press.reverse();
  void _onTapCancel() => _press.reverse();

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return AnimatedBuilder(
      animation: _press,
      builder: (context, child) {
        final scale = 1.0 - _press.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.30),
              width: active ? 1.5 : 1.0,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                transitionBuilder: (c, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: c),
                ),
                child: Icon(
                  widget.icon,
                  key: ValueKey(widget.icon.codePoint),
                  size: 18,
                  color: active ? AppColors.primary : Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 240),
                  style: GoogleFonts.inter(
                    color: active ? AppColors.primary : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (active)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
