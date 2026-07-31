/// Volunteer premium preferences (persisted locally / TODO Supabase extras).
class VolunteerPremiumSettings {
  const VolunteerPremiumSettings({
    this.maxRadiusKm = 5,
    this.preferredJobCategories = const [],
    this.availabilitySchedule = const ['Weekday mornings', 'Weekend afternoons'],
    this.transport = 'On foot',
    this.urgentJobAlerts = true,
    this.nearbyJobAlerts = true,
  });

  final double maxRadiusKm;
  final List<String> preferredJobCategories;
  final List<String> availabilitySchedule;
  final String transport;
  final bool urgentJobAlerts;
  final bool nearbyJobAlerts;

  static const defaultCategories = [
    'Elderly care',
    'Medical visit',
    'Pharmacy',
    'Groceries',
    'Home assistance',
    'General help',
  ];

  static const transportOptions = [
    'On foot',
    'Bicycle',
    'Car',
    'Public transit',
  ];

  VolunteerPremiumSettings copyWith({
    double? maxRadiusKm,
    List<String>? preferredJobCategories,
    List<String>? availabilitySchedule,
    String? transport,
    bool? urgentJobAlerts,
    bool? nearbyJobAlerts,
  }) {
    return VolunteerPremiumSettings(
      maxRadiusKm: maxRadiusKm ?? this.maxRadiusKm,
      preferredJobCategories:
          preferredJobCategories ?? this.preferredJobCategories,
      availabilitySchedule:
          availabilitySchedule ?? this.availabilitySchedule,
      transport: transport ?? this.transport,
      urgentJobAlerts: urgentJobAlerts ?? this.urgentJobAlerts,
      nearbyJobAlerts: nearbyJobAlerts ?? this.nearbyJobAlerts,
    );
  }

  Map<String, dynamic> toMap() => {
        'max_radius_km': maxRadiusKm,
        'preferred_job_categories': preferredJobCategories,
        'availability_schedule': availabilitySchedule,
        'transport': transport,
        'urgent_job_alerts': urgentJobAlerts,
        'nearby_job_alerts': nearbyJobAlerts,
      };

  factory VolunteerPremiumSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) return const VolunteerPremiumSettings();
    return VolunteerPremiumSettings(
      maxRadiusKm: (map['max_radius_km'] as num?)?.toDouble() ?? 5,
      preferredJobCategories: (map['preferred_job_categories'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      availabilitySchedule: (map['availability_schedule'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Weekday mornings', 'Weekend afternoons'],
      transport: map['transport']?.toString() ?? 'On foot',
      urgentJobAlerts: map['urgent_job_alerts'] as bool? ?? true,
      nearbyJobAlerts: map['nearby_job_alerts'] as bool? ?? true,
    );
  }
}
