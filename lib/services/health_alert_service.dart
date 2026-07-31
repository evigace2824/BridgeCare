import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/dashboard/patient/data/patient_models.dart';

/// Optional persistence for abnormal heart-rate events (family notification).
///
/// Tries `health_alerts` then `notifications` — whichever exists in the project.
/// If neither exists, returns `false` and callers rely on local UI only.
class HealthAlertService {
  HealthAlertService._();
  static final HealthAlertService instance = HealthAlertService._();

  Future<bool> tryNotifyAbnormalReading({
    required int heartRate,
    required HealthStatus status,
    String? notes,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;

    final payload = {
      'user_id': userId,
      'heart_rate': heartRate,
      'status': status.name,
      'notes': notes,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };

    for (final table in const ['health_alerts', 'notifications']) {
      try {
        await Supabase.instance.client.from(table).insert(payload);
        return true;
      } on PostgrestException {
        continue;
      } catch (_) {
        continue;
      }
    }
    return false;
  }
}
