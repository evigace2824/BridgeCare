import 'package:flutter/foundation.dart';

enum HealthStatusType { normal, warning, emergency }

enum AlertSeverity { info, warning, critical }

enum ReminderStatus { pending, done, missed }

enum ReminderType { medication, appointment, general }

enum RequestStatus { pending, accepted, completed, rejected }

enum RequestType { groceryShopping, medicalVisit, collectPension, other }

@immutable
class LatLng {
  const LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class HealthStatus {
  const HealthStatus({
    required this.type,
    required this.label,
    required this.description,
  });

  final HealthStatusType type;
  final String label;
  final String description;
}

class AppAlert {
  AppAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime createdAt;
  bool isRead;
}

class VitalReading {
  const VitalReading({
    required this.value,
    required this.timestamp,
    this.secondaryValue,
    this.unit,
  });

  final double value;
  final double? secondaryValue;
  final DateTime timestamp;
  final String? unit;
}

class MedicationSummary {
  const MedicationSummary({
    required this.name,
    required this.takenCount,
    required this.missedCount,
  });

  final String name;
  final int takenCount;
  final int missedCount;

  int get total => takenCount + missedCount;
}

class WeeklyReport {
  const WeeklyReport({
    required this.heartRateData,
    required this.bloodPressureData,
    required this.missedMedicationCount,
    required this.takenMedicationCount,
    required this.missedAppointmentsCount,
    required this.medications,
  });

  final List<VitalReading> heartRateData;
  final List<VitalReading> bloodPressureData;
  final int missedMedicationCount;
  final int takenMedicationCount;
  final int missedAppointmentsCount;
  final List<MedicationSummary> medications;
}

class Reminder {
  Reminder({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.status,
    required this.type,
    this.description,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;
  ReminderStatus status;
  final ReminderType type;
  final String? description;
}

class AssistanceRequest {
  AssistanceRequest({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.status,
    this.notes,
    this.assignedVolunteerName,
  });

  final String id;
  final RequestType type;
  final String title;
  final String? notes;
  final DateTime createdAt;
  RequestStatus status;
  final String? assignedVolunteerName;
}

class SafeZone {
  const SafeZone({
    required this.id,
    required this.name,
    required this.center,
    required this.radiusMeters,
  });

  final String id;
  final String name;
  final LatLng center;
  final double radiusMeters;
}

class LinkedUser {
  const LinkedUser({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    required this.healthStatus,
    this.isConnected = true,
    this.lastSeen,
    this.lastCall,
    this.currentLocation,
    this.safeZones = const [],
    this.heartRateHistory = const [],
    this.bloodPressureHistory = const [],
    this.reminders = const [],
    this.assistanceRequests = const [],
  });

  final String uid;
  final String fullName;
  final String phoneNumber;
  /// True when loaded from a real patient row in Supabase (not demo data).
  final bool isConnected;
  final HealthStatus healthStatus;
  final DateTime? lastSeen;
  final DateTime? lastCall;
  final LatLng? currentLocation;
  final List<SafeZone> safeZones;
  final List<VitalReading> heartRateHistory;
  final List<VitalReading> bloodPressureHistory;
  final List<Reminder> reminders;
  final List<AssistanceRequest> assistanceRequests;
}
