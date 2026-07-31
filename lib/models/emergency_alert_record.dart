// ignore_for_file: public_member_api_docs

/// Row shape for `emergency_alerts` (Supabase). Used by [EmergencyAlertService].
///
/// Fields mirror the expected schema; GPS is optional — see TODO in service.
class EmergencyAlertRecord {
  const EmergencyAlertRecord({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.locationLat,
    this.locationLng,
    this.notifiedFamily = false,
    this.notifiedVolunteers = false,
  });

  final String id;
  final String userId;

  /// e.g. `sent`, `delivered` — local demo uses `sent`.
  final String status;
  final DateTime createdAt;
  final double? locationLat;
  final double? locationLng;
  final bool notifiedFamily;
  final bool notifiedVolunteers;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'status': status,
        'created_at': createdAt.toUtc().toIso8601String(),
        'location_lat': locationLat,
        'location_lng': locationLng,
        'notified_family': notifiedFamily,
        'notified_volunteers': notifiedVolunteers,
      };
}
