import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/premium/premium_perk.dart';
import '../features/premium/premium_perk_navigator.dart';
import '../models/family_models.dart';
import '../models/user_model.dart';
import '../services/premium_service.dart';

/// Tappable premium perk chips — each opens a real feature screen.
class PremiumFeaturesStrip extends StatelessWidget {
  const PremiumFeaturesStrip({
    super.key,
    required this.role,
    this.linkedUser,
    this.onFamilyTab,
    this.onVolunteerTab,
  });

  final UserRole role;
  final LinkedUser? linkedUser;
  final void Function(int tabIndex)? onFamilyTab;
  final void Function(int tabIndex)? onVolunteerTab;

  static const _purple = Color(0xFF7C3AED);
  static const _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PremiumService.instance,
      builder: (context, _) {
        final isPremium = role == UserRole.family
            ? PremiumService.instance.familyIsPremium
            : PremiumService.instance.volunteerIsPremium;
        if (!isPremium) return const SizedBox.shrink();

        final perks = role == UserRole.family
            ? PremiumPerkNavigator.familyPerks()
            : PremiumPerkNavigator.volunteerPerks();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _purple.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: _gold, size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Premium active — tap a perk to open',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(Icons.touch_app_rounded, color: Colors.white54, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: perks.map((p) => _PerkChip(
                      perk: p,
                      onTap: () => PremiumPerkNavigator.open(
                        context,
                        role: role,
                        perk: p,
                        linkedUser: linkedUser,
                        onFamilyTab: onFamilyTab,
                        onVolunteerTab: onVolunteerTab,
                      ),
                    )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PerkChip extends StatefulWidget {
  const _PerkChip({required this.perk, required this.onTap});

  final PremiumPerk perk;
  final VoidCallback onTap;

  @override
  State<_PerkChip> createState() => _PerkChipState();
}

class _PerkChipState extends State<_PerkChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        child: Material(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.perk.icon, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.perk.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (widget.perk.subtitle != null)
                        Text(
                          widget.perk.subtitle!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
