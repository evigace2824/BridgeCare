import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../features/family/family_plan_store.dart';
import '../../features/volunteer/data/volunteer_store.dart';
import '../../models/family_models.dart';
import '../../models/user_model.dart';
import 'premium_perk.dart';
import 'screens/premium_alerts_screen.dart';
import 'screens/premium_family_sharing_screen.dart';
import 'screens/premium_health_hub_screen.dart';
import 'screens/premium_job_hub_screen.dart';
import 'screens/premium_safe_zones_screen.dart';
import 'screens/premium_volunteer_perk_screen.dart';
import 'screens/premium_weekly_report_screen.dart';

/// Routes premium perk taps to real screens and tab switches.
class PremiumPerkNavigator {
  PremiumPerkNavigator._();

  static Future<void> open(
    BuildContext context, {
    required UserRole role,
    required PremiumPerk perk,
    LinkedUser? linkedUser,
    void Function(int tabIndex)? onFamilyTab,
    void Function(int tabIndex)? onVolunteerTab,
  }) async {
    await HapticFeedback.lightImpact();

    if (role == UserRole.family) {
      await _openFamily(
        context,
        perk: perk,
        linkedUser: linkedUser,
        onTab: onFamilyTab,
      );
    } else {
      await _openVolunteer(
        context,
        perk: perk,
        onTab: onVolunteerTab,
      );
    }
  }

  static Future<void> _openFamily(
    BuildContext context, {
    required PremiumPerk perk,
    LinkedUser? linkedUser,
    void Function(int tabIndex)? onTab,
  }) async {
    switch (perk.id) {
      case PremiumPerkId.familyJobPosts:
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const PremiumJobHubScreen()),
        );
        break;
      case PremiumPerkId.familyWeeklyReports:
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => PremiumWeeklyReportScreen(linkedUser: linkedUser),
          ),
        );
        break;
      case PremiumPerkId.familyHealthMonitoring:
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => PremiumHealthHubScreen(linkedUser: linkedUser),
          ),
        );
        break;
      case PremiumPerkId.familyAdvancedAlerts:
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => PremiumAlertsScreen(linkedUser: linkedUser),
          ),
        );
        break;
      case PremiumPerkId.familyCaregivers:
        await Navigator.push<void>(
          context,
          MaterialPageRoute(builder: (_) => const PremiumFamilySharingScreen()),
        );
        break;
      case PremiumPerkId.familySafeZones:
        if (onTab != null) {
          onTab(1);
          if (context.mounted) {
            _snack(context, 'Location opened — manage your safe zones');
          }
        }
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => PremiumSafeZonesScreen(linkedUser: linkedUser),
          ),
        );
        break;
      default:
        break;
    }
  }

  static Future<void> _openVolunteer(
    BuildContext context, {
    required PremiumPerk perk,
    void Function(int tabIndex)? onTab,
  }) async {
    switch (perk.id) {
      case PremiumPerkId.volunteerRadius:
        if (context.mounted) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (ctx) => PremiumVolunteerPerkScreen(
                title: 'Extended search radius',
                icon: Icons.explore_rounded,
                heroColor: const Color(0xFF1A6BD8),
                body:
                    'Premium unlocks up to ${VolunteerStore.instance.currentPlan.maxRadiusCapKm.toStringAsFixed(0)} km. '
                    'Adjust your radius in Profile — more families and job posts will appear.',
                primaryAction: 'Open profile settings',
                onPrimary: () {
                  Navigator.pop(ctx);
                  onTab?.call(4);
                },
              ),
            ),
          );
        }
        break;
      case PremiumPerkId.volunteerPriorityQueue:
        if (context.mounted) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (ctx) => PremiumVolunteerPerkScreen(
                title: 'Priority request queue',
                icon: Icons.flash_on_rounded,
                heroColor: const Color(0xFF7C3AED),
                body:
                    'You see new assistance requests and premium 48-hour family jobs '
                    'before free volunteers. Premium jobs are labeled and sorted first.',
                primaryAction: 'View requests',
                onPrimary: () {
                  Navigator.pop(ctx);
                  onTab?.call(1);
                },
              ),
            ),
          );
        }
        break;
      case PremiumPerkId.volunteerImpactPoints:
        onTab?.call(3);
        if (context.mounted) {
          _snack(context, 'Impact dashboard — earning 1.5× points on every task');
          onTab?.call(3);
        }
        break;
      case PremiumPerkId.volunteerBadges:
        if (context.mounted) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (ctx) => PremiumVolunteerPerkScreen(
                title: 'Advanced impact badges',
                icon: Icons.emoji_events_rounded,
                heroColor: const Color(0xFFFFB300),
                body:
                    'Premium unlocks exclusive badges including Rapid Responder, '
                    'Community Hero, and streak achievements.',
                primaryAction: 'View badges',
                onPrimary: () {
                  Navigator.pop(ctx);
                  onTab?.call(3);
                },
              ),
            ),
          );
        }
        break;
      case PremiumPerkId.volunteerJobPosts:
        onTab?.call(1);
        if (context.mounted) {
          _snack(context, 'Premium family jobs — active for 48 hours');
          onTab?.call(1);
        }
        break;
      default:
        break;
    }
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static List<PremiumPerk> familyPerks() {
    final p = FamilyPlanStore.instance.plan;
    return [
      const PremiumPerk(
        id: PremiumPerkId.familyJobPosts,
        icon: Icons.work_history_rounded,
        label: '48h job posts',
        subtitle: 'Post & track',
      ),
      const PremiumPerk(
        id: PremiumPerkId.familyWeeklyReports,
        icon: Icons.bar_chart_rounded,
        label: 'Weekly reports',
        subtitle: 'PDF-ready',
      ),
      const PremiumPerk(
        id: PremiumPerkId.familyHealthMonitoring,
        icon: Icons.monitor_heart_rounded,
        label: 'Health hub',
        subtitle: 'Full vitals',
      ),
      const PremiumPerk(
        id: PremiumPerkId.familyAdvancedAlerts,
        icon: Icons.notifications_active_rounded,
        label: 'Smart alerts',
        subtitle: 'Priority',
      ),
      PremiumPerk(
        id: PremiumPerkId.familyCaregivers,
        icon: Icons.people_rounded,
        label: '${p.familyMaxLinkedProfilesHint} caregivers',
        subtitle: 'Sharing',
      ),
      PremiumPerk(
        id: PremiumPerkId.familySafeZones,
        icon: Icons.location_on_rounded,
        label: '${p.familyMaxSafeZones} safe zones',
        subtitle: 'Geofence',
      ),
    ];
  }

  static List<PremiumPerk> volunteerPerks() {
    final s = VolunteerStore.instance;
    return [
      PremiumPerk(
        id: PremiumPerkId.volunteerRadius,
        icon: Icons.explore_rounded,
        label: '${s.maxRadiusKm.toStringAsFixed(0)} km radius',
        subtitle: 'Wider reach',
      ),
      const PremiumPerk(
        id: PremiumPerkId.volunteerPriorityQueue,
        icon: Icons.flash_on_rounded,
        label: 'Priority queue',
        subtitle: 'See first',
      ),
      const PremiumPerk(
        id: PremiumPerkId.volunteerImpactPoints,
        icon: Icons.trending_up_rounded,
        label: '1.5× points',
        subtitle: 'Impact',
      ),
      const PremiumPerk(
        id: PremiumPerkId.volunteerBadges,
        icon: Icons.emoji_events_rounded,
        label: 'Badges',
        subtitle: 'Unlocked',
      ),
      const PremiumPerk(
        id: PremiumPerkId.volunteerJobPosts,
        icon: Icons.campaign_rounded,
        label: 'Premium jobs',
        subtitle: '48h posts',
      ),
    ];
  }
}
