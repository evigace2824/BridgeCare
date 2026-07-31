// ignore_for_file: public_member_api_docs

/// Shape for optional `reminders` table rows (Supabase).
///
/// Column names are conventional; if your project schema differs, adjust
/// [ReminderSyncService] mapping — local demo state continues to work without DB.
class ReminderRecord {
  const ReminderRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.scheduledAt,
    this.notes,
    required this.status,
    required this.createdAt,
    this.repeatRule,
  });

  final String id;
  final String userId;
  final String title;

  /// e.g. `medication`, `appointment`, `daily_task`
  final String type;
  final DateTime scheduledAt;
  final String? notes;

  /// e.g. `pending`, `completed`
  final String status;
  final DateTime createdAt;

  /// e.g. `none`, `daily`
  final String? repeatRule;

  Map<String, dynamic> toInsertJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'type': type,
        // Common variants: scheduled_at vs date+time columns — service tries both patterns via separate attempts if needed.
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'notes': notes,
        'status': status,
        'created_at': createdAt.toUtc().toIso8601String(),
        'repeat_rule': repeatRule,
      };
}
