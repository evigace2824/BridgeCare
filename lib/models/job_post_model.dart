/// Status of a premium family job post (48-hour window).
///
/// Flow: Active → (volunteer applies) → Accepted → In Progress → Completed → Confirmed
enum JobPostStatus {
  active,
  accepted,
  inProgress,
  completed,
  confirmed,
  expired,
}

/// Urgency for caregiver job posts.
enum JobUrgency {
  low,
  medium,
  high,
  urgent,
}

/// Standard care types for premium job posts.
abstract final class JobPostCareTypes {
  static const elderlyCareVisit = 'Elderly care visit';
  static const medicalVisitSupport = 'Medical visit support';
  static const pharmacyPickup = 'Pharmacy pickup';
  static const groceries = 'Groceries';
  static const homeAssistance = 'Home assistance';
  static const transportation = 'Transportation help';
  static const companionVisit = 'Companion visit';

  /// Legacy alias for dropdown default.
  static const elderlyCare = elderlyCareVisit;

  static const List<String> all = [
    elderlyCareVisit,
    medicalVisitSupport,
    pharmacyPickup,
    groceries,
    homeAssistance,
    transportation,
    companionVisit,
  ];
}

/// Premium-only care job visible to verified volunteers for 48 hours.
class JobPostModel {
  JobPostModel({
    required this.id,
    required this.title,
    required this.careType,
    required this.description,
    required this.location,
    required this.preferredAt,
    required this.durationLabel,
    required this.urgency,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.budget,
    this.linkedElderlyUserId,
    this.linkedElderlyName,
    this.status = JobPostStatus.active,
    this.acceptedByVolunteerId,
  });

  final String id;
  final String title;
  final String careType;
  final String description;
  final String location;
  final DateTime preferredAt;
  final String durationLabel;
  final JobUrgency urgency;
  final String? budget;
  final String? linkedElderlyUserId;
  final String? linkedElderlyName;
  final String createdBy;
  final DateTime createdAt;
  final DateTime expiresAt;
  JobPostStatus status;
  final String? acceptedByVolunteerId;

  static const Duration activeDuration = Duration(hours: 48);

  /// Effective status including automatic 48h expiry (terminal states preserved).
  JobPostStatus get effectiveStatus {
    if (status == JobPostStatus.confirmed) return JobPostStatus.confirmed;
    if (status == JobPostStatus.completed) return JobPostStatus.completed;
    if (DateTime.now().isAfter(expiresAt)) return JobPostStatus.expired;
    return status;
  }

  /// Open for new volunteer applications.
  bool get acceptsApplications =>
      effectiveStatus == JobPostStatus.active;

  String get statusLabel => switch (effectiveStatus) {
        JobPostStatus.active => 'Active',
        JobPostStatus.accepted => 'Accepted',
        JobPostStatus.inProgress => 'In progress',
        JobPostStatus.completed => 'Completed',
        JobPostStatus.confirmed => 'Confirmed',
        JobPostStatus.expired => 'Expired',
      };

  Duration get timeRemaining {
    final left = expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  String get remainingLabel {
    final left = timeRemaining;
    if (effectiveStatus == JobPostStatus.expired) return 'Expired';
    if (left == Duration.zero) return 'Expired';
    if (left.inHours >= 1) return '${left.inHours}h left';
    if (left.inMinutes >= 1) return '${left.inMinutes}m left';
    return '<1m left';
  }

  JobPostModel copyWith({
    JobPostStatus? status,
    String? acceptedByVolunteerId,
  }) {
    return JobPostModel(
      id: id,
      title: title,
      careType: careType,
      description: description,
      location: location,
      preferredAt: preferredAt,
      durationLabel: durationLabel,
      urgency: urgency,
      budget: budget,
      linkedElderlyUserId: linkedElderlyUserId,
      linkedElderlyName: linkedElderlyName,
      createdBy: createdBy,
      createdAt: createdAt,
      expiresAt: expiresAt,
      status: status ?? this.status,
      acceptedByVolunteerId:
          acceptedByVolunteerId ?? this.acceptedByVolunteerId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'care_type': careType,
        'description': description,
        'location': location,
        'preferred_at': preferredAt.toIso8601String(),
        'duration_label': durationLabel,
        'urgency': urgency.name,
        'budget': budget,
        'linked_elderly_user_id': linkedElderlyUserId,
        'linked_elderly_name': linkedElderlyName,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'status': switch (status) {
          JobPostStatus.inProgress => 'in_progress',
          JobPostStatus.confirmed => 'confirmed',
          _ => status.name,
        },
        'accepted_by': acceptedByVolunteerId,
      };

  factory JobPostModel.fromMap(Map<String, dynamic> map) {
    return JobPostModel(
      id: map['id'].toString(),
      title: map['title']?.toString() ?? '',
      careType: map['care_type']?.toString() ?? JobPostCareTypes.homeAssistance,
      description: map['description']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      preferredAt: DateTime.tryParse(map['preferred_at']?.toString() ?? '') ??
          DateTime.now(),
      durationLabel: map['duration_label']?.toString() ?? 'Flexible',
      urgency: _parseUrgency(map['urgency']?.toString()),
      budget: map['budget']?.toString(),
      linkedElderlyUserId: map['linked_elderly_user_id']?.toString(),
      linkedElderlyName: map['linked_elderly_name']?.toString(),
      createdBy: map['created_by']?.toString() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      expiresAt: DateTime.tryParse(map['expires_at']?.toString() ?? '') ??
          DateTime.now().add(activeDuration),
      status: _parseStatus(map['status']?.toString()),
      acceptedByVolunteerId: map['accepted_by']?.toString(),
    );
  }

  static JobUrgency _parseUrgency(String? raw) => switch (raw) {
        'low' => JobUrgency.low,
        'high' => JobUrgency.high,
        'urgent' => JobUrgency.urgent,
        _ => JobUrgency.medium,
      };

  static JobPostStatus _parseStatus(String? raw) => switch (raw) {
        'accepted' => JobPostStatus.accepted,
        'in_progress' || 'inprogress' => JobPostStatus.inProgress,
        'completed' => JobPostStatus.completed,
        'confirmed' => JobPostStatus.confirmed,
        'expired' => JobPostStatus.expired,
        _ => JobPostStatus.active,
      };
}
