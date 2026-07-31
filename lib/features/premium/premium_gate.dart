import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/premium_service.dart';
import 'premium_plans_screen.dart';

/// Shows upgrade prompt or runs [onUnlocked] when user has premium.
class PremiumGate {
  PremiumGate._();

  static bool isPremiumFor(UserRole role) {
    switch (role) {
      case UserRole.family:
        return PremiumService.instance.familyIsPremium;
      case UserRole.volunteer:
        return PremiumService.instance.volunteerIsPremium;
      default:
        return PremiumService.instance.isPremium;
    }
  }

  static Future<void> requirePremium(
    BuildContext context, {
    required UserRole role,
    required String featureName,
    VoidCallback? onUnlocked,
  }) async {
    if (isPremiumFor(role)) {
      onUnlocked?.call();
      return;
    }
    final upgrade = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpgradeSheet(featureName: featureName, role: role),
    );
    if (upgrade == true && context.mounted) {
      onUnlocked?.call();
    }
  }

  static void openPlans(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PremiumPlansScreen(role: role)),
    );
  }
}

class _UpgradeSheet extends StatelessWidget {
  const _UpgradeSheet({required this.featureName, required this.role});

  final String featureName;
  final UserRole role;

  static const _purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Icon(Icons.lock_rounded, color: _purple, size: 40),
          const SizedBox(height: 12),
          Text(
            'Premium feature',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '$featureName is included with BridgeCare Premium.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PremiumPlansScreen(role: role),
                  ),
                );
                if (PremiumGate.isPremiumFor(role) && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View Premium plans'),
            ),
          ),
        ],
      ),
    );
  }
}
