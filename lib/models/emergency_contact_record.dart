// ignore_for_file: public_member_api_docs

/// Shape for optional `emergency_contacts` table.
class EmergencyContactRecord {
  const EmergencyContactRecord({
    required this.id,
    required this.userId,
    required this.name,
    required this.relationship,
    required this.phone,
    required this.priority,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String relationship;
  final String phone;
  final int priority;
  final DateTime createdAt;

  Map<String, dynamic> toInsertJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'priority': priority,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}
