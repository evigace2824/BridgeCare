import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HeartRateNotificationService {
  HeartRateNotificationService._();

  static final HeartRateNotificationService instance =
      HeartRateNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  DateTime? _lastAlertAt;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> initialize() async {
    if (_initialized || !_isMobile) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> showAbnormalHeartRateAlert({
    required int heartRate,
    required String level,
  }) async {
    if (!_isMobile) return;
    await initialize();

    final now = DateTime.now();
    if (_lastAlertAt != null &&
        now.difference(_lastAlertAt!) < const Duration(minutes: 1)) {
      return;
    }
    _lastAlertAt = now;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'carebridge_heart_alerts',
        'Heart Alerts',
        channelDescription: 'Alerts when heart rate is abnormal',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: 1001,
      title: 'BridgeCare Heart Alert',
      body: 'Heart rate is $heartRate bpm ($level). Check now.',
      notificationDetails: details,
    );
  }
}
