import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

/// Small centered BridgeCare wordmark used at the top of auth screens
/// (Login / Signup / Verify email).
///
/// Renders as a quiet brand bar — large enough to be recognizable, small
/// enough not to compete with the screen heading.
class BrandLogoHeader extends StatelessWidget {
  const BrandLogoHeader({
    super.key,
    this.height = 88,
    this.padding = const EdgeInsets.only(top: 8, bottom: 16),
  });

  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: Image.asset(
          'assets/bridgecare_logo.png',
          height: height,
          fit: BoxFit.contain,
          color: AppColors.background,
          colorBlendMode: BlendMode.multiply,
          semanticLabel: 'BridgeCare',
        ),
      ),
    );
  }
}
