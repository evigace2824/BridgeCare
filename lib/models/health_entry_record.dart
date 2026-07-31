// ignore_for_file: public_member_api_docs

/// Shape for optional heart-rate rows (`health_entries`, `vitals`, etc.).
class HealthEntryRecord {
  const HealthEntryRecord({
    required this.id,
    required this.userId,
    required this.heartRate,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final int heartRate;

  /// Matches [HealthStatus.name] from patient domain.
  final String status;
  final String? notes;
  final DateTime createdAt;

  Map<String, dynamic> toInsertJson() => {
        'id': id,
        'user_id': userId,
        'heart_rate': heartRate,
        'status': status,
        'notes': notes,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
