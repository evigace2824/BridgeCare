import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// OS-level alert when a family posts a premium job (mobile).
class JobNotificationService {
  JobNotificationService._();
  static final JobNotificationService instance = JobNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (_initialized || !_isMobile) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> showNewJobPostAlert({
    required String jobTitle,
    required String familyName,
  }) async {
    if (!_isMobile) return;
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'carebridge_job_posts',
        'Care Jobs',
        channelDescription: 'New premium family job posts (48h)',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: 'New care job — 48h active',
      body: '$familyName: $jobTitle',
      notificationDetails: details,
    );
  }
}
