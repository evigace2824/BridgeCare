import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/job_post_model.dart';
import '../../../models/subscription_model.dart';
import '../../../models/volunteer_premium_settings.dart';
import '../../../services/job_post_service.dart';
import 'volunteer_models.dart';

/// Subscription tiers for volunteer accounts.
///
/// Inspired by modern gig / volunteer apps (Strava, Komoot, DoorDash Dasher
/// Plus, Roadie) — tiers unlock convenience and recognition, never block the
/// core public-good features.
enum VolunteerPlan { helper, plus, pro }

extension VolunteerPlanX on VolunteerPlan {
  String get name => switch (this) {
        VolunteerPlan.helper => 'Helper',
        VolunteerPlan.plus => 'Active Helper',
        VolunteerPlan.pro => 'Trusted Hero',
      };

  String get shortName => switch (this) {
        VolunteerPlan.helper => 'Free',
        VolunteerPlan.plus => 'Plus',
        VolunteerPlan.pro => 'Pro',
      };

  bool get isPaid => this != VolunteerPlan.helper;

  bool get isPremium => this == VolunteerPlan.pro;

  /// 1× for Helper, 1.25× for Plus, 1.5× for Pro.
  double get pointsMultiplier => switch (this) {
        VolunteerPlan.helper => 1.0,
        VolunteerPlan.plus => 1.25,
        VolunteerPlan.pro => 1.5,
      };

  /// Hard cap on simultaneous active tasks.
  int get maxConcurrentTasks => switch (this) {
        VolunteerPlan.helper => 3,
        VolunteerPlan.plus => 10,
        VolunteerPlan.pro => 999,
      };

  /// Maximum search radius in km the slider allows.
  double get maxRadiusCapKm => switch (this) {
        VolunteerPlan.helper => 5.0,
        VolunteerPlan.plus => 15.0,
        VolunteerPlan.pro => 25.0,
      };
}

class VolunteerStore extends ChangeNotifier {
  VolunteerStore._() {
    _seed();
  }

  static final VolunteerStore instance = VolunteerStore._();

  // Profile (populated from Supabase on shell init, with sensible defaults)
  String volunteerName = 'Volunteer';
  String volunteerCity = 'Your city';
  String? volunteerEmail;
  bool isAvailableNow = true;
  bool notifyNearby = true;
  bool notifyUrgent = true;
  double maxRadiusKm = 5.0;
  String transport = 'On foot';
  List<String> preferredJobCategories = [];
  List<String> availabilitySchedule = const [
    'Weekday mornings',
    'Weekend afternoons',
  ];
  final Set<String> _awardedPremiumJobIds = {};

  bool hasAppliedToJob(String postId) {
    final volId = Supabase.instance.client.auth.currentUser?.id ?? 'volunteer_local';
    return JobPostService.instance.hasApplied(postId, volId);
  }

  // Subscription
  VolunteerPlan currentPlan = VolunteerPlan.helper;
  bool isYearlyBilling = false;
  DateTime? planRenewsOn;

  void setPlan(VolunteerPlan plan, {bool yearly = false}) {
    currentPlan = plan;
    isYearlyBilling = yearly;
    if (plan == VolunteerPlan.helper) {
      planRenewsOn = null;
    } else {
      planRenewsOn = DateTime.now().add(
        yearly ? const Duration(days: 365) : const Duration(days: 30),
      );
    }
    // Clamp the radius to the new plan's cap.
    if (maxRadiusKm > plan.maxRadiusCapKm) {
      maxRadiusKm = plan.maxRadiusCapKm;
    }
    notifyListeners();
  }

  /// Premium subscription from [PremiumService].
  void applySubscription(SubscriptionModel sub) {
    if (sub.isPremium) {
      setPlan(VolunteerPlan.pro, yearly: sub.billingCycle == BillingCycle.yearly);
      _unlockPremiumBadges();
    } else {
      setPlan(VolunteerPlan.helper);
    }
  }

  void _unlockPremiumBadges() {
    for (var i = 0; i < badges.length; i++) {
      final b = badges[i];
      if (!b.unlocked &&
          (b.id == 'rapid' || b.id == 'community' || b.id == 'streak')) {
        badges[i] = VolunteerBadge(
          id: b.id,
          title: b.title,
          subtitle: b.subtitle,
          icon: b.icon,
          color: b.color,
          unlocked: true,
          progress: b.target,
          target: b.target,
        );
      }
    }
  }

  bool get hasPriorityQueue => currentPlan.isPremium;

  bool get hasAdvancedBadges => currentPlan.isPremium;

  /// Premium jobs use [JobPostService] application flow — not mixed into assistance tasks.
  void syncJobPosts(List<JobPostModel> posts) {
    _tasks.removeWhere((t) => t.id.startsWith('jobpost_'));
    notifyListeners();
  }

  /// Award 1.5× points when family confirms premium job completion.
  void awardPremiumJobPoints(String postId) {
    if (_awardedPremiumJobIds.contains(postId)) return;
    _awardedPremiumJobIds.add(postId);
    final earned = (22 * currentPlan.pointsMultiplier).round();
    _stats = VolunteerImpactStats(
      peopleHelped: _stats.peopleHelped + 1,
      tasksCompleted: _stats.tasksCompleted + 1,
      hoursVolunteered: _stats.hoursVolunteered + 2,
      streakDays: _stats.streakDays,
      points: _stats.points + earned,
      level: _stats.level,
      levelTitle: _stats.levelTitle,
      nextLevelPoints: _stats.nextLevelPoints,
    );
    notifyListeners();
  }
  List<String> skills = const [
    'Grocery shopping',
    'Pharmacy pickup',
    'Doctor accompaniment',
    'Companionship',
    'Tech help',
  ];

  void hydrateFromProfile({
    String? name,
    String? city,
    String? email,
    String? transportLabel,
    List<String>? skillsList,
  }) {
    if (name != null && name.trim().isNotEmpty) {
      volunteerName = name.trim().split(' ').first;
    }
    if (city != null && city.trim().isNotEmpty) volunteerCity = city.trim();
    if (email != null && email.trim().isNotEmpty) volunteerEmail = email.trim();
    if (transportLabel != null && transportLabel.trim().isNotEmpty) {
      transport = transportLabel.trim();
    }
    if (skillsList != null && skillsList.isNotEmpty) {
      skills = List.unmodifiable(skillsList);
    }
    notifyListeners();
  }

  void toggleAvailability() {
    isAvailableNow = !isAvailableNow;
    notifyListeners();
  }

  void setMaxRadius(double v) {
    maxRadiusKm = v.clamp(1.0, currentPlan.maxRadiusCapKm);
    notifyListeners();
  }

  void toggleNotifyNearby(bool v) {
    notifyNearby = v;
    notifyListeners();
  }

  void toggleNotifyUrgent(bool v) {
    notifyUrgent = v;
    notifyListeners();
  }

  void applyPremiumSettings(VolunteerPremiumSettings s) {
    maxRadiusKm = s.maxRadiusKm.clamp(1.0, currentPlan.maxRadiusCapKm);
    preferredJobCategories = List.from(s.preferredJobCategories);
    availabilitySchedule = List.from(s.availabilitySchedule);
    transport = s.transport;
    notifyUrgent = s.urgentJobAlerts;
    notifyNearby = s.nearbyJobAlerts;
    notifyListeners();
  }

  void setPreferredJobCategories(List<String> cats) {
    preferredJobCategories = List.from(cats);
    notifyListeners();
  }

  void setAvailabilitySchedule(List<String> slots) {
    availabilitySchedule = List.from(slots);
    notifyListeners();
  }

  void setTransportMethod(String t) {
    transport = t;
    notifyListeners();
  }

  List<VolunteerTask> get assistanceOpenTasks =>
      openTasks.where((t) => !t.id.startsWith('jobpost_')).toList();

  List<VolunteerTask> get assistanceWithinRadius => openTasks
      .where((t) => !t.id.startsWith('jobpost_'))
      .where((t) => t.distanceKm <= maxRadiusKm)
      .toList();

  // Tasks
  final List<VolunteerTask> _tasks = [];
  List<VolunteerTask> get tasks => List.unmodifiable(_tasks);

  List<VolunteerTask> get openTasks {
    final list = _tasks
        .where((t) => t.status == VolunteerTaskStatus.open)
        .toList();
    if (hasPriorityQueue) {
      list.sort((a, b) {
        final aJob = a.id.startsWith('jobpost_');
        final bJob = b.id.startsWith('jobpost_');
        if (aJob != bJob) return aJob ? -1 : 1;
        return a.distanceKm.compareTo(b.distanceKm);
      });
    } else {
      list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }
    return list;
  }

  /// Assistance + SOS within radius (excludes premium job posts).
  List<VolunteerTask> get openAssistanceNearby => openTasks
      .where((t) => !t.id.startsWith('jobpost_'))
      .where((t) => t.distanceKm <= maxRadiusKm)
      .toList();

  List<VolunteerTask> get urgentAssistanceNearby => _tasks
      .where((t) =>
          !t.id.startsWith('jobpost_') &&
          t.status == VolunteerTaskStatus.open &&
          t.distanceKm <= maxRadiusKm &&
          (t.urgency == VolunteerUrgency.high ||
              t.urgency == VolunteerUrgency.sos))
      .toList();

  List<VolunteerTask> get myTasks => _tasks
      .where((t) =>
          t.status == VolunteerTaskStatus.accepted ||
          t.status == VolunteerTaskStatus.inProgress)
      .toList();

  List<VolunteerTask> get completedTasks =>
      _tasks.where((t) => t.status == VolunteerTaskStatus.completed).toList();

  List<VolunteerTask> get urgentTasks => _tasks
      .where((t) =>
          t.status == VolunteerTaskStatus.open &&
          (t.urgency == VolunteerUrgency.high ||
              t.urgency == VolunteerUrgency.sos))
      .toList();

  void acceptTask(String id) {
    // Premium job posts require family approval — see Requests → Jobs.
    if (id.startsWith('jobpost_')) return;
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    _tasks[i].status = VolunteerTaskStatus.accepted;
    notifyListeners();
  }

  void startTask(String id) {
    if (id.startsWith('jobpost_')) return;
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    _tasks[i].status = VolunteerTaskStatus.inProgress;
    notifyListeners();
  }

  void completeTask(String id) {
    if (id.startsWith('jobpost_')) return;
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    _tasks[i].status = VolunteerTaskStatus.completed;
    final earnedPoints =
        (_tasks[i].points * currentPlan.pointsMultiplier).round();
    _stats = VolunteerImpactStats(
      peopleHelped: _stats.peopleHelped + 1,
      tasksCompleted: _stats.tasksCompleted + 1,
      hoursVolunteered:
          _stats.hoursVolunteered + (_tasks[i].estimatedMinutes / 60).round(),
      streakDays: _stats.streakDays,
      points: _stats.points + earnedPoints,
      level: _stats.level,
      levelTitle: _stats.levelTitle,
      nextLevelPoints: _stats.nextLevelPoints,
    );
    notifyListeners();
  }

  void declineTask(String id) {
    final i = _tasks.indexWhere((t) => t.id == id);
    if (i == -1) return;
    _tasks[i].status = VolunteerTaskStatus.cancelled;
    notifyListeners();
  }

  // Stats / Impact
  VolunteerImpactStats _stats = const VolunteerImpactStats(
    peopleHelped: 27,
    tasksCompleted: 34,
    hoursVolunteered: 41,
    streakDays: 6,
    points: 320,
    level: 4,
    levelTitle: 'Trusted Helper',
    nextLevelPoints: 500,
  );
  VolunteerImpactStats get stats => _stats;

  // Badges
  late final List<VolunteerBadge> badges = [
    const VolunteerBadge(
      id: 'first',
      title: 'First Step',
      subtitle: 'Completed your first task',
      icon: Icons.flag_rounded,
      color: Color(0xFF24B6A8),
      unlocked: true,
    ),
    const VolunteerBadge(
      id: 'streak',
      title: '7-Day Streak',
      subtitle: 'Help 7 days in a row',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFFB8C00),
      unlocked: false,
      progress: 6,
      target: 7,
    ),
    const VolunteerBadge(
      id: 'community',
      title: 'Community Hero',
      subtitle: 'Help 50 people',
      icon: Icons.volunteer_activism_rounded,
      color: Color(0xFF7C4DFF),
      unlocked: false,
      progress: 27,
      target: 50,
    ),
    const VolunteerBadge(
      id: 'medical',
      title: 'Medical Buddy',
      subtitle: 'Accompany 10 medical visits',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFE53935),
      unlocked: true,
    ),
    const VolunteerBadge(
      id: 'rapid',
      title: 'Rapid Responder',
      subtitle: 'Accept 5 SOS within 5 min',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFB300),
      unlocked: false,
      progress: 2,
      target: 5,
    ),
    const VolunteerBadge(
      id: 'kind',
      title: 'Kind Heart',
      subtitle: '5 thank-you notes from families',
      icon: Icons.favorite_rounded,
      color: Color(0xFFEC407A),
      unlocked: true,
    ),
  ];

  // Leaderboard — peer rows are mocked, "You" row reflects the logged-in user.
  List<VolunteerLeaderboardEntry> get leaderboard => [
        const VolunteerLeaderboardEntry(
          rank: 1,
          name: 'Elira K.',
          points: 540,
          tasksCompleted: 58,
          color: Color(0xFF24B6A8),
        ),
        const VolunteerLeaderboardEntry(
          rank: 2,
          name: 'Bardh L.',
          points: 482,
          tasksCompleted: 49,
          color: Color(0xFF7C4DFF),
        ),
        VolunteerLeaderboardEntry(
          rank: 3,
          name: '${volunteerName.isEmpty ? 'You' : volunteerName} (You)',
          points: stats.points,
          tasksCompleted: stats.tasksCompleted,
          color: const Color(0xFF1976D2),
          isMe: true,
        ),
        const VolunteerLeaderboardEntry(
          rank: 4,
          name: 'Mira S.',
          points: 290,
          tasksCompleted: 31,
          color: Color(0xFFE53935),
        ),
        const VolunteerLeaderboardEntry(
          rank: 5,
          name: 'Genti P.',
          points: 245,
          tasksCompleted: 26,
          color: Color(0xFFFB8C00),
        ),
      ];

  // Seed data
  void _seed() {
    final now = DateTime.now();
    DateTime at(int hours, [int minutes = 0]) =>
        now.add(Duration(hours: hours, minutes: minutes));

    _tasks.addAll([
      VolunteerTask(
        id: 't1',
        kind: VolunteerTaskKind.emergency,
        title: 'Help Lisa — feeling unwell',
        requesterName: 'Lisa H.',
        requesterPhone: '+355681112222',
        address: 'Rruga e Kavajës, Tirana',
        distanceKm: 0.6,
        createdAt: now.subtract(const Duration(minutes: 4)),
        scheduledFor: at(0, 5),
        urgency: VolunteerUrgency.sos,
        estimatedMinutes: 30,
        points: 25,
        notes: 'She pressed the SOS button. Family already notified.',
        requesterPhotoColor: const Color(0xFFE53935),
      ),
      VolunteerTask(
        id: 't2',
        kind: VolunteerTaskKind.pharmacy,
        title: 'Pick up prescription',
        requesterName: 'Mihal D.',
        requesterPhone: '+355682223333',
        address: 'Farmacia 24/7, Bllok',
        distanceKm: 1.2,
        createdAt: now.subtract(const Duration(minutes: 22)),
        scheduledFor: at(1),
        urgency: VolunteerUrgency.high,
        estimatedMinutes: 35,
        points: 12,
        notes: 'Diabetes medication. Receipt is paid. Show ID.',
        requesterPhotoColor: const Color(0xFF24B6A8),
      ),
      VolunteerTask(
        id: 't3',
        kind: VolunteerTaskKind.groceries,
        title: 'Weekly groceries',
        requesterName: 'Drita V.',
        requesterPhone: '+355681334455',
        address: 'Conad Komuna e Parisit',
        distanceKm: 2.4,
        createdAt: now.subtract(const Duration(hours: 1)),
        scheduledFor: at(3),
        urgency: VolunteerUrgency.medium,
        estimatedMinutes: 60,
        points: 15,
        notes: 'List in chat. Budget 2,500 LEK.',
        requesterPhotoColor: const Color(0xFF1976D2),
      ),
      VolunteerTask(
        id: 't4',
        kind: VolunteerTaskKind.companionship,
        title: 'Afternoon walk + chat',
        requesterName: 'Sokol B.',
        requesterPhone: '+355682777888',
        address: 'Parku Rinia, Tirana',
        distanceKm: 1.8,
        createdAt: now.subtract(const Duration(hours: 2)),
        scheduledFor: at(5),
        urgency: VolunteerUrgency.low,
        estimatedMinutes: 60,
        points: 8,
        requesterPhotoColor: const Color(0xFF7C4DFF),
      ),
      VolunteerTask(
        id: 't5',
        kind: VolunteerTaskKind.medicalVisit,
        title: 'Cardiology appointment',
        requesterName: 'Albana M.',
        address: 'Spitali Amerikan, Tirana',
        distanceKm: 4.1,
        createdAt: now.subtract(const Duration(hours: 6)),
        scheduledFor: now.add(const Duration(days: 1, hours: 9)),
        urgency: VolunteerUrgency.medium,
        estimatedMinutes: 120,
        points: 20,
        requesterPhotoColor: const Color(0xFFFB8C00),
      ),
      VolunteerTask(
        id: 't6',
        kind: VolunteerTaskKind.paperwork,
        title: 'Pension paperwork at post office',
        requesterName: 'Petrit S.',
        address: 'Posta Qendrore',
        distanceKm: 2.9,
        createdAt: now.subtract(const Duration(hours: 3)),
        scheduledFor: now.add(const Duration(days: 1)),
        urgency: VolunteerUrgency.low,
        estimatedMinutes: 45,
        points: 10,
        requesterPhotoColor: const Color(0xFFEC407A),
      ),
      VolunteerTask(
        id: 't7',
        kind: VolunteerTaskKind.transport,
        title: 'Drive to physiotherapy',
        requesterName: 'Iliria K.',
        address: 'Klinika Mediteran',
        distanceKm: 3.6,
        createdAt: now.subtract(const Duration(hours: 1)),
        scheduledFor: now.add(const Duration(hours: 2)),
        urgency: VolunteerUrgency.high,
        estimatedMinutes: 90,
        points: 18,
        requesterPhotoColor: const Color(0xFF26A69A),
      ),
    ]);
  }
}
