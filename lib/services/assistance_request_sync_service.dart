import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/dashboard/patient/data/patient_models.dart';
import '../models/assistance_request_record.dart';

/// Optional insert into `assistance_requests`.
class AssistanceRequestSyncService {
  AssistanceRequestSyncService._();
  static final AssistanceRequestSyncService instance =
      AssistanceRequestSyncService._();

  Future<bool> tryInsert(AssistanceRequest request) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;

    final row = AssistanceRequestRecord(
      id: request.id,
      userId: uid,
      type: request.kind.backendType,
      details: request.note,
      preferredTime: _preferred(request.when, request.customDate),
      status: request.state.name,
      createdAt: request.createdAt,
    );

    try {
      await Supabase.instance.client
          .from('assistance_requests')
          .insert(row.toInsertJson());
      return true;
    } on PostgrestException catch (e) {
      debugPrint('AssistanceRequestSyncService: ${e.message}');
    } catch (e) {
      debugPrint('AssistanceRequestSyncService: $e');
    }
    return false;
  }

  static String _preferred(AssistanceRequestWhen when, DateTime? custom) {
    switch (when) {
      case AssistanceRequestWhen.today:
        return 'today';
      case AssistanceRequestWhen.tomorrow:
        return 'tomorrow';
      case AssistanceRequestWhen.customDate:
        final c = custom ?? DateTime.now();
        return 'custom:${c.toUtc().toIso8601String()}';
    }
  }
}
