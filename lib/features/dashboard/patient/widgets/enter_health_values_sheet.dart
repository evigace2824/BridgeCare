import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../data/patient_models.dart';
import '../data/patient_store.dart';

/// Bottom sheet: heart rate + optional notes. Validates 30–220 bpm.
class EnterHealthValuesSheet extends StatefulWidget {
  const EnterHealthValuesSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const EnterHealthValuesSheet(),
      );

  @override
  State<EnterHealthValuesSheet> createState() =>
      _EnterHealthValuesSheetState();
}

class _EnterHealthValuesSheetState extends State<EnterHealthValuesSheet> {
  final _hrCtrl = TextEditingController();
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _tempCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = PatientStore.instance.vitals;
    if (v.heartRate != null) _hrCtrl.text = '${v.heartRate}';
  }

  @override
  void dispose() {
    _hrCtrl.dispose();
    _sysCtrl.dispose();
    _diaCtrl.dispose();
    _sugarCtrl.dispose();
    _tempCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  HealthStatus _statusFor({
    required int hr,
    int? systolic,
    int? diastolic,
  }) {
    final hrStatus = hr < 50 || hr > 120
        ? HealthStatus.emergency
        : ((hr >= 50 && hr <= 59) || (hr >= 101 && hr <= 120))
            ? HealthStatus.warning
            : HealthStatus.normal;
    final bpStatus = (systolic != null && diastolic != null)
        ? (systolic >= 180 || diastolic >= 110)
            ? HealthStatus.emergency
            : (systolic >= 130 || diastolic >= 85)
                ? HealthStatus.warning
                : HealthStatus.normal
        : HealthStatus.normal;
    if (hrStatus == HealthStatus.emergency || bpStatus == HealthStatus.emergency) {
      return HealthStatus.emergency;
    }
    if (hrStatus == HealthStatus.warning || bpStatus == HealthStatus.warning) {
      return HealthStatus.warning;
    }
    return HealthStatus.normal;
  }

  Future<void> _save(BuildContext context) async {
    setState(() => _error = null);
    final raw = _hrCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = context.tr('Please enter your heart rate.'));
      return;
    }
    final hr = int.tryParse(raw);
    if (hr == null) {
      setState(() => _error = context.tr('Enter a valid number.'));
      return;
    }
    if (!HeartRateRules.isPlausible(hr)) {
      setState(
        () => _error = context.tr(
          'Enter a heart rate between 30 and 220.',
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final warnReading = context.tr(
      'Your reading looks unusual. Your family will be notified.',
    );
    final savedReading = context.tr('Reading saved.');
    final syncHint = context.tr(
      'Saved on this device. Could not sync to the cloud.',
    );
    try {
      final sys = int.tryParse(_sysCtrl.text.trim());
      final dia = int.tryParse(_diaCtrl.text.trim());
      final sugar = double.tryParse(_sugarCtrl.text.trim());
      final temp = double.tryParse(_tempCtrl.text.trim());
      final computedStatus = _statusFor(
        hr: hr,
        systolic: sys,
        diastolic: dia,
      );
      final synced = await PatientStore.instance.recordVitals(
        heartRate: hr,
        systolic: sys,
        diastolic: dia,
        bloodSugar: sugar,
        temperatureC: temp,
        notes:
            '${(sys != null && dia != null) ? 'BP: $sys/$dia' : ''}'
            '${sugar != null ? ', Sugar: $sugar' : ''}'
            '${temp != null ? ', Temp: $temp°C' : ''}'
            '${_notesCtrl.text.trim().isEmpty ? '' : ', ${_notesCtrl.text.trim()}'}',
      );
      if (!context.mounted) return;
      final st = computedStatus;
      final loggedIn = Supabase.instance.client.auth.currentUser != null;
      Navigator.pop(context);

      if (st == HealthStatus.warning || st == HealthStatus.emergency) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor:
                st == HealthStatus.emergency ? AppColors.emergency : AppColors.warning,
            content: Text(warnReading),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(savedReading),
          ),
        );
      }

      if (!synced && loggedIn) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    syncHint,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } on ArgumentError {
      if (context.mounted) {
        setState(() {
          _error = context.tr('Enter a heart rate between 30 and 220.');
          _saving = false;
        });
      }
    } catch (_) {
      if (context.mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('Enter health values'),
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('Use your home device and type the numbers below.'),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              context.tr('Heart rate'),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _hrCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: context.tr('e.g. 78'),
                suffixText: 'bpm',
                suffixStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sugarCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: context.tr('Blood sugar (optional)'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sysCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        InputDecoration(labelText: context.tr('Systolic')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _diaCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        InputDecoration(labelText: context.tr('Diastolic')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tempCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: context.tr('Temperature (optional)'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.tr('Notes (optional)'),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () => _save(context),
                icon: const Icon(Icons.save_rounded),
                label: Text(context.tr('Save')),
                style: ElevatedButton.styleFrom(
                  textStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
