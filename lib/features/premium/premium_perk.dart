import 'package:flutter/material.dart';

/// Identifies each tappable premium perk chip.
enum PremiumPerkId {
  // Family
  familyJobPosts,
  familyWeeklyReports,
  familyHealthMonitoring,
  familyAdvancedAlerts,
  familyCaregivers,
  familySafeZones,
  // Volunteer
  volunteerRadius,
  volunteerPriorityQueue,
  volunteerImpactPoints,
  volunteerBadges,
  volunteerJobPosts,
}

/// One interactive premium perk chip.
class PremiumPerk {
  const PremiumPerk({
    required this.id,
    required this.icon,
    required this.label,
    this.subtitle,
  });

  final PremiumPerkId id;
  final IconData icon;
  final String label;
  final String? subtitle;
}
