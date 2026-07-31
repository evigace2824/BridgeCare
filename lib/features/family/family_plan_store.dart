import 'package:flutter/foundation.dart';

import '../../models/subscription_model.dart';
import 'subscription_page_clean.dart';

/// Feature flags / limits keyed off [UserPlan] so upgrading changes real behavior,
/// not just marketing banners.
extension FamilyPlanTier on UserPlan {
  bool get familyHasPaidFeatures => this == UserPlan.premium || this == UserPlan.pro;

  /// Premium-only features (job posting 48h, multi-caregiver, advanced alerts).
  bool get familyHasPremiumFeatures => this == UserPlan.premium;

  /// Firehose Supabase Postgres streams (`users`, `location_history`) for patient
  /// coords — caregiver safety behaves like volunteer “live”; poll interval still
  /// varies slightly by tier.
  bool get familyRealtimeLocationEnabled => true;

  Duration get familyLocationPollInterval => switch (this) {
        UserPlan.free => const Duration(seconds: 5),
        UserPlan.pro => const Duration(seconds: 2),
        UserPlan.premium => const Duration(seconds: 2),
      };

  /// Max simultaneous geofences on the family location screen.
  int get familyMaxSafeZones => switch (this) {
        UserPlan.free => 2,
        UserPlan.pro => 6,
        UserPlan.premium => 14,
      };

  int get familyMaxLocationTrailPoints => switch (this) {
        UserPlan.free => 12,
        UserPlan.pro => 40,
        UserPlan.premium => 85,
      };

  bool get familyWeeklyVitalChartsUnlocked => familyHasPremiumFeatures;

  bool get familyWeeklyReportsUnlocked => familyHasPremiumFeatures;

  bool get familyAdvancedAlertsUnlocked => familyHasPremiumFeatures;

  bool get familyFullHealthMonitoring => familyHasPremiumFeatures;

  bool get familySharingUnlocked => familyHasPremiumFeatures;

  bool get familyJobPostingUnlocked => familyHasPremiumFeatures;

  bool get familySafeZonesUnlocked => familyHasPremiumFeatures;

  bool get familyPriorityNotificationsUnlocked => familyHasPremiumFeatures;

  /// Premium positioning (multi-care-recipient) — surfaced in UI; linking flow may still be single-user.
  int get familyMaxLinkedProfilesHint => switch (this) {
        UserPlan.free => 1,
        UserPlan.pro => 1,
        UserPlan.premium => 5,
      };
}

/// Tiny in-memory plan store for the family side.
/// Notifies listeners so banners across the dashboard re-render when the
/// user upgrades or downgrades.
class FamilyPlanStore extends ChangeNotifier {
  FamilyPlanStore._();
  static final FamilyPlanStore instance = FamilyPlanStore._();

  UserPlan _plan = UserPlan.free;
  UserPlan get plan => _plan;

  void setPlan(UserPlan p) {
    if (_plan == p) return;
    _plan = p;
    notifyListeners();
  }

  /// Called by [PremiumService] after Supabase load or payment success.
  void applySubscription(SubscriptionModel sub) {
    final next = sub.isPremium ? UserPlan.premium : UserPlan.free;
    if (_plan != next) {
      _plan = next;
      notifyListeners();
    }
  }
}
