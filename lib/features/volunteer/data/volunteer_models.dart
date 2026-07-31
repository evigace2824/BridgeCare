import 'package:flutter/material.dart';

enum VolunteerTaskKind {
  groceries,
  pharmacy,
  medicalVisit,
  transport,
  paperwork,
  companionship,
  homeHelp,
  emergency,
}

enum VolunteerTaskStatus {
  open,
  accepted,
  inProgress,
  completed,
  cancelled,
}

enum VolunteerUrgency { low, medium, high, sos }

class VolunteerTask {
  VolunteerTask({
    required this.id,
    required this.kind,
    required this.title,
    required this.requesterName,
    required this.address,
    required this.distanceKm,
    required this.createdAt,
    required this.scheduledFor,
    this.notes,
    this.urgency = VolunteerUrgency.medium,
    this.status = VolunteerTaskStatus.open,
    this.estimatedMinutes = 45,
    this.points = 10,
    this.requesterPhone,
    this.requesterPhotoColor,
    this.latitude,
    this.longitude,
  });

  final String id;
  final VolunteerTaskKind kind;
  final String title;
  final String requesterName;
  final String? requesterPhone;
  final Color? requesterPhotoColor;
  final String address;
  final double distanceKm;
  final String? notes;
  final DateTime createdAt;
  final DateTime scheduledFor;
  VolunteerUrgency urgency;
  VolunteerTaskStatus status;
  final int estimatedMinutes;
  final int points;
  final double? latitude;
  final double? longitude;

  String get timeWindowLabel {
    final hh = scheduledFor.hour.toString().padLeft(2, '0');
    final mm = scheduledFor.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class VolunteerBadge {
  const VolunteerBadge({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.unlocked,
    this.progress = 0,
    this.target = 1,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool unlocked;
  final int progress;
  final int target;
}

class VolunteerImpactStats {
  const VolunteerImpactStats({
    required this.peopleHelped,
    required this.tasksCompleted,
    required this.hoursVolunteered,
    required this.streakDays,
    required this.points,
    required this.level,
    required this.levelTitle,
    required this.nextLevelPoints,
  });

  final int peopleHelped;
  final int tasksCompleted;
  final int hoursVolunteered;
  final int streakDays;
  final int points;
  final int level;
  final String levelTitle;
  final int nextLevelPoints;

  double get progressToNextLevel {
    if (nextLevelPoints == 0) return 1;
    return (points / nextLevelPoints).clamp(0, 1);
  }
}

class VolunteerLeaderboardEntry {
  const VolunteerLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.points,
    required this.tasksCompleted,
    required this.color,
    this.isMe = false,
  });

  final int rank;
  final String name;
  final int points;
  final int tasksCompleted;
  final Color color;
  final bool isMe;
}
