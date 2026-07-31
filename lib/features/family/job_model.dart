class Applicant {
  final String userId;
  String status; // pending / accepted / rejected

  Applicant({
    required this.userId,
    this.status = 'pending',
  });
}

class Job {
  final String title;
  final String description;
  final String category;
  final String hours;
  final String salary;
  final bool requiresCertification;
  final bool isUrgent;
  final String createdBy;

  List<Applicant> applicants;

  Job({
    required this.title,
    required this.description,
    required this.category,
    required this.hours,
    required this.salary,
    required this.requiresCertification,
    required this.isUrgent,
    required this.createdBy,
    List<Applicant>? applicants,
  }) : applicants = applicants ?? []; // ✅ always non-null
}