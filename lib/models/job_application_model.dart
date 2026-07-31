/// Volunteer application to a premium family job post.
enum JobApplicationStatus {
  pending,
  accepted,
  rejected,
}

class JobApplicationModel {
  JobApplicationModel({
    required this.id,
    required this.jobPostId,
    required this.volunteerId,
    required this.volunteerName,
    required this.createdAt,
    this.status = JobApplicationStatus.pending,
    this.rating = 4.5,
    this.trustLevel = 'Verified',
    this.verificationStatus = 'Verified',
    this.completedTasks = 0,
    this.skills = const [],
    this.distanceKm = 2.0,
    this.transportMethod = 'On foot',
    this.availabilityConfirmed = false,
    this.message,
  });

  final String id;
  final String jobPostId;
  final String volunteerId;
  final String volunteerName;
  final JobApplicationStatus status;
  final double rating;
  final String trustLevel;
  final String verificationStatus;
  final int completedTasks;
  final List<String> skills;
  final double distanceKm;
  final String transportMethod;
  final bool availabilityConfirmed;
  final String? message;
  final DateTime createdAt;

  String get statusLabel => switch (status) {
        JobApplicationStatus.pending => 'Pending review',
        JobApplicationStatus.accepted => 'Accepted',
        JobApplicationStatus.rejected => 'Not selected',
      };

  Map<String, dynamic> toMap() => {
        'id': id,
        'job_post_id': jobPostId,
        'volunteer_id': volunteerId,
        'volunteer_name': volunteerName,
        'status': status.name,
        'rating': rating,
        'trust_level': trustLevel,
        'verification_status': verificationStatus,
        'completed_tasks': completedTasks,
        'skills': skills,
        'distance_km': distanceKm,
        'transport_method': transportMethod,
        'availability_confirmed': availabilityConfirmed,
        'message': message,
        'created_at': createdAt.toIso8601String(),
      };

  factory JobApplicationModel.fromMap(Map<String, dynamic> map) {
    return JobApplicationModel(
      id: map['id'].toString(),
      jobPostId: map['job_post_id']?.toString() ?? '',
      volunteerId: map['volunteer_id']?.toString() ?? '',
      volunteerName: map['volunteer_name']?.toString() ?? 'Volunteer',
      status: _parseStatus(map['status']?.toString()),
      rating: (map['rating'] as num?)?.toDouble() ?? 4.5,
      trustLevel: map['trust_level']?.toString() ?? 'Verified',
      verificationStatus:
          map['verification_status']?.toString() ?? 'Verified',
      completedTasks: (map['completed_tasks'] as num?)?.toInt() ?? 0,
      skills: (map['skills'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      distanceKm: (map['distance_km'] as num?)?.toDouble() ?? 2.0,
      transportMethod: map['transport_method']?.toString() ?? 'On foot',
      availabilityConfirmed: map['availability_confirmed'] == true,
      message: map['message']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static JobApplicationStatus _parseStatus(String? raw) =>
      switch (raw?.toLowerCase()) {
        'accepted' => JobApplicationStatus.accepted,
        'rejected' => JobApplicationStatus.rejected,
        _ => JobApplicationStatus.pending,
      };

  JobApplicationModel copyWith({JobApplicationStatus? status}) {
    return JobApplicationModel(
      id: id,
      jobPostId: jobPostId,
      volunteerId: volunteerId,
      volunteerName: volunteerName,
      createdAt: createdAt,
      status: status ?? this.status,
      rating: rating,
      trustLevel: trustLevel,
      verificationStatus: verificationStatus,
      completedTasks: completedTasks,
      skills: skills,
      distanceKm: distanceKm,
      transportMethod: transportMethod,
      availabilityConfirmed: availabilityConfirmed,
      message: message,
    );
  }
}
