// Domain models used by the patient dashboard. Currently powered by mock
// data in `PatientStore`; the same shapes will map to Supabase tables in v2:
//
// - PatientReminder → `reminders`
// - Vitals / HeartRateEntry → `vitals` / `health_entries`
// - AssistanceRequest → `assistance_requests`

import 'package:flutter/foundation.dart' show immutable;

enum ReminderKind { medication, appointment, dailyTask }

enum ReminderState { pending, done }

/// Simple repeat rule for local reminders (Supabase sync TODO).
enum ReminderRepeat { none, daily, weekly }
enum PatientOverallStatus { safe, needsAttention, emergency }
enum DailyCheckInMood { good, okay, unwell }

class PatientReminder {
  const PatientReminder({
    required this.id,
    required this.kind,
    required this.title,
    required this.scheduledAt,
    this.state = ReminderState.pending,
    this.notes,
    this.repeat = ReminderRepeat.none,
    required this.createdAt,
  });

  final String id;
  final ReminderKind kind;
  final String title;
  final DateTime scheduledAt;
  final ReminderState state;
  final String? notes;
  final ReminderRepeat repeat;
  final DateTime createdAt;

  PatientReminder copyWith({
    ReminderState? state,
    DateTime? scheduledAt,
    String? notes,
    ReminderRepeat? repeat,
  }) =>
      PatientReminder(
        id: id,
        kind: kind,
        title: title,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        state: state ?? this.state,
        notes: notes ?? this.notes,
        repeat: repeat ?? this.repeat,
        createdAt: createdAt,
      );
}

/// Three-tier health status used across the patient dashboard.
enum HealthStatus { normal, warning, emergency, unknown }

/// Heart-rate thresholds (bpm) per product spec.
abstract final class HeartRateRules {
  HeartRateRules._();

  /// Normal: 60–100 · Warning: 45–59 or 101–120 · Emergency: &lt;45 or &gt;120
  static HealthStatus statusFor(int? hrBpm) {
    if (hrBpm == null) return HealthStatus.unknown;
    if (hrBpm < 45 || hrBpm > 120) return HealthStatus.emergency;
    if (hrBpm >= 60 && hrBpm <= 100) return HealthStatus.normal;
    return HealthStatus.warning;
  }

  static bool isPlausible(int hr) => hr >= 30 && hr <= 220;
}

@immutable
class Vitals {
  const Vitals({
    this.heartRate,
    this.recordedAt,
  });

  final int? heartRate;
  final DateTime? recordedAt;

  bool get hasAny => heartRate != null;
}

@immutable
class HeartRateEntry {
  const HeartRateEntry({
    required this.id,
    required this.heartRate,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  final String id;
  final int heartRate;
  final HealthStatus status;
  final DateTime createdAt;
  final String? notes;
}

@immutable
class HealthEntry {
  const HealthEntry({
    required this.id,
    required this.heartRate,
    this.systolic,
    this.diastolic,
    this.bloodSugar,
    this.temperatureC,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final int heartRate;
  final int? systolic;
  final int? diastolic;
  final double? bloodSugar;
  final double? temperatureC;
  final String? notes;
  final HealthStatus status;
  final DateTime createdAt;
}

enum RoutineTaskKind {
  morningMedicine,
  drinkWater,
  shortWalk,
  checkBloodPressure,
  callFamily,
}

@immutable
class RoutineTask {
  const RoutineTask({
    required this.kind,
    required this.label,
    this.completed = false,
  });

  final RoutineTaskKind kind;
  final String label;
  final bool completed;

  RoutineTask copyWith({bool? completed}) => RoutineTask(
        kind: kind,
        label: label,
        completed: completed ?? this.completed,
      );
}

enum ActivityType {
  reminderDone,
  reminderSnoozed,
  healthEntered,
  helpRequested,
  familyCheckIn,
  emergencyAlert,
}

@immutable
class PatientActivity {
  const PatientActivity({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.at,
  });

  final String id;
  final ActivityType type;
  final String title;
  final String? subtitle;
  final DateTime at;
}

enum AssistanceRequestKind {
  buyMedicine,
  grocery,
  doctorAppointment,
  transportation,
  houseHelp,
  talkToSomeone,
  other,
}

extension AssistanceRequestKindLabel on AssistanceRequestKind {
  String get label => switch (this) {
        AssistanceRequestKind.buyMedicine => 'Buy medicine',
        AssistanceRequestKind.grocery => 'Grocery shopping',
        AssistanceRequestKind.doctorAppointment => 'Doctor appointment',
        AssistanceRequestKind.transportation => 'Transportation',
        AssistanceRequestKind.houseHelp => 'House help',
        AssistanceRequestKind.talkToSomeone => 'Talk to someone',
        AssistanceRequestKind.other => 'Other help',
      };

  /// Backward-compatible API values expected by existing Supabase rows.
  String get backendType => switch (this) {
        AssistanceRequestKind.buyMedicine => 'medical',
        AssistanceRequestKind.grocery => 'grocery',
        AssistanceRequestKind.doctorAppointment => 'medical',
        AssistanceRequestKind.transportation => 'daily',
        AssistanceRequestKind.houseHelp => 'daily',
        AssistanceRequestKind.talkToSomeone => 'daily',
        AssistanceRequestKind.other => 'other',
      };
}

enum AssistanceRequestWhen { today, tomorrow, customDate }

enum AssistanceRequestState { pending, accepted, completed, cancelled }

class AssistanceRequest {
  const AssistanceRequest({
    required this.id,
    required this.kind,
    required this.when,
    required this.state,
    required this.createdAt,
    this.customDate,
    this.note,
  });

  final String id;
  final AssistanceRequestKind kind;
  final AssistanceRequestWhen when;
  final DateTime? customDate;
  final String? note;
  final AssistanceRequestState state;
  final DateTime createdAt;

  AssistanceRequest copyWith({AssistanceRequestState? state}) =>
      AssistanceRequest(
        id: id,
        kind: kind,
        when: when,
        state: state ?? this.state,
        createdAt: createdAt,
        customDate: customDate,
        note: note,
      );
}

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.priority = 0,
  });

  final String id;
  final String name;
  final String phone;
  final String relationship;

  /// Lower number = higher priority (0 is primary).
  final int priority;
}
