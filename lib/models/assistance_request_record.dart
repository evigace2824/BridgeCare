// ignore_for_file: public_member_api_docs

/// Shape for optional `assistance_requests` table.
class AssistanceRequestRecord {
  const AssistanceRequestRecord({
    required this.id,
    required this.userId,
    required this.type,
    this.details,
    required this.preferredTime,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;

  /// e.g. `grocery`, `medical`, …
  final String type;
  final String? details;

  /// Serialized preference: `today`, `tomorrow`, `custom:<iso8601>`
  final String preferredTime;

  /// e.g. `pending`, `accepted`, `completed`
  final String status;
  final DateTime createdAt;

  Map<String, dynamic> toInsertJson() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'details': details,
        'preferred_time': preferredTime,
        'status': status,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
