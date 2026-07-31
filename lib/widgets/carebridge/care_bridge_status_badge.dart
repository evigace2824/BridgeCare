import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Compact pill for Normal / Warning / Emergency / custom workflow labels.
class CareBridgeStatusBadge extends StatelessWidget {
  const CareBridgeStatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.dense = false,
    this.leadingDot = false,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final bool dense;
  final bool leadingDot;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.12);
    final padH = dense ? 8.0 : 10.0;
    final padV = dense ? 3.0 : 5.0;
    final fontSize = dense ? 11.0 : 12.0;
    final iconSize = dense ? 12.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingDot) ...[
            Container(
              width: dense ? 8 : 10,
              height: dense ? 8 : 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: dense ? 6 : 8),
          ],
          if (icon != null && !leadingDot) ...[
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
