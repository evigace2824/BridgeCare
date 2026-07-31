import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/family_models.dart';
import 'two_factor_auth_service.dart';

class FamilyLinkException implements Exception {
  FamilyLinkException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FamilyService {
  FamilyService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Loads the patient linked to the signed-in family caregiver, or `null`.
  Future<LinkedUser?> fetchLinkedUser() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return null;

    try {
      final payload = await _client.rpc('get_linked_elderly_for_family_member');
      final map = _asMap(payload);
      if (map == null || map['ok'] != true) return null;

      final patient = _asMap(map['patient']);
      if (patient == null) return null;

      return _linkedUserFromPatient(patient, connected: true);
    } catch (e) {
      debugPrint('fetchLinkedUser: $e');
      return null;
    }
  }

  /// Links the signed-in family member to a patient using their shareable code.
  Future<String> linkToPatientByCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      throw FamilyLinkException('Please enter a family link code.');
    }

    try {
      final payload = await _client.rpc(
        'link_family_to_patient',
        params: {'link_code': trimmed},
      );
      final map = _asMap(payload);
      if (map == null) {
        throw FamilyLinkException('Could not link to patient. Try again.');
      }
      if (map['ok'] != true) {
        final err = map['error']?.toString() ?? '';
        if (err == 'code_not_found') {
          throw FamilyLinkException(
            'No patient found for that code. Ask them for the code on their '
            'profile ("My family link code").',
          );
        }
        throw FamilyLinkException('Could not link to patient. Try again.');
      }
      final name = map['patient_name']?.toString().trim();
      return (name != null && name.isNotEmpty) ? name : 'your family member';
    } on FamilyLinkException {
      rethrow;
    } catch (e) {
      debugPrint('linkToPatientByCode: $e');
      throw FamilyLinkException(
        'Linking is not available yet. Run supabase/migrations/008_family_patient_link.sql '
        'in your Supabase SQL Editor, then try again.',
      );
    }
  }

  /// Name of a family caregiver linked to the signed-in elderly patient.
  Future<String?> fetchLinkedFamilyMemberName() async {
    if (_client.auth.currentUser == null) return null;
    try {
      final payload = await _client.rpc('get_linked_family_for_elderly');
      final map = _asMap(payload);
      if (map == null || map['ok'] != true) return null;
      final family = _asMap(map['family_member']);
      if (family == null) return null;
      return _pickName(family);
    } catch (e) {
      debugPrint('fetchLinkedFamilyMemberName: $e');
      return null;
    }
  }

  String? _pickName(Map<String, dynamic> row) {
    for (final key in ['name', 'full_name', 'display_name']) {
      final v = row[key]?.toString().trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  LinkedUser _linkedUserFromPatient(
    Map<String, dynamic> patient, {
    required bool connected,
  }) {
    final uid = patient['id']?.toString() ?? '';
    final fullName = _pickName(patient) ?? 'Patient';
    final phone = patient['phone_number']?.toString().trim() ?? '';

    final now = DateTime.now();
    return LinkedUser(
      uid: uid,
      fullName: fullName,
      phoneNumber: phone.isNotEmpty ? phone : '+355 69 000 0000',
      isConnected: connected,
      healthStatus: const HealthStatus(
        type: HealthStatusType.normal,
        label: 'Normal',
        description: 'No active alerts',
      ),
      lastSeen: now.subtract(const Duration(minutes: 9)),
      lastCall: now.subtract(const Duration(hours: 4)),
      currentLocation: const LatLng(41.3275, 19.8187),
      safeZones: const [
        SafeZone(
          id: 'home',
          name: 'Home',
          center: LatLng(41.3275, 19.8187),
          radiusMeters: 120,
        ),
      ],
      heartRateHistory: List.generate(
        7,
        (i) => VitalReading(
          value: 68 + (i % 3) * 4,
          timestamp: now.subtract(Duration(days: 6 - i)),
          unit: 'bpm',
        ),
      ),
      bloodPressureHistory: List.generate(
        7,
        (i) => VitalReading(
          value: 116 + (i % 2) * 6,
          secondaryValue: 76 + (i % 2) * 4,
          timestamp: now.subtract(Duration(days: 6 - i)),
          unit: 'mmHg',
        ),
      ),
      reminders: [
        Reminder(
          id: 'r1',
          title: 'Morning medication',
          description: 'After breakfast',
          scheduledAt: DateTime(now.year, now.month, now.day, 8, 0),
          status: ReminderStatus.pending,
          type: ReminderType.medication,
        ),
        Reminder(
          id: 'r2',
          title: 'Hydration reminder',
          scheduledAt: DateTime(now.year, now.month, now.day, 12, 30),
          status: ReminderStatus.pending,
          type: ReminderType.general,
        ),
      ],
      assistanceRequests: const [],
    );
  }

  Future<void> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final payload = <String, dynamic>{
        if (fullName.trim().isNotEmpty) 'name': fullName.trim(),
        if (phoneNumber.trim().isNotEmpty) 'phone_number': phoneNumber.trim(),
      };
      if (payload.isEmpty) return;
      await _client.from('users').update(payload).eq('id', uid);
      if (fullName.trim().isNotEmpty) {
        await _client.auth.updateUser(
          UserAttributes(
            data: {
              'name': fullName.trim(),
              'full_name': fullName.trim(),
            },
          ),
        );
      }
    } catch (_) {}
  }

  Future<String> fetchCurrentFamilyDisplayName() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return 'Family Member';

    try {
      final row = await _client
          .from('users')
          .select('name, full_name, display_name')
          .eq('id', currentUser.id)
          .maybeSingle();
      final candidates = [
        row?['full_name'],
        row?['name'],
        row?['display_name'],
        currentUser.userMetadata?['full_name'],
        currentUser.userMetadata?['name'],
        currentUser.userMetadata?['display_name'],
        currentUser.email?.split('@').first,
      ];
      for (final c in candidates) {
        final v = c?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
    } catch (_) {
      final fallback = currentUser.email?.split('@').first;
      if (fallback != null && fallback.isNotEmpty) return fallback;
    }
    return 'Family Member';
  }

  Future<bool> isTwoFactorEnabled() =>
      TwoFactorAuthService.instance.isEnabled();

  String effectiveTwoFactorEmail({String? hintEmail}) =>
      TwoFactorAuthService.instance.resolveEmail(hintEmail: hintEmail);

  Future<void> sendTwoFactorOtp({String? email}) =>
      TwoFactorAuthService.instance.sendEmailOtp(email: email);

  Future<void> verifyTwoFactorOtp({
    required String email,
    required String token,
  }) =>
      TwoFactorAuthService.instance.verifyEmailOtp(
        email: email,
        token: token,
      );

  Future<void> setTwoFactorEnabled(bool enabled) =>
      TwoFactorAuthService.instance.setEnabled(
        enabled,
        email: _client.auth.currentUser?.email,
      );

  Future<void> updateReminderStatus({
    required String elderlyUid,
    required String reminderId,
    required ReminderStatus status,
  }) async {
    try {
      await _client.from('reminders').update({
        'status': status.name,
      }).eq('id', reminderId).eq('elderly_uid', elderlyUid);
    } catch (_) {}
  }

  Future<void> saveSafeZone({
    required String elderlyUid,
    required SafeZone zone,
  }) async {
    try {
      await _client.from('safe_zones').upsert({
        'id': zone.id,
        'elderly_uid': elderlyUid,
        'name': zone.name,
        'latitude': zone.center.latitude,
        'longitude': zone.center.longitude,
        'radius_meters': zone.radiusMeters,
      });
    } catch (_) {}
  }

  Future<void> deleteSafeZone({
    required String elderlyUid,
    required String zoneId,
  }) async {
    try {
      await _client
          .from('safe_zones')
          .delete()
          .eq('id', zoneId)
          .eq('elderly_uid', elderlyUid);
    } catch (_) {}
  }

  Future<WeeklyReport> fetchWeeklyReport(String elderlyUid) async {
    final now = DateTime.now();
    return WeeklyReport(
      heartRateData: List.generate(
        7,
        (i) => VitalReading(
          value: 66 + (i % 4) * 5,
          timestamp: now.subtract(Duration(days: 6 - i)),
        ),
      ),
      bloodPressureData: List.generate(
        7,
        (i) => VitalReading(
          value: 114 + (i % 3) * 6,
          secondaryValue: 74 + (i % 2) * 5,
          timestamp: now.subtract(Duration(days: 6 - i)),
        ),
      ),
      missedMedicationCount: 2,
      takenMedicationCount: 12,
      missedAppointmentsCount: 1,
      medications: const [
        MedicationSummary(name: 'Aspirin 100mg', takenCount: 6, missedCount: 1),
        MedicationSummary(
          name: 'Metformin 500mg',
          takenCount: 5,
          missedCount: 1,
        ),
      ],
    );
  }

  static DateTime? _parseServerTime(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  Future<LinkedUserLocationSnapshot?> fetchLatestLinkedUserLocationDetailed(
    String elderlyUid,
  ) async {
    try {
      final row = await _client
          .from('users')
          .select(
            'latitude, longitude, current_latitude, current_longitude, updated_at',
          )
          .eq('id', elderlyUid)
          .maybeSingle();
      final lat = (row?['latitude'] as num?)?.toDouble() ??
          (row?['current_latitude'] as num?)?.toDouble();
      final lng = (row?['longitude'] as num?)?.toDouble() ??
          (row?['current_longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        return LinkedUserLocationSnapshot(
          latitude: lat,
          longitude: lng,
          recordedAt: _parseServerTime(row?['updated_at']),
        );
      }
    } catch (_) {}

    try {
      final fromHistory = await _client
          .from('location_history')
          .select('latitude, longitude, created_at')
          .eq('elderly_uid', elderlyUid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final userLat = (fromHistory?['latitude'] as num?)?.toDouble();
      final userLng = (fromHistory?['longitude'] as num?)?.toDouble();
      if (userLat != null && userLng != null) {
        return LinkedUserLocationSnapshot(
          latitude: userLat,
          longitude: userLng,
          recordedAt: _parseServerTime(fromHistory?['created_at']),
        );
      }
    } catch (_) {}

    return null;
  }

  Future<LatLng?> fetchLatestLinkedUserLocation(String elderlyUid) async {
    final snap = await fetchLatestLinkedUserLocationDetailed(elderlyUid);
    if (snap == null) return null;
    return LatLng(snap.latitude, snap.longitude);
  }

  Future<void> signOut() => _client.auth.signOut();
}

/// Point-in-time location for a linked elderly user (map + "last seen" UI).
class LinkedUserLocationSnapshot {
  const LinkedUserLocationSnapshot({
    required this.latitude,
    required this.longitude,
    this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final DateTime? recordedAt;
}
