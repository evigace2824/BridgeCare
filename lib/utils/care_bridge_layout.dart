import 'package:flutter/material.dart';

/// Shared spacing so scrollable tab bodies clear the custom bottom bar and
/// system gesture inset on phones (§13 mobile-first).
abstract final class CareBridgeLayout {
  CareBridgeLayout._();

  /// Material accessibility guideline — use for custom hit targets.
  static const double minTouchTarget = 48;

  /// Bottom nav row should feel easy to tap (thumbs, reduced dexterity).
  static const double bottomNavTouchMinHeight = 56;

  /// Approximate height of the patient shell bottom bar (icons + labels +
  /// vertical padding), excluding system safe area.
  static const double bottomNavContentHeight = 80;

  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 600) return 28;
    if (w >= 400) return 22;
    return 20;
  }

  /// Bottom inset for tab [ListView] / [CustomScrollView] padding so content
  /// is not obscured by the bottom navigation bar.
  static double tabScrollBottomInset(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return safe + bottomNavContentHeight + 12;
  }

  static EdgeInsets tabScreenPadding(BuildContext context, {double top = 16}) {
    final h = horizontalPadding(context);
    return EdgeInsets.fromLTRB(h, top, h, tabScrollBottomInset(context));
  }
}
