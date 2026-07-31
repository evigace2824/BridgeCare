import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../premium/premium_plans_screen.dart';
import 'family_plan_store.dart';
import 'subscription_page_clean.dart';

/// Eye-catching Premium upsell banner used across the family dashboard.
///
/// Two compact variants:
///   • [variant]: SpotlightVariant.large — full hero ad on the home tab.
///   • [variant]: SpotlightVariant.compact — slim chip-style ad for inline
///     placement inside cards / sections (chat, reports, etc.).
///
/// Tapping the banner opens [SubscriptionPage]. Hides itself for users who
/// already have Pro/Premium, and instead shows a small "manage plan" pill.
enum SpotlightVariant { large, compact }

class FamilyPremiumSpotlight extends StatefulWidget {
  const FamilyPremiumSpotlight({
    super.key,
    this.variant = SpotlightVariant.large,
    this.angle = SpotlightAngle.alerts,
  });

  final SpotlightVariant variant;
  final SpotlightAngle angle;

  @override
  State<FamilyPremiumSpotlight> createState() => _FamilyPremiumSpotlightState();
}

/// Different sales pitches keyed to the dashboard area we're rendering in.
enum SpotlightAngle {
  alerts, // home page
  health, // health page / vitals
  reports, // reports tab
  chat, // chat tab
  location, // location tab
}

class _FamilyPremiumSpotlightState extends State<FamilyPremiumSpotlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  ({String headline, String sub, IconData icon, List<String> chips})
      _copyForAngle() {
    switch (widget.angle) {
      case SpotlightAngle.alerts:
        return (
          headline: 'Catch problems before they happen',
          sub:
              'Smart alerts, AI fall detection & 24/7 priority support — try Premium.',
          icon: Icons.notifications_active_rounded,
          chips: ['Smart alerts', 'AI insights', 'Priority support'],
        );
      case SpotlightAngle.health:
        return (
          headline: 'Deeper health insights',
          sub:
              'Trend lines, weekly PDF reports & doctor-ready summaries on Pro.',
          icon: Icons.monitor_heart_rounded,
          chips: ['Trend graphs', 'Weekly PDFs', 'Vitals export'],
        );
      case SpotlightAngle.reports:
        return (
          headline: 'Share PDF reports with the doctor',
          sub:
              'Premium unlocks full reports, exports and longer history.',
          icon: Icons.bar_chart_rounded,
          chips: ['PDF export', '365-day history', 'Custom ranges'],
        );
      case SpotlightAngle.chat:
        return (
          headline: 'Voice notes, photos & translations',
          sub:
              'Premium chat adds voice notes, photo sharing and live translation.',
          icon: Icons.chat_bubble_rounded,
          chips: ['Voice notes', 'Photos', 'Translate'],
        );
      case SpotlightAngle.location:
        return (
          headline: 'Geofence safe-zones with alerts',
          sub:
              'Get notified the moment they leave home or arrive somewhere.',
          icon: Icons.location_on_rounded,
          chips: ['Safe-zones', 'Arrival alerts', 'Live history'],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: FamilyPlanStore.instance,
      builder: (context, _) {
        final plan = FamilyPlanStore.instance.plan;
        if (plan.familyHasPremiumFeatures) {
          return _ManagePlanPill(plan: plan);
        }
        if (widget.variant == SpotlightVariant.compact) {
          return _buildCompact(context);
        }
        return _buildLarge(context);
      },
    );
  }

  void _openSubscription(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const PremiumPlansScreen(role: UserRole.family),
    ));
  }

  // ─── Large ad ──────────────────────────────────────────────────────────

  Widget _buildLarge(BuildContext context) {
    final copy = _copyForAngle();
    return GestureDetector(
      onTap: () => _openSubscription(context),
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.40),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Animated gradient base
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: const [
                          Color(0xFF1565C0),
                          Color(0xFF5B21B6),
                          Color(0xFFA855F7),
                        ],
                        stops: [
                          (0.0 + _shimmer.value * 0.05).clamp(0.0, 1.0),
                          (0.5 + _shimmer.value * 0.05).clamp(0.0, 1.0),
                          1.0,
                        ],
                      ),
                    ),
                    child: child,
                  ),
                  // Diagonal sweep
                  Positioned.fill(
                    child: IgnorePointer(
                      child: FractionalTranslation(
                        translation: Offset(-1.0 + _shimmer.value * 2.2, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.16),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.45, 0.5, 0.55],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.45),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(copy.icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PREMIUM',
                          style: TextStyle(
                            color: Color(0xFF5B21B6),
                            fontWeight: FontWeight.w900,
                            fontSize: 9.5,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '50% OFF',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 9.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    copy.headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      height: 1.2,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    copy.sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11.8,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: copy.chips
                        .map((c) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.40)),
                              ),
                              child: Text(
                                c,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10.5,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Column(
                children: [
                  Text(
                    '\$19.99',
                    style: TextStyle(
                      color: Color(0xFF5B21B6),
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'a month',
                    style: TextStyle(
                      color: Color(0xFF5B21B6),
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Compact ad ────────────────────────────────────────────────────────

  Widget _buildCompact(BuildContext context) {
    final copy = _copyForAngle();
    return GestureDetector(
      onTap: () => _openSubscription(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(copy.icon, color: Colors.white, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    copy.headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Tap to see Premium plans',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ManagePlanPill extends StatelessWidget {
  const _ManagePlanPill({required this.plan});
  final UserPlan plan;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.familyHasPremiumFeatures;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PremiumPlansScreen(role: UserRole.family),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPremium
                ? const [Color(0xFF5B21B6), Color(0xFFA855F7)]
                : const [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (isPremium
                      ? const Color(0xFF7C3AED)
                      : const Color(0xFF1565C0))
                  .withValues(alpha: 0.30),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium plan active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    '48h job posts · reports · up to ${UserPlan.premium.familyMaxSafeZones} safe zones · ${UserPlan.premium.familyMaxLinkedProfilesHint} caregivers',
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
