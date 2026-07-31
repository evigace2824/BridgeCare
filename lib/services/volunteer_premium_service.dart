import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/volunteer/data/volunteer_models.dart';
import '../features/volunteer/data/volunteer_store.dart';
import '../models/volunteer_premium_settings.dart';

/// Filters and persists volunteer premium preferences.
class VolunteerPremiumService {
  VolunteerPremiumService._();
  static final VolunteerPremiumService instance = VolunteerPremiumService._();

  static const _prefsKey = 'volunteer_premium_settings';

  /// Assistance + SOS only (never premium family job posts).
  List<VolunteerTask> assistanceTasks(Iterable<VolunteerTask> all) => all
      .where((t) => !t.id.startsWith('jobpost_'))
      .where((t) => t.distanceKm <= VolunteerStore.instance.maxRadiusKm)
      .toList();

  /// Open assistance within current radius cap (5 km free, up to 25 km premium).
  List<VolunteerTask> openAssistanceNearby() {
    final cap = VolunteerStore.instance.maxRadiusKm;
    return VolunteerStore.instance.openTasks
        .where((t) => !t.id.startsWith('jobpost_'))
        .where((t) => t.distanceKm <= cap)
        .toList();
  }

  Future<void> loadSettings() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    VolunteerPremiumSettings settings = const VolunteerPremiumSettings();

    try {
      if (userId != null) {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('extras')
            .eq('id', userId)
            .maybeSingle();
        if (row != null && row['extras'] is Map) {
          final extras = Map<String, dynamic>.from(row['extras'] as Map);
          if (extras['volunteer_premium_settings'] is Map) {
            settings = VolunteerPremiumSettings.fromMap(
              Map<String, dynamic>.from(
                  extras['volunteer_premium_settings'] as Map),
            );
          }
        }
      }
    } catch (_) {
      // TODO: dedicated volunteer_settings table
    }

    settings = await _loadLocal() ?? settings;
    VolunteerStore.instance.applyPremiumSettings(settings);
  }

  Future<void> saveSettings(VolunteerPremiumSettings settings) async {
    VolunteerStore.instance.applyPremiumSettings(settings);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(settings.toMap()));
    } catch (_) {}

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final existing = await Supabase.instance.client
          .from('profiles')
          .select('extras')
          .eq('id', userId)
          .maybeSingle();
      Map<String, dynamic> extras = {};
      if (existing != null && existing['extras'] is Map) {
        extras = Map<String, dynamic>.from(existing['extras'] as Map);
      }
      extras['volunteer_premium_settings'] = settings.toMap();
      await Supabase.instance.client
          .from('profiles')
          .update({'extras': extras})
          .eq('id', userId);
    } catch (_) {
      // TODO: persist to Supabase when schema ready
    }
  }

  Future<VolunteerPremiumSettings?> _loadLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return null;
      return VolunteerPremiumSettings.fromMap(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
