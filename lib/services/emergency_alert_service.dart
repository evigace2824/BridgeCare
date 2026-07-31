import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_alert_record.dart';

/// Persists emergency alerts when the `emergency_alerts` table exists.
///
/// TODO(location): When `geolocator` or platform location is added, pass
/// lat/lng from the device here. Until then [EmergencyAlertRecord.locationLat]
/// / [locationLng] stay null by design.
class EmergencyAlertService {
  EmergencyAlertService._();
  static final EmergencyAlertService instance = EmergencyAlertService._();

  /// Returns `true` if the insert succeeded, `false` if the table is missing
  /// or any error occurred (failures are swallowed after debug logging).
  Future<bool> tryInsert(EmergencyAlertRecord row) async {
    try {
      await Supabase.instance.client.from('emergency_alerts').insert(row.toJson());
      return true;
    } on PostgrestException catch (e) {
      debugPrint('EmergencyAlertService: Supabase insert skipped: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('EmergencyAlertService: $e');
      return false;
    }
  }
}
