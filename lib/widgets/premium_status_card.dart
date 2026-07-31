import 'package:flutter/material.dart';

import '../features/premium/premium_perk.dart';
import '../features/premium/premium_perk_navigator.dart';
import '../models/family_models.dart';
import '../models/user_model.dart';
import '../features/premium/manage_billing_helper.dart';
import '../services/premium_service.dart';

/// Slim premium status row with a single "View benefits" CTA that opens a
/// bottom sheet listing all perks. Replaces the verbose inline perk chips.
class PremiumStatusCard extends StatelessWidget {
  const PremiumStatusCard({
    super.key,
    required this.role,
    required this.summary,
    this.linkedUser,
    this.onFamilyTab,
    this.onVolunteerTab,
  });

  /// e.g. "25 km · Jobs · 1.5× points".
  final String summary;
  final UserRole role;
  final LinkedUser? linkedUser;
  final void Function(int tabIndex)? onFamilyTab;
  final void Function(int tabIndex)? onVolunteerTab;

  static const _purple = Color(0xFF7C3AED);
  static const _purpleDark = Color(0xFF5B21B6);
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

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openSheet(context),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_purpleDark, _purple],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _purple.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _gold, width: 1.2),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: _gold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Premium active',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Benefits',
                          style: TextStyle(
                            color: _purpleDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded,
                            color: _purpleDark, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSheet(BuildContext context) {
    final perks = role == UserRole.family
        ? PremiumPerkNavigator.familyPerks()
        : PremiumPerkNavigator.volunteerPerks();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _PerksSheet(
        role: role,
        perks: perks,
        linkedUser: linkedUser,
        onFamilyTab: onFamilyTab,
        onVolunteerTab: onVolunteerTab,
      ),
    );
  }
}

class _PerksSheet extends StatelessWidget {
  const _PerksSheet({
    required this.role,
    required this.perks,
    this.linkedUser,
    this.onFamilyTab,
    this.onVolunteerTab,
  });

  final UserRole role;
  final List<PremiumPerk> perks;
  final LinkedUser? linkedUser;
  final void Function(int tabIndex)? onFamilyTab;
  final void Function(int tabIndex)? onVolunteerTab;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      color: Color(0xFFFFB300), size: 22),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Premium benefits',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tap any perk to open it.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => handleManageBilling(context, role: role),
                  icon: const Icon(Icons.credit_card_rounded, size: 18),
                  label: const Text('Manage subscription & payment method'),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
                itemCount: perks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final p = perks[i];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        Navigator.of(context).maybePop();
                        PremiumPerkNavigator.open(
                          context,
                          role: role,
                          perk: p,
                          linkedUser: linkedUser,
                          onFamilyTab: onFamilyTab,
                          onVolunteerTab: onVolunteerTab,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(p.icon,
                                  color: const Color(0xFF7C3AED), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (p.subtitle != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      p.subtitle!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Color(0xFF9CA3AF)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
