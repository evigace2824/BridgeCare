import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/dashboard/patient/data/patient_models.dart';
import '../models/health_entry_record.dart';

/// Persists heart-rate readings when a compatible table exists.
///
/// Tries a few common table names / payloads — failures never throw to callers.
class HealthEntrySyncService {
  HealthEntrySyncService._();
  static final HealthEntrySyncService instance = HealthEntrySyncService._();

  Future<bool> tryInsertHeartRate(HeartRateEntry entry) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;

    final core = HealthEntryRecord(
      id: entry.id,
      userId: uid,
      heartRate: entry.heartRate,
      status: entry.status.name,
      notes: entry.notes,
      createdAt: entry.createdAt,
    );

    final tables = ['health_entries', 'patient_health_entries', 'vitals'];

    for (final table in tables) {
      try {
        await Supabase.instance.client
            .from(table)
            .insert(core.toInsertJson());
        return true;
      } on PostgrestException catch (e) {
        debugPrint('HealthEntrySyncService.$table: ${e.message}');
      } catch (e) {
        debugPrint('HealthEntrySyncService.$table: $e');
      }
    }
    return false;
  }
}
