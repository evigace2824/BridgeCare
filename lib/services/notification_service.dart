import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'job_notification_service.dart';

/// In-app notification (volunteer + family job flows).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.type = 'general',
    this.read = false,
    this.relatedId,
    this.audience = NotificationAudience.volunteer,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String type;
  final bool read;
  final String? relatedId;
  final NotificationAudience audience;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'type': type,
        'read': read,
        'related_id': relatedId,
        'audience': audience.name,
      };

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'].toString(),
        title: m['title']?.toString() ?? '',
        body: m['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
        type: m['type']?.toString() ?? 'general',
        read: m['read'] == true,
        relatedId: m['related_id']?.toString(),
        audience: NotificationAudience.values.asNameMap()[
                m['audience']?.toString()] ??
            NotificationAudience.volunteer,
      );
}

enum NotificationAudience { volunteer, family }

/// Delivers job-post alerts to volunteers and application updates to families.
class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final List<AppNotification> _volunteer = [];
  final List<AppNotification> _family = [];
  static const _volunteerPrefsKey = 'volunteer_job_notifications';
  static const _familyPrefsKey = 'family_job_notifications';

  List<AppNotification> get notifications => List.unmodifiable(_volunteer);

  List<AppNotification> get familyNotifications =>
      List.unmodifiable(_family);

  int get unreadCount => _volunteer.where((n) => !n.read).length;

  int get familyUnreadCount => _family.where((n) => !n.read).length;

  List<AppNotification> get jobPostNotifications =>
      _volunteer.where((n) => n.type == 'job_post').toList();

  List<AppNotification> get familyApplicationNotifications => _family
      .where((n) => n.type == 'job_application' || n.type == 'job_update')
      .toList();

  Future<void> loadPersisted() async {
    await _loadList(_volunteerPrefsKey, _volunteer);
    await _loadList(_familyPrefsKey, _family);
    notifyListeners();
  }

  Future<void> _loadList(String key, List<AppNotification> target) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(key);
      if (raw == null) return;
      final list = jsonDecode(raw) as List;
      target
        ..clear()
        ..addAll(list.map((e) =>
            AppNotification.fromMap(Map<String, dynamic>.from(e as Map))));
    } catch (_) {}
  }

  Future<void> _persistVolunteer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _volunteerPrefsKey,
        jsonEncode(_volunteer.map((n) => n.toMap()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _persistFamily() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _familyPrefsKey,
        jsonEncode(_family.map((n) => n.toMap()).toList()),
      );
    } catch (_) {}
  }

  Future<void> _insertSupabase({
    required String type,
    required String title,
    required String body,
    String? relatedId,
    String? userId,
  }) async {
    try {
      // TODO: Set user_id when notifications table + RLS target each recipient.
      await Supabase.instance.client.from('notifications').insert({
        if (userId != null) 'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'related_id': relatedId,
      });
    } catch (_) {}
  }

  Future<void> notifyVolunteersNewJobPost({
    required String jobId,
    required String jobTitle,
    required String familyName,
    String? elderlyName,
  }) async {
    final forWho = elderlyName != null ? ' for $elderlyName' : '';
    final notification = AppNotification(
      id: 'job_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New premium care job',
      body:
          '$familyName posted "$jobTitle"$forWho — apply within 48 hours.',
      createdAt: DateTime.now(),
      type: 'job_post',
      relatedId: jobId,
    );
    _volunteer.insert(0, notification);
    notifyListeners();
    await _persistVolunteer();

    await JobNotificationService.instance.showNewJobPostAlert(
      jobTitle: jobTitle,
      familyName: familyName,
    );

    await _insertSupabase(
      type: 'job_post',
      title: notification.title,
      body: notification.body,
      relatedId: jobId,
    );
  }

  Future<void> notifyFamilyVolunteerApplied({
    required String familyUserId,
    required String jobId,
    required String jobTitle,
    required String volunteerName,
  }) async {
    final notification = AppNotification(
      id: 'fapp_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New job application',
      body: '$volunteerName applied for "$jobTitle". Review their care profile.',
      createdAt: DateTime.now(),
      type: 'job_application',
      relatedId: jobId,
      audience: NotificationAudience.family,
    );
    _family.insert(0, notification);
    notifyListeners();
    await _persistFamily();
    await _insertSupabase(
      type: 'job_application',
      title: notification.title,
      body: notification.body,
      relatedId: jobId,
      userId: familyUserId,
    );
  }

  Future<void> notifyVolunteerApplicationAccepted({
    required String volunteerUserId,
    required String jobTitle,
  }) async {
    final notification = AppNotification(
      id: 'vacc_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Application accepted',
      body:
          'The family accepted you for "$jobTitle". You can start the job when ready.',
      createdAt: DateTime.now(),
      type: 'job_accepted',
      audience: NotificationAudience.volunteer,
    );
    _volunteer.insert(0, notification);
    notifyListeners();
    await _persistVolunteer();
    await _insertSupabase(
      type: 'job_accepted',
      title: notification.title,
      body: notification.body,
      userId: volunteerUserId,
    );
  }

  Future<void> notifyVolunteerApplicationRejected({
    required String volunteerUserId,
    required String jobTitle,
  }) async {
    final notification = AppNotification(
      id: 'vrej_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Application update',
      body: 'The family chose another volunteer for "$jobTitle".',
      createdAt: DateTime.now(),
      type: 'job_rejected',
      audience: NotificationAudience.volunteer,
    );
    _volunteer.insert(0, notification);
    notifyListeners();
    await _persistVolunteer();
    await _insertSupabase(
      type: 'job_rejected',
      title: notification.title,
      body: notification.body,
      userId: volunteerUserId,
    );
  }

  void markRead(String id, {NotificationAudience? audience}) {
    final list = audience == NotificationAudience.family ? _family : _volunteer;
    final i = list.indexWhere((n) => n.id == id);
    if (i == -1) return;
    final n = list[i];
    list[i] = AppNotification(
      id: n.id,
      title: n.title,
      body: n.body,
      createdAt: n.createdAt,
      type: n.type,
      read: true,
      relatedId: n.relatedId,
      audience: n.audience,
    );
    notifyListeners();
    if (audience == NotificationAudience.family) {
      _persistFamily();
    } else {
      _persistVolunteer();
    }
  }

  void markAllJobPostsRead() {
    for (var i = 0; i < _volunteer.length; i++) {
      if (_volunteer[i].type == 'job_post' && !_volunteer[i].read) {
        final n = _volunteer[i];
        _volunteer[i] = AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          createdAt: n.createdAt,
          type: n.type,
          read: true,
          relatedId: n.relatedId,
          audience: n.audience,
        );
      }
    }
    notifyListeners();
    _persistVolunteer();
  }

  void markAllFamilyJobRead() {
    for (var i = 0; i < _family.length; i++) {
      if (!_family[i].read) {
        final n = _family[i];
        _family[i] = AppNotification(
          id: n.id,
          title: n.title,
          body: n.body,
          createdAt: n.createdAt,
          type: n.type,
          read: true,
          relatedId: n.relatedId,
          audience: n.audience,
        );
      }
    }
    notifyListeners();
    _persistFamily();
  }

  void clearAll() {
    _volunteer.clear();
    notifyListeners();
    _persistVolunteer();
  }
}
