import 'package:flutter/material.dart';

import '../../../../widgets/carebridge/care_bridge_quick_action_card.dart';

/// Home tab quick action — uses shared [CareBridgeQuickActionCard].
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.softColor,
    required this.onTap,
    this.metric,
  });

  final IconData icon;
  final String label;
  final String? metric;
  final Color color;
  final Color softColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CareBridgeQuickActionCard(
      icon: icon,
      label: label,
      metric: metric,
      accentColor: color,
      softAccentColor: softColor,
      onTap: onTap,
    );
  }
}
