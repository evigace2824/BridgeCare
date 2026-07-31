import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_theme.dart';

/// Full-width primary action — wraps [FilledButton] with BridgeCare sizing.
class CareBridgePrimaryButton extends StatelessWidget {
  const CareBridgePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.minimumHeight = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double minimumHeight;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
    );

    return SizedBox(
      width: double.infinity,
      height: minimumHeight,
      child: icon != null
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 22),
              label: child,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: child,
            ),
    );
  }
}
