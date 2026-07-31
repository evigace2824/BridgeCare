import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Rounded elevated surface used across BridgeCare patient screens.
class CareBridgeCard extends StatelessWidget {
  const CareBridgeCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 16,
    this.borderColor = AppColors.border,
    this.backgroundColor = AppColors.surface,
    this.showShadow = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color borderColor;
  final Color backgroundColor;
  final bool showShadow;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    Widget core = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    core = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: borderColor),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: core,
    );

    if (onTap != null) {
      core = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: core,
        ),
      );
    }

    return core;
  }
}
