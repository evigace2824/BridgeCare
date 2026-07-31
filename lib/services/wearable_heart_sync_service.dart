import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class WearableVitalsResult {
  const WearableVitalsResult({
    required this.success,
    this.heartRateBpm,
    this.systolic,
    this.diastolic,
    this.steps,
    this.oxygenSaturation,
    this.temperatureC,
    this.sourceLabel,
    this.errorMessage,
  });

  final bool success;
  final int? heartRateBpm;
  final int? systolic;
  final int? diastolic;
  final int? steps;
  final double? oxygenSaturation;
  final double? temperatureC;
  final String? sourceLabel;
  final String? errorMessage;

  bool get hasAnyVital =>
      heartRateBpm != null ||
      systolic != null ||
      diastolic != null ||
      steps != null ||
      oxygenSaturation != null ||
      temperatureC != null;
}

/// Backwards-compatible alias.
typedef WearableHeartSyncResult = WearableVitalsResult;

class WearableHeartSyncService {
  WearableHeartSyncService._();

  static final WearableHeartSyncService instance = WearableHeartSyncService._();

  final Health _health = Health();
  bool _configured = false;

  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String get setupInstructions {
    if (kIsWeb) {
      return 'Open the mobile app on Android or iPhone, then connect Health Connect / Apple Health.';
    }
    if (Platform.isAndroid) {
      return 'Install Health Connect, allow heart-rate / blood-pressure permissions, and ensure your watch syncs into Health Connect.';
    }
    if (Platform.isIOS) {
      return 'Open Apple Health, allow heart-rate and blood-pressure sharing for BridgeCare, and make sure your Apple Watch is paired and syncing.';
    }
    return 'Wearable sync is available on Android/iOS mobile devices.';
  }

  static const List<HealthDataType> _types = [
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.STEPS,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BODY_TEMPERATURE,
  ];

  Future<bool> ensureAuthorized({bool promptInstall = true}) async {
    if (!isSupportedPlatform) return false;
    try {
      if (!_configured) {
        await _health.configure();
        _configured = true;
      }
      if (Platform.isAndroid) {
        final available = await _health.isHealthConnectAvailable();
        if (!available) {
          if (promptInstall) {
            await _health.installHealthConnect();
          }
          return false;
        }
      }
      final permissions =
          List<HealthDataAccess>.filled(_types.length, HealthDataAccess.READ);
      final has = await _health.hasPermissions(_types, permissions: permissions);
      if (has == true) return true;
      return await _health.requestAuthorization(_types, permissions: permissions);
    } catch (e) {
      debugPrint('WearableHeartSyncService.ensureAuthorized error: $e');
      return false;
    }
  }

  Future<WearableVitalsResult> fetchLatestVitals({bool promptInstall = true}) async {
    if (!isSupportedPlatform) {
      return const WearableVitalsResult(
        success: false,
        errorMessage: 'Wearable sync is available on Android/iPhone only.',
      );
    }
    try {
      final granted = await ensureAuthorized(promptInstall: promptInstall);
      if (!granted) {
        return WearableVitalsResult(
          success: false,
          errorMessage: Platform.isAndroid
              ? 'Health Connect access not granted. Open Health Connect and allow BridgeCare.'
              : 'Apple Health access not granted. Open Apple Health and allow BridgeCare.',
        );
      }

      final now = DateTime.now();
      final from = now.subtract(const Duration(hours: 24));
      final points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: from,
        endTime: now,
      );

      if (points.isEmpty) {
        return const WearableVitalsResult(
          success: false,
          errorMessage:
              'No recent data found from your wearable. Wear your device and try again.',
        );
      }

      points.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));

      int? heartRate;
      int? systolic;
      int? diastolic;
      int? steps;
      double? spo2;
      double? tempC;

      for (final p in points) {
        final v = p.value;
        final n = v is NumericHealthValue ? v.numericValue : null;
        switch (p.type) {
          case HealthDataType.HEART_RATE:
            heartRate ??= n?.round();
            break;
          case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
            systolic ??= n?.round();
            break;
          case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
            diastolic ??= n?.round();
            break;
          case HealthDataType.STEPS:
            steps ??= n?.round();
            break;
          case HealthDataType.BLOOD_OXYGEN:
            spo2 ??= n?.toDouble();
            break;
          case HealthDataType.BODY_TEMPERATURE:
            tempC ??= n?.toDouble();
            break;
          default:
            break;
        }
      }

      return WearableVitalsResult(
        success: heartRate != null ||
            systolic != null ||
            diastolic != null ||
            steps != null ||
            spo2 != null ||
            tempC != null,
        heartRateBpm: heartRate,
        systolic: systolic,
        diastolic: diastolic,
        steps: steps,
        oxygenSaturation: spo2,
        temperatureC: tempC,
        sourceLabel: Platform.isIOS
            ? 'Apple Health / Apple Watch'
            : 'Health Connect / Wear OS',
        errorMessage: heartRate == null &&
                systolic == null &&
                diastolic == null &&
                steps == null
            ? 'Wearable connected but no readings available yet.'
            : null,
      );
    } catch (e) {
      debugPrint('WearableHeartSyncService.fetchLatestVitals error: $e');
      return const WearableVitalsResult(
        success: false,
        errorMessage:
            'Wearable sync failed. Please check permissions and try again.',
      );
    }
  }

  /// Backwards-compatible API used by existing code.
  Future<WearableVitalsResult> fetchLatestHeartRate({bool promptInstall = true}) =>
      fetchLatestVitals(promptInstall: promptInstall);
}
