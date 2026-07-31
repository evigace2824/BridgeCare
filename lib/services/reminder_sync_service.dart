import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/dashboard/patient/data/patient_models.dart';
import '../models/reminder_record.dart';

/// Optional sync into `reminders`. Safe no-op when table / RLS / columns differ.
class ReminderSyncService {
  ReminderSyncService._();
  static final ReminderSyncService instance = ReminderSyncService._();

  /// Returns `true` if Supabase accepted at least one insert shape.
  Future<bool> tryInsert(PatientReminder reminder) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;

    final row = ReminderRecord(
      id: reminder.id,
      userId: uid,
      title: reminder.title,
      type: _type(reminder.kind),
      scheduledAt: reminder.scheduledAt,
      notes: reminder.notes,
      status: reminder.state == ReminderState.done ? 'completed' : 'pending',
      createdAt: reminder.createdAt,
      repeatRule: switch (reminder.repeat) {
        ReminderRepeat.none => 'none',
        ReminderRepeat.daily => 'daily',
        ReminderRepeat.weekly => 'weekly',
      },
    );

    try {
      await Supabase.instance.client.from('reminders').insert(row.toInsertJson());
      return true;
    } on PostgrestException catch (e) {
      debugPrint('ReminderSyncService: ${e.message}');
      // TODO(reminders): If schema uses different column names, try alternate payloads here.
    } catch (e) {
      debugPrint('ReminderSyncService: $e');
    }
    return false;
  }

  static String _type(ReminderKind k) => switch (k) {
        ReminderKind.medication => 'medication',
        ReminderKind.appointment => 'appointment',
        ReminderKind.dailyTask => 'daily_task',
      };
}
