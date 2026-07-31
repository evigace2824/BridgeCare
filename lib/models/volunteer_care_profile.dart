import '../features/volunteer/data/volunteer_store.dart';

/// Care-focused volunteer profile shown to families (not a CV).
class VolunteerCareProfile {
  const VolunteerCareProfile({
    required this.volunteerId,
    required this.displayName,
    required this.verificationStatus,
    required this.trustLevel,
    required this.rating,
    required this.completedTasks,
    required this.skills,
    required this.transportMethod,
    required this.distanceKm,
    this.availabilitySummary = 'Flexible',
    this.city,
  });

  final String volunteerId;
  final String displayName;
  final String verificationStatus;
  final String trustLevel;
  final double rating;
  final int completedTasks;
  final List<String> skills;
  final String transportMethod;
  final double distanceKm;
  final String availabilitySummary;
  final String? city;

  /// Build from local volunteer store (Supabase profile sync can extend this later).
  factory VolunteerCareProfile.fromStore(VolunteerStore store, {String? volunteerId}) {
    final isPremium = store.currentPlan.isPremium;
    return VolunteerCareProfile(
      volunteerId: volunteerId ?? 'volunteer_local',
      displayName: store.volunteerName,
      verificationStatus: isPremium ? 'Verified Premium' : 'Verified',
      trustLevel: isPremium ? 'High trust' : 'Trusted helper',
      rating: 4.5 + (store.stats.tasksCompleted.clamp(0, 20) * 0.02),
      completedTasks: store.stats.tasksCompleted,
      skills: store.skills,
      transportMethod: store.transport,
      distanceKm: 2.0,
      availabilitySummary: store.availabilitySchedule.join(' · '),
      city: store.volunteerCity,
    );
  }
}
