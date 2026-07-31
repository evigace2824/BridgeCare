import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/volunteer/data/volunteer_models.dart';
import '../models/job_application_model.dart';
import '../models/job_post_model.dart';
import '../models/volunteer_care_profile.dart';
import 'notification_service.dart';

/// Manages premium 48-hour job posts and volunteer applications.
class JobPostService extends ChangeNotifier {
  JobPostService._();
  static final JobPostService instance = JobPostService._();

  final List<JobPostModel> _posts = [];
  final List<JobApplicationModel> _applications = [];

  List<JobPostModel> get allPosts {
    refreshExpirations();
    return List.unmodifiable(_posts);
  }

  List<JobApplicationModel> get allApplications =>
      List.unmodifiable(_applications);

  List<JobPostModel> postsForFamily(String familyUserId) {
    return _posts.where((p) {
      if (p.createdBy == familyUserId) return true;
      // Local/demo posts: show when volunteers have applied so families can review.
      if (p.createdBy == 'family_demo') {
        return applicationsForPost(p.id).isNotEmpty;
      }
      return false;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  JobPostModel? postById(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return _posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Active posts open for new applications.
  List<JobPostModel> get activePostsForVolunteers {
    return _posts.where((p) => p.acceptsApplications).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Jobs a volunteer should see: open posts + posts they applied to or were accepted for.
  List<JobPostModel> postsForVolunteer(String volunteerId) {
    return _posts.where((p) {
      if (p.effectiveStatus == JobPostStatus.expired) {
        return p.acceptedByVolunteerId == volunteerId;
      }
      if (p.acceptsApplications) return true;
      if (p.acceptedByVolunteerId == volunteerId) return true;
      return _applications.any(
        (a) =>
            a.jobPostId == p.id &&
            a.volunteerId == volunteerId &&
            a.status != JobApplicationStatus.rejected,
      );
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  JobApplicationModel? applicationForPost(String postId, String volunteerId) {
    try {
      return _applications.firstWhere(
        (a) => a.jobPostId == postId && a.volunteerId == volunteerId,
      );
    } catch (_) {
      return null;
    }
  }

  bool hasApplied(String postId, String volunteerId) {
    final app = applicationForPost(postId, volunteerId);
    return app != null && app.status == JobApplicationStatus.pending;
  }

  List<JobApplicationModel> applicationsForPost(String postId) {
    return _applications
        .where((a) => a.jobPostId == postId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int pendingApplicationCount(String postId) => _applications
      .where(
        (a) =>
            a.jobPostId == postId &&
            a.status == JobApplicationStatus.pending,
      )
      .length;

  void refreshExpirations() {
    var changed = false;
    for (var i = 0; i < _posts.length; i++) {
      // Expire only if still active with no family acceptance after 48h.
      if (_posts[i].status == JobPostStatus.active &&
          DateTime.now().isAfter(_posts[i].expiresAt)) {
        _posts[i] = _posts[i].copyWith(status: JobPostStatus.expired);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> loadFromRemote() async {
    try {
      final rows = await Supabase.instance.client
          .from('job_posts')
          .select()
          .order('created_at', ascending: false);
      _posts
        ..clear()
        ..addAll(
          (rows as List)
              .map((r) => JobPostModel.fromMap(Map<String, dynamic>.from(r))),
        );
      await _loadApplicationsFromRemote();
      refreshExpirations();
      notifyListeners();
    } catch (_) {
      // TODO: Run `005_job_posts.sql` and `006_job_applications.sql` in Supabase.
      ensureDemoPostsIfEmpty();
    }
    ensureDemoPostsIfEmpty();
  }

  Future<void> _loadApplicationsFromRemote() async {
    try {
      final rows = await Supabase.instance.client
          .from('job_applications')
          .select()
          .order('created_at', ascending: false);
      _applications
        ..clear()
        ..addAll(
          (rows as List).map(
            (r) => JobApplicationModel.fromMap(
              Map<String, dynamic>.from(r),
            ),
          ),
        );
    } catch (_) {
      // In-memory fallback until migration runs.
    }
  }

  void ensureDemoPostsIfEmpty() {
    if (_posts.isNotEmpty) return;
    final now = DateTime.now();
    _posts.addAll([
      JobPostModel(
        id: 'demo_job_1',
        title: 'Weekly grocery & companionship',
        careType: JobPostCareTypes.groceries,
        description:
            'Help Drita with Conad shopping and a short chat at home.',
        location: 'Komuna e Parisit, Tirana',
        preferredAt: now.add(const Duration(hours: 6)),
        durationLabel: '2 hours',
        urgency: JobUrgency.medium,
        budget: '3,000 LEK',
        linkedElderlyName: 'Drita V.',
        createdBy: 'family_demo',
        createdAt: now.subtract(const Duration(hours: 2)),
        expiresAt: now.add(const Duration(hours: 37)),
      ),
      JobPostModel(
        id: 'demo_job_2',
        title: 'Cardiology appointment escort',
        careType: JobPostCareTypes.medicalVisitSupport,
        description: 'Pickup and accompany to Spitali Amerikan. ID required.',
        location: 'Spitali Amerikan, Tirana',
        preferredAt: now.add(const Duration(days: 1, hours: 9)),
        durationLabel: '3 hours',
        urgency: JobUrgency.high,
        linkedElderlyName: 'Albana M.',
        createdBy: 'family_demo',
        createdAt: now.subtract(const Duration(hours: 5)),
        expiresAt: now.add(const Duration(hours: 42)),
      ),
    ]);
    notifyListeners();
  }

  Future<JobPostModel?> createPost({
    required String title,
    required String careType,
    required String description,
    required String location,
    required DateTime preferredAt,
    required String durationLabel,
    required JobUrgency urgency,
    String? budget,
    required String createdBy,
    String? linkedElderlyUserId,
    String? linkedElderlyName,
    String familyDisplayName = 'A family',
  }) async {
    final now = DateTime.now();
    final post = JobPostModel(
      id: 'job_${now.millisecondsSinceEpoch}',
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
      createdAt: now,
      expiresAt: now.add(JobPostModel.activeDuration),
    );

    try {
      await Supabase.instance.client.from('job_posts').insert(post.toMap());
    } catch (_) {}

    _posts.insert(0, post);
    notifyListeners();

    // TODO: Target only verified volunteer user_ids from `public.users`.
    await NotificationService.instance.notifyVolunteersNewJobPost(
      jobId: post.id,
      jobTitle: post.title,
      familyName: familyDisplayName,
      elderlyName: linkedElderlyName,
    );

    return post;
  }

  /// Volunteer applies — does NOT auto-accept the job.
  Future<JobApplicationModel?> applyForJob({
    required String postId,
    required VolunteerCareProfile careProfile,
    required String suitabilityMessage,
    required bool availabilityConfirmed,
    required String transportMethod,
  }) async {
    final postIdx = _posts.indexWhere((p) => p.id == postId);
    if (postIdx == -1) return null;
    final post = _posts[postIdx];
    if (!post.acceptsApplications) return null;
    if (!availabilityConfirmed) return null;

    final existing = applicationForPost(postId, careProfile.volunteerId);
    if (existing != null) return existing;

    final app = JobApplicationModel(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      jobPostId: postId,
      volunteerId: careProfile.volunteerId,
      volunteerName: careProfile.displayName,
      rating: careProfile.rating,
      trustLevel: careProfile.trustLevel,
      verificationStatus: careProfile.verificationStatus,
      completedTasks: careProfile.completedTasks,
      skills: careProfile.skills,
      distanceKm: careProfile.distanceKm,
      transportMethod: transportMethod,
      availabilityConfirmed: availabilityConfirmed,
      message: suitabilityMessage.trim().isEmpty ? null : suitabilityMessage.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await Supabase.instance.client.from('job_applications').insert(app.toMap());
    } catch (_) {}

    _applications.insert(0, app);
    notifyListeners();

    await NotificationService.instance.notifyFamilyVolunteerApplied(
      familyUserId: post.createdBy,
      jobId: post.id,
      jobTitle: post.title,
      volunteerName: careProfile.displayName,
    );

    return app;
  }

  /// Family accepts one volunteer; other pending applications are rejected.
  void acceptApplication(String applicationId) {
    final appIdx = _applications.indexWhere((a) => a.id == applicationId);
    if (appIdx == -1) return;
    final app = _applications[appIdx];
    if (app.status != JobApplicationStatus.pending) return;

    final postIdx = _posts.indexWhere((p) => p.id == app.jobPostId);
    if (postIdx == -1) return;

    _applications[appIdx] =
        app.copyWith(status: JobApplicationStatus.accepted);
    final postTitle = _posts[postIdx].title;
    for (var i = 0; i < _applications.length; i++) {
      if (_applications[i].jobPostId == app.jobPostId &&
          _applications[i].id != applicationId &&
          _applications[i].status == JobApplicationStatus.pending) {
        _applications[i] =
            _applications[i].copyWith(status: JobApplicationStatus.rejected);
        final other = _applications[i];
        NotificationService.instance.notifyVolunteerApplicationRejected(
          volunteerUserId: other.volunteerId,
          jobTitle: postTitle,
        );
      }
    }

    _posts[postIdx] = _posts[postIdx].copyWith(
      status: JobPostStatus.accepted,
      acceptedByVolunteerId: app.volunteerId,
    );

    _persistApplication(appIdx);
    _persistPost(postIdx);
    notifyListeners();

    final post = _posts[postIdx];
    NotificationService.instance.notifyVolunteerApplicationAccepted(
      volunteerUserId: app.volunteerId,
      jobTitle: post.title,
    );
  }

  void rejectApplication(String applicationId) {
    final i = _applications.indexWhere((a) => a.id == applicationId);
    if (i == -1) return;
    if (_applications[i].status != JobApplicationStatus.pending) return;
    final app = _applications[i];
    final post = _post(app.jobPostId);
    _applications[i] =
        _applications[i].copyWith(status: JobApplicationStatus.rejected);
    _persistApplication(i);
    notifyListeners();

    if (post != null) {
      NotificationService.instance.notifyVolunteerApplicationRejected(
        volunteerUserId: app.volunteerId,
        jobTitle: post.title,
      );
    }
  }

  bool canVolunteerStart(String postId, String volunteerId) {
    final post = _post(postId);
    return post != null &&
        post.acceptedByVolunteerId == volunteerId &&
        post.effectiveStatus == JobPostStatus.accepted;
  }

  bool canVolunteerComplete(String postId, String volunteerId) {
    final post = _post(postId);
    return post != null &&
        post.acceptedByVolunteerId == volunteerId &&
        post.effectiveStatus == JobPostStatus.inProgress;
  }

  void volunteerStartJob(String postId, String volunteerId) {
    if (!canVolunteerStart(postId, volunteerId)) return;
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i == -1) return;
    _posts[i] = _posts[i].copyWith(status: JobPostStatus.inProgress);
    _persistPost(i);
    notifyListeners();
  }

  void volunteerCompleteJob(String postId, String volunteerId) {
    if (!canVolunteerComplete(postId, volunteerId)) return;
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i == -1) return;
    _posts[i] = _posts[i].copyWith(status: JobPostStatus.completed);
    _persistPost(i);
    notifyListeners();
  }

  bool canFamilyConfirm(String postId) {
    final post = _post(postId);
    return post?.effectiveStatus == JobPostStatus.completed;
  }

  void confirmCompletion(String postId) {
    final i = _posts.indexWhere((p) => p.id == postId);
    if (i == -1) return;
    if (_posts[i].effectiveStatus != JobPostStatus.completed) return;
    _posts[i] = _posts[i].copyWith(status: JobPostStatus.confirmed);
    _persistPost(i);
    notifyListeners();
  }

  JobPostModel? _post(String id) {
    try {
      return _posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistPost(int index) async {
    try {
      await Supabase.instance.client
          .from('job_posts')
          .update(_posts[index].toMap())
          .eq('id', _posts[index].id);
    } catch (_) {}
  }

  Future<void> _persistApplication(int index) async {
    try {
      await Supabase.instance.client
          .from('job_applications')
          .update({'status': _applications[index].status.name})
          .eq('id', _applications[index].id);
    } catch (_) {}
  }

  static String? postIdFromTaskId(String taskId) {
    if (!taskId.startsWith('jobpost_')) return null;
    return taskId.substring('jobpost_'.length);
  }
}

extension JobPostVolunteerMapping on JobPostModel {
  VolunteerTask toVolunteerTask() {
    final urg = switch (urgency) {
      JobUrgency.low => VolunteerUrgency.low,
      JobUrgency.high => VolunteerUrgency.high,
      JobUrgency.urgent => VolunteerUrgency.sos,
      JobUrgency.medium => VolunteerUrgency.medium,
    };
    final who = linkedElderlyName ?? 'Linked care recipient';
    return VolunteerTask(
      id: 'jobpost_$id',
      kind: VolunteerTaskKind.homeHelp,
      title: '📋 $title',
      requesterName: 'Premium job · $who',
      address: location,
      distanceKm: 2.0,
      createdAt: createdAt,
      scheduledFor: preferredAt,
      urgency: urg,
      estimatedMinutes: 120,
      points: 22,
      notes:
          '$careType\n$description\n\nDuration: $durationLabel'
          '${budget != null ? '\nBudget: $budget' : ''}\n⏱ $remainingLabel',
      requesterPhotoColor: const Color(0xFF7C3AED),
    );
  }
}
