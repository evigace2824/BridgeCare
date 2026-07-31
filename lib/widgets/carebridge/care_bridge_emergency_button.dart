import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';

/// Large red emergency CTA (patient home). [onPressed] opens confirm flow.
class CareBridgeEmergencyButton extends StatelessWidget {
  const CareBridgeEmergencyButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.onLongPressConfirmed,
    this.isEmergencyActive = false,
    this.semanticsLabel,
    this.semanticsHint,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final VoidCallback onLongPressConfirmed;
  final bool isEmergencyActive;
  final String? semanticsLabel;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    return _EmergencyButtonBody(
      title: title,
      subtitle: subtitle,
      onPressed: onPressed,
      onLongPressConfirmed: onLongPressConfirmed,
      isEmergencyActive: isEmergencyActive,
      semanticsHint: semanticsHint,
      semanticsLabel: semanticsLabel,
    );
  }
}

class _EmergencyButtonBody extends StatefulWidget {
  const _EmergencyButtonBody({
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.onLongPressConfirmed,
    required this.isEmergencyActive,
    required this.semanticsLabel,
    required this.semanticsHint,
  });

  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final VoidCallback onLongPressConfirmed;
  final bool isEmergencyActive;
  final String? semanticsLabel;
  final String? semanticsHint;

  @override
  State<_EmergencyButtonBody> createState() => _EmergencyButtonBodyState();
}

class _EmergencyButtonBodyState extends State<_EmergencyButtonBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticsLabel ?? widget.title,
      hint: widget.semanticsHint,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.heavyImpact();
            widget.onPressed();
          },
          onLongPress: widget.onLongPressConfirmed,
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.isEmergencyActive)
                ScaleTransition(
                  scale: Tween<double>(
                    begin: 1,
                    end: 1.08,
                  ).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                  child: Container(
                    height: 104,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.emergency.withValues(alpha: 0.45),
                        width: 4,
                      ),
                    ),
                  ),
                ),
              Ink(
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.emergency,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emergency.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.health_and_safety_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.4,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
