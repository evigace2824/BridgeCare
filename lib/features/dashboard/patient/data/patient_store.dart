import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/i18n/locale_controller.dart';
import '../../../../models/emergency_alert_record.dart';
import '../../../../services/assistance_request_sync_service.dart';
import '../../../../services/emergency_alert_service.dart';
import '../../../../services/emergency_contact_sync_service.dart';
import '../../../../services/health_alert_service.dart';
import '../../../../services/health_entry_sync_service.dart';
import '../../../../services/heart_rate_notification_service.dart';
import '../../../../services/family_service.dart';
import '../../../../services/wearable_heart_sync_service.dart';
import 'patient_models.dart';

/// In-memory mock state for the patient dashboard.
///
/// **Supabase:** [EmergencyAlertService] / [HealthAlertService] no-op if tables
/// or RLS are missing. See TODOs there.
class PatientStore extends ChangeNotifier {
  PatientStore._() {
    _seed();
    if (_vitals.heartRate != null && _vitals.recordedAt != null) {
      _heartHistory.add(
        HeartRateEntry(
          id: 'hr-seed',
          heartRate: _vitals.heartRate!,
          status: HeartRateRules.statusFor(_vitals.heartRate),
          createdAt: _vitals.recordedAt!,
        ),
      );
    }
  }

  static final PatientStore instance = PatientStore._();

  // ---------------------------------------------------------------------------
  // Connection
  // ---------------------------------------------------------------------------

  String? connectedFamilyName;
  bool connectedFamilyLoaded = false;
  bool audioModeEnabled = false;
  String language = 'en';
  bool wearableConnected = false;
  bool wearableSyncInProgress = false;
  bool wearableAutoSyncEnabled = false;
  DateTime? lastWearableSyncAt;
  String wearableSourceLabel = 'Health Connect / Apple Health';
  String? wearableLastError;
  int? wearableLastSystolic;
  int? wearableLastDiastolic;
  int? wearableLastSteps;
  double? wearableLastSpO2;
  double? wearableLastTemperatureC;
  Timer? _wearableAutoSyncTimer;
  String get wearableSetupInstructions =>
      WearableHeartSyncService.instance.setupInstructions;
  bool get wearableSyncSupported =>
      WearableHeartSyncService.instance.isSupportedPlatform;

  /// Profile presets: 100% / 120% / 140%.
  double textScale = 1.0;
  bool highContrastMode = false;
  bool biggerTextMode = false;

  void toggleAudioMode() {
    audioModeEnabled = !audioModeEnabled;
    notifyListeners();
  }

  /// Loads the family caregiver linked to this patient (by family link code).
  Future<void> refreshFamilyConnection() async {
    try {
      final name = await FamilyService().fetchLinkedFamilyMemberName();
      connectedFamilyName = name;
    } catch (_) {
      connectedFamilyName = null;
    } finally {
      connectedFamilyLoaded = true;
      notifyListeners();
    }
  }

  String get displayFamilyName =>
      (connectedFamilyName != null && connectedFamilyName!.trim().isNotEmpty)
          ? connectedFamilyName!.trim()
          : 'No family linked yet';

  void setLanguage(String value) {
    language = value;
    notifyListeners();
  }

  void setTextScalePreset(int percent) {
    switch (percent) {
      case 100:
        textScale = 1.0;
        break;
      case 120:
        textScale = 1.2;
        break;
      case 140:
        textScale = 1.4;
        break;
      default:
        textScale = (percent / 100).clamp(0.9, 1.5);
    }
    notifyListeners();
  }

  /// Legacy slider support (Profile).
  void setTextScale(double value) {
    textScale = value.clamp(0.9, 1.5);
    notifyListeners();
  }

  void toggleHighContrastMode() {
    highContrastMode = !highContrastMode;
    notifyListeners();
  }

  void toggleBiggerTextMode() {
    biggerTextMode = !biggerTextMode;
    textScale = biggerTextMode ? 1.4 : textScale.clamp(0.9, 1.4);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Emergency alert (local + optional Supabase)
  // ---------------------------------------------------------------------------

  bool _emergencyBannerDismissed = false;
  DateTime? lastEmergencyAlertSentAt;
  DailyCheckInMood? _dailyCheckInMood;
  DateTime? _dailyCheckInAt;

  bool get showEmergencyStatusBanner =>
      lastEmergencyAlertSentAt != null && !_emergencyBannerDismissed;
  static const Duration emergencyClearDelay = Duration(minutes: 2);
  DailyCheckInMood? get dailyCheckInMood => _dailyCheckInMood;
  DateTime? get dailyCheckInAt => _dailyCheckInAt;
  DateTime? get emergencyCanClearAt =>
      lastEmergencyAlertSentAt?.add(emergencyClearDelay);
  bool get canClearEmergencyAlert =>
      lastEmergencyAlertSentAt != null &&
      DateTime.now().isAfter(emergencyCanClearAt!);

  void dismissEmergencyBanner() {
    _emergencyBannerDismissed = true;
    notifyListeners();
  }

  void clearEmergencyAlert() {
    lastEmergencyAlertSentAt = null;
    _emergencyBannerDismissed = false;
    addActivity(
      type: ActivityType.familyCheckIn,
      title: 'Emergency alert cleared',
      subtitle: 'Patient marked they are safe now.',
    );
    notifyListeners();
  }

  void markEmergencyAlertSent() {
    lastEmergencyAlertSentAt = DateTime.now();
    _emergencyBannerDismissed = false;
    addActivity(
      type: ActivityType.emergencyAlert,
      title: 'Emergency alert sent',
      subtitle: 'Family and volunteers were notified.',
    );
    notifyListeners();
  }

  void setDailyCheckIn(DailyCheckInMood mood) {
    _dailyCheckInMood = mood;
    _dailyCheckInAt = DateTime.now();
    addActivity(
      type: ActivityType.familyCheckIn,
      title: switch (mood) {
        DailyCheckInMood.good => 'Daily check-in: I feel good',
        DailyCheckInMood.okay => 'Daily check-in: I feel okay',
        DailyCheckInMood.unwell => 'Daily check-in: I do not feel well',
      },
    );
    notifyListeners();
  }

  void clearDailyCheckIn() {
    _dailyCheckInMood = null;
    _dailyCheckInAt = null;
    notifyListeners();
  }

  /// Optional remote insert. Returns whether Supabase accepted the row.
  Future<bool> sendEmergencyAlertToBackend() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;

    final row = EmergencyAlertRecord(
      id: 'ea-${DateTime.now().microsecondsSinceEpoch}',
      userId: uid,
      status: 'sent',
      createdAt: DateTime.now(),
      // TODO(location): set locationLat / locationLng when geolocation is integrated.
      notifiedFamily: true,
      notifiedVolunteers: true,
    );
    return EmergencyAlertService.instance.tryInsert(row);
  }

  // ---------------------------------------------------------------------------
  // Reminders
  // ---------------------------------------------------------------------------

  final List<PatientReminder> _reminders = [];
  List<PatientReminder> get reminders => List.unmodifiable(_reminders);

  PatientReminder addReminder({
    required ReminderKind kind,
    required String title,
    required DateTime scheduledAt,
    String? notes,
    ReminderRepeat repeat = ReminderRepeat.none,
  }) {
    final rem = PatientReminder(
      id: 'rem-${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      title: title,
      scheduledAt: scheduledAt,
      notes: notes,
      repeat: repeat,
      createdAt: DateTime.now(),
    );
    _reminders.add(rem);
    _reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    notifyListeners();
    return rem;
  }

  PatientReminder? get nextReminder {
    final pending = _reminders
        .where((r) => r.state == ReminderState.pending)
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return pending.isEmpty ? null : pending.first;
  }

  int get pendingMedicationCount => _reminders
      .where((r) =>
          r.kind == ReminderKind.medication && r.state == ReminderState.pending)
      .length;

  void markReminderDone(String id) {
    final i = _reminders.indexWhere((r) => r.id == id);
    if (i == -1) return;
    _reminders[i] = _reminders[i].copyWith(state: ReminderState.done);
    addActivity(
      type: ActivityType.reminderDone,
      title: 'Medicine marked as done',
      subtitle: _reminders[i].title,
    );
    notifyListeners();
  }

  void snoozeReminder(String id, Duration delay) {
    final i = _reminders.indexWhere((r) => r.id == id);
    if (i == -1) return;
    final r = _reminders[i];
    if (r.state == ReminderState.done) return;
    _reminders[i] = r.copyWith(scheduledAt: r.scheduledAt.add(delay));
    _reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    addActivity(
      type: ActivityType.reminderSnoozed,
      title: 'Reminder snoozed',
      subtitle: r.title,
    );
    notifyListeners();
  }

  int get todayMedicationTotal => _reminders
      .where((r) => r.kind == ReminderKind.medication)
      .length;

  int get todayMedicationDone => _reminders
      .where(
        (r) => r.kind == ReminderKind.medication && r.state == ReminderState.done,
      )
      .length;

  int get todayReminderTotal {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _reminders.where((r) {
      final d = DateTime(r.scheduledAt.year, r.scheduledAt.month, r.scheduledAt.day);
      return d == today;
    }).length;
  }

  int get todayReminderDone {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _reminders.where((r) {
      final d = DateTime(r.scheduledAt.year, r.scheduledAt.month, r.scheduledAt.day);
      return d == today && r.state == ReminderState.done;
    }).length;
  }

  int get missedRemindersCount => _reminders
      .where(
        (r) =>
            r.state == ReminderState.pending && r.scheduledAt.isBefore(DateTime.now()),
      )
      .length;

  // ---------------------------------------------------------------------------
  // Health (heart rate)
  // ---------------------------------------------------------------------------

  Vitals _vitals = Vitals(
    heartRate: 78,
    recordedAt: DateTime.now().subtract(const Duration(minutes: 30)),
  );
  Vitals get vitals => _vitals;

  final List<HeartRateEntry> _heartHistory = [];
  final List<HealthEntry> _healthEntries = [];

  List<HeartRateEntry> get heartRateHistory =>
      List.unmodifiable(_heartHistory);
  List<HealthEntry> get healthEntries => List.unmodifiable(_healthEntries);
  HealthStatus get healthStatus {
    if (_healthEntries.isNotEmpty) return _healthEntries.first.status;
    return HeartRateRules.statusFor(_vitals.heartRate);
  }

  PatientOverallStatus get overallStatus {
    if (lastEmergencyAlertSentAt != null || healthStatus == HealthStatus.emergency) {
      return PatientOverallStatus.emergency;
    }
    if (missedRemindersCount > 0 || healthStatus == HealthStatus.warning) {
      return PatientOverallStatus.needsAttention;
    }
    return PatientOverallStatus.safe;
  }

  /// Returns whether the reading was persisted to Supabase (when logged in).
  Future<bool> recordVitals({
    required int heartRate,
    int? systolic,
    int? diastolic,
    double? bloodSugar,
    double? temperatureC,
    String? notes,
  }) async {
    if (!HeartRateRules.isPlausible(heartRate)) {
      throw ArgumentError('implausible');
    }
    final status = HeartRateRules.statusFor(heartRate);
    final at = DateTime.now();
    _vitals = Vitals(heartRate: heartRate, recordedAt: at);
    final entry = HeartRateEntry(
      id: 'hr-${at.microsecondsSinceEpoch}',
      heartRate: heartRate,
      status: status,
      createdAt: at,
      notes: (notes == null || notes.trim().isEmpty)
          ? null
          : notes.trim(),
    );
    _heartHistory.insert(0, entry);
    final full = HealthEntry(
      id: entry.id,
      heartRate: heartRate,
      systolic: systolic,
      diastolic: diastolic,
      bloodSugar: bloodSugar,
      temperatureC: temperatureC,
      notes: entry.notes,
      status: status,
      createdAt: at,
    );
    _healthEntries.insert(0, full);
    while (_heartHistory.length > 50) {
      _heartHistory.removeLast();
    }
    while (_healthEntries.length > 50) {
      _healthEntries.removeLast();
    }
    addActivity(
      type: ActivityType.healthEntered,
      title: 'Health value entered',
      subtitle: '$heartRate bpm',
    );
    notifyListeners();

    if (status == HealthStatus.warning || status == HealthStatus.emergency) {
      await HealthAlertService.instance.tryNotifyAbnormalReading(
        heartRate: heartRate,
        status: status,
        notes: notes,
      );
      await HeartRateNotificationService.instance.showAbnormalHeartRateAlert(
        heartRate: heartRate,
        level: status.name,
      );
    }

    return HealthEntrySyncService.instance.tryInsertHeartRate(entry);
  }

  Future<void> syncHeartRateFromWearable() async {
    if (wearableSyncInProgress) return;
    wearableSyncInProgress = true;
    wearableLastError = null;
    notifyListeners();

    final result = await WearableHeartSyncService.instance.fetchLatestVitals(
      promptInstall: true,
    );
    wearableSyncInProgress = false;

    if (!result.success || !result.hasAnyVital) {
      wearableConnected = false;
      wearableLastError = result.errorMessage ?? 'Wearable sync failed.';
      notifyListeners();
      return;
    }

    wearableConnected = true;
    lastWearableSyncAt = DateTime.now();
    wearableSourceLabel = result.sourceLabel ?? wearableSourceLabel;
    wearableLastError = null;
    wearableLastSystolic = result.systolic ?? wearableLastSystolic;
    wearableLastDiastolic = result.diastolic ?? wearableLastDiastolic;
    wearableLastSteps = result.steps ?? wearableLastSteps;
    wearableLastSpO2 = result.oxygenSaturation ?? wearableLastSpO2;
    wearableLastTemperatureC = result.temperatureC ?? wearableLastTemperatureC;

    if (result.heartRateBpm != null) {
      await recordVitals(
        heartRate: result.heartRateBpm!,
        systolic: result.systolic,
        diastolic: result.diastolic,
        temperatureC: result.temperatureC,
        notes: 'Synced from wearable',
      );
    }
    notifyListeners();
  }

  Future<void> setWearableAutoSyncEnabled(bool enabled) async {
    wearableAutoSyncEnabled = enabled;
    _wearableAutoSyncTimer?.cancel();
    _wearableAutoSyncTimer = null;

    if (!enabled) {
      notifyListeners();
      return;
    }

    if (!wearableSyncSupported) {
      wearableAutoSyncEnabled = false;
      wearableLastError = 'Live sync is available only on Android/iPhone.';
      notifyListeners();
      return;
    }

    await syncHeartRateFromWearable();
    if (!wearableConnected) {
      wearableAutoSyncEnabled = false;
      notifyListeners();
      return;
    }

    _wearableAutoSyncTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => syncHeartRateFromWearable(),
    );
    notifyListeners();
  }

  void handleAppLifecycle(AppLifecycleState state) {
    if (!wearableAutoSyncEnabled) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _wearableAutoSyncTimer?.cancel();
      _wearableAutoSyncTimer = null;
      return;
    }
    if (state == AppLifecycleState.resumed && _wearableAutoSyncTimer == null) {
      _wearableAutoSyncTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => syncHeartRateFromWearable(),
      );
      syncHeartRateFromWearable();
    }
  }

  // ---------------------------------------------------------------------------
  // Assistance request
  // ---------------------------------------------------------------------------

  AssistanceRequest? _activeRequest;
  AssistanceRequest? get activeRequest => _activeRequest;

  final List<EmergencyContact> _contacts = [
    const EmergencyContact(
      id: 'ec-1',
      name: 'Arben H.',
      phone: '+355681234567',
      relationship: 'Son',
      priority: 1,
    ),
    const EmergencyContact(
      id: 'ec-2',
      name: 'Mira K.',
      phone: '+355692222221',
      relationship: 'Daughter',
      priority: 2,
    ),
  ];
  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);

  EmergencyContact? get primaryEmergencyContact {
    if (_contacts.isEmpty) return null;
    final sorted = List<EmergencyContact>.from(_contacts)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return sorted.first;
  }

  /// Returns whether Supabase accepted the row (`false` is OK — contact stays local).
  Future<bool> addContact(EmergencyContact c) async {
    _contacts.add(c);
    notifyListeners();
    return EmergencyContactSyncService.instance.tryInsert(c);
  }

  void updateContact(EmergencyContact updated) {
    final i = _contacts.indexWhere((e) => e.id == updated.id);
    if (i == -1) return;
    _contacts[i] = updated;
    notifyListeners();
  }

  void removeContact(String id) {
    _contacts.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Returns whether Supabase accepted the row (`false` is OK — request stays local).
  Future<bool> submitAssistanceRequest({
    required AssistanceRequestKind kind,
    required AssistanceRequestWhen when,
    DateTime? customDate,
    String? note,
  }) async {
    final req = AssistanceRequest(
      id: 'req-${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      when: when,
      customDate: customDate,
      note: note,
      state: AssistanceRequestState.pending,
      createdAt: DateTime.now(),
    );
    _activeRequest = req;
    addActivity(
      type: ActivityType.helpRequested,
      title: 'Help request sent',
      subtitle: kind.label,
    );
    notifyListeners();
    return AssistanceRequestSyncService.instance.tryInsert(req);
  }

  final List<RoutineTask> _todayRoutine = [
    const RoutineTask(
      kind: RoutineTaskKind.morningMedicine,
      label: 'Take morning medicine',
    ),
    const RoutineTask(kind: RoutineTaskKind.drinkWater, label: 'Drink water'),
    const RoutineTask(kind: RoutineTaskKind.shortWalk, label: 'Take a short walk'),
    const RoutineTask(
      kind: RoutineTaskKind.checkBloodPressure,
      label: 'Check blood pressure',
    ),
    const RoutineTask(kind: RoutineTaskKind.callFamily, label: 'Call family'),
  ];
  List<RoutineTask> get todayRoutine => List.unmodifiable(_todayRoutine);

  void toggleRoutineTask(RoutineTaskKind kind) {
    final i = _todayRoutine.indexWhere((t) => t.kind == kind);
    if (i == -1) return;
    final next = !_todayRoutine[i].completed;
    _todayRoutine[i] = _todayRoutine[i].copyWith(completed: next);
    notifyListeners();
  }

  final List<PatientActivity> _activities = [];
  List<PatientActivity> get recentActivities => List.unmodifiable(_activities);

  void addActivity({
    required ActivityType type,
    required String title,
    String? subtitle,
  }) {
    _activities.insert(
      0,
      PatientActivity(
        id: 'act-${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        title: title,
        subtitle: subtitle,
        at: DateTime.now(),
      ),
    );
    while (_activities.length > 30) {
      _activities.removeLast();
    }
  }

  void cancelActiveRequest() {
    _activeRequest = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Daily content
  // ---------------------------------------------------------------------------

  static const List<String> _dailyTipsEn = [
    'Drink a glass of water every 2 hours today.',
    'A short walk after lunch helps digestion.',
    'Take your blood pressure pill at the same time each day.',
    'Open a window for fresh air for 10 minutes.',
    'Call someone you love today, even for a minute.',
    "Stretch your arms and shoulders — it helps with stiffness.",
    'Eat a piece of fruit before bedtime.',
  ];

  static const List<String> _dailyTipsSq = [
    'Pini nje gote uje cdo 2 ore sot.',
    'Nje shetitje e shkurter pas drekes ndihmon tretjen.',
    'Merrni ilacin e tensionit ne te njejten ore cdo dite.',
    'Hapni dritaren per ajer te paster per 10 minuta.',
    'Telefononi dike qe e doni sot, edhe per nje minute.',
    'Beni shtrirje te kraheve dhe shpatullave — ndihmon kunder ngurtesimit.',
    'Hani nje cope frut para gjumit.',
  ];

  List<String> get _localizedDailyTips =>
      LocaleController.instance.code == 'sq' ? _dailyTipsSq : _dailyTipsEn;

  String get dailyTip {
    final tips = _localizedDailyTips;
    final dayOfYear = int.parse(
      '${DateTime.now().difference(DateTime(DateTime.now().year)).inDays}',
    );
    return tips[dayOfYear % tips.length];
  }

  List<String> get dailyTips => _localizedDailyTips;

  void _seed() {
    final now = DateTime.now();
    DateTime at(int hour, [int minute = 0]) =>
        DateTime(now.year, now.month, now.day, hour, minute);

    _reminders.addAll([
      PatientReminder(
        id: 'rem-1',
        kind: ReminderKind.medication,
        title: 'Aspirin 100 mg',
        scheduledAt: at(9),
        createdAt: now,
      ),
      PatientReminder(
        id: 'rem-2',
        kind: ReminderKind.medication,
        title: 'Blood pressure pill',
        scheduledAt: at(14),
        createdAt: now,
      ),
      PatientReminder(
        id: 'rem-3',
        kind: ReminderKind.appointment,
        title: 'Doctor — Dr. Hoxha',
        scheduledAt: at(15, 30),
        createdAt: now,
      ),
    ]);
    _activities.add(
      PatientActivity(
        id: 'act-seed',
        type: ActivityType.familyCheckIn,
        title: 'Family check-in sent',
        subtitle: 'Your family was informed you are okay.',
        at: now.subtract(const Duration(hours: 2)),
      ),
    );
  }
}
