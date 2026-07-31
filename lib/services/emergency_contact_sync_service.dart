import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/dashboard/patient/data/patient_models.dart';
import '../models/emergency_contact_record.dart';

/// Optional insert into `emergency_contacts`.
class EmergencyContactSyncService {
  EmergencyContactSyncService._();
  static final EmergencyContactSyncService instance =
      EmergencyContactSyncService._();

  Future<bool> tryInsert(EmergencyContact contact) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;

    final row = EmergencyContactRecord(
      id: contact.id,
      userId: uid,
      name: contact.name,
      relationship: contact.relationship,
      phone: contact.phone,
      priority: contact.priority,
      createdAt: DateTime.now(),
    );

    try {
      await Supabase.instance.client
          .from('emergency_contacts')
          .insert(row.toInsertJson());
      return true;
    } on PostgrestException catch (e) {
      debugPrint('EmergencyContactSyncService: ${e.message}');
    } catch (e) {
      debugPrint('EmergencyContactSyncService: $e');
    }
    return false;
  }
}
