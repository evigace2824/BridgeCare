import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../utils/care_bridge_layout.dart';
import '../../../../widgets/carebridge/care_bridge_status_badge.dart';
import '../data/patient_models.dart';
import '../data/patient_store.dart';
import '../widgets/enter_health_values_sheet.dart';
import '../widgets/health_status_card.dart';
import '../widgets/section_title.dart';

/// Health tab — heart rate, history, guidance.
class HealthTab extends StatelessWidget {
  const HealthTab({super.key});

  static String _since(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return context.tr('Just now');
    if (diff.inMinutes < 60) {
      return context.tr('{n} min ago', {'n': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return context.tr('{n}h ago', {'n': '${diff.inHours}'});
    }
    return context.tr('{n}d ago', {'n': '${diff.inDays}'});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PatientStore.instance,
      builder: (context, _) {
        final store = PatientStore.instance;
        final v = store.vitals;
        final hist = store.healthEntries.take(10).toList();

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: CareBridgeLayout.tabScreenPadding(context),
            children: [
              Text(
                context.tr('Health'),
                style: GoogleFonts.inter(
                  fontSize: PatientText.titleL,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('Track heart rate.'),
                style: GoogleFonts.inter(
                  fontSize: PatientText.bodyM,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              _WearableSyncCard(store: store),
              const SizedBox(height: 16),
              HealthStatusCard(
                vitals: v,
                status: store.healthStatus,
                onEnterValues: () => EnterHealthValuesSheet.show(context),
              ),
              const SizedBox(height: 22),
              SectionTitle(context.tr('Recent history')),
              const SizedBox(height: 8),
              if (hist.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_outline_rounded, color: AppColors.textMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr('No recent health history yet.'),
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final e in hist) ...[
                  _HistoryRow(
                    time: _since(context, e.createdAt),
                    label: context.tr('Heart rate'),
                    value: '${e.heartRate} bpm',
                    status: e.status,
                    note:
                        '${e.systolic != null && e.diastolic != null ? 'BP ${e.systolic}/${e.diastolic}. ' : ''}'
                        '${e.bloodSugar != null ? 'Sugar ${e.bloodSugar}. ' : ''}'
                        '${e.temperatureC != null ? 'Temp ${e.temperatureC}°C. ' : ''}'
                        '${e.notes ?? ''}',
                  ),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr(
                          'Enter your heart rate by tapping "Enter health values" above. Your family will be notified if a value is in the Warning or Emergency range.',
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WearableSyncCard extends StatelessWidget {
  const _WearableSyncCard({required this.store});

  final PatientStore store;

  @override
  Widget build(BuildContext context) {
    final syncedAt = store.lastWearableSyncAt;
    final unsupported = !store.wearableSyncSupported;
    final showSetupHint = unsupported || (!store.wearableConnected && store.wearableLastError != null);
    final subtitle = syncedAt == null
        ? (store.wearableLastError ?? 'Connect your smartwatch for automatic heart-rate sync.')
        : 'Last synced ${HealthTab._since(context, syncedAt)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14133A63),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF24B6A8), Color(0xFF1FA59A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4024B6A8),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.watch_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smartwatch Sync',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      store.wearableSourceLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              CareBridgeStatusBadge(
                label: store.wearableConnected ? 'Connected' : 'Not connected',
                color: store.wearableConnected ? AppColors.success : AppColors.warning,
                dense: true,
              ),
            ],
          ),
          if (store.wearableConnected || syncedAt != null) ...[
            const SizedBox(height: 14),
            _VitalsGrid(store: store),
          ],
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (showSetupHint) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6E8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD79A)),
              ),
              child: Text(
                unsupported
                    ? store.wearableSetupInstructions
                    : 'If sync fails, open Setup and complete health permissions first.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF8E5D00),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: store.wearableSyncInProgress || unsupported
                      ? null
                      : () => PatientStore.instance.syncHeartRateFromWearable(),
                  icon: store.wearableSyncInProgress
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: Text(
                    store.wearableSyncInProgress
                        ? 'Syncing...'
                        : (store.wearableConnected ? 'Sync latest heart rate' : 'Connect and sync'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 110,
                child: OutlinedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Connect smartwatch'),
                        content: Text(
                          store.wearableSetupInstructions,
                          style: GoogleFonts.inter(fontSize: 13.5),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Setup'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Live sync (every 20s)',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  value: store.wearableAutoSyncEnabled,
                  onChanged: (v) => PatientStore.instance.setWearableAutoSyncEnabled(v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.time,
    required this.label,
    required this.value,
    required this.status,
    this.note,
  });

  final String time;
  final String label;
  final String value;
  final HealthStatus status;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = switch (status) {
      HealthStatus.normal => ('Normal', AppColors.success),
      HealthStatus.warning => ('Warning', AppColors.warning),
      HealthStatus.emergency => ('Emergency', AppColors.emergency),
      HealthStatus.unknown => ('No data', AppColors.textMuted),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              CareBridgeStatusBadge(
                label: context.tr(statusLabel),
                color: statusColor,
                dense: true,
              ),
            ],
          ),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VitalsGrid extends StatelessWidget {
  const _VitalsGrid({required this.store});

  final PatientStore store;

  @override
  Widget build(BuildContext context) {
    final hr = store.vitals.heartRate;
    final sys = store.wearableLastSystolic;
    final dia = store.wearableLastDiastolic;
    final steps = store.wearableLastSteps;
    final spo2 = store.wearableLastSpO2;
    final tempC = store.wearableLastTemperatureC;

    final tiles = <Widget>[
      _VitalTile(
        icon: Icons.favorite_rounded,
        accent: const Color(0xFFE53935),
        label: 'Heart',
        value: hr != null ? '$hr' : '--',
        unit: 'bpm',
      ),
      _VitalTile(
        icon: Icons.monitor_heart_rounded,
        accent: const Color(0xFF1976D2),
        label: 'Blood pressure',
        value: (sys != null && dia != null) ? '$sys/$dia' : '--',
        unit: 'mmHg',
      ),
      _VitalTile(
        icon: Icons.directions_walk_rounded,
        accent: const Color(0xFF24B6A8),
        label: 'Steps today',
        value: steps != null ? '$steps' : '--',
        unit: 'steps',
      ),
      _VitalTile(
        icon: Icons.bubble_chart_rounded,
        accent: const Color(0xFF7C4DFF),
        label: 'Oxygen',
        value: spo2 != null ? spo2.toStringAsFixed(0) : '--',
        unit: '% SpO2',
      ),
      _VitalTile(
        icon: Icons.thermostat_rounded,
        accent: const Color(0xFFFB8C00),
        label: 'Temperature',
        value: tempC != null ? tempC.toStringAsFixed(1) : '--',
        unit: '°C',
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.4,
      children: tiles,
    );
  }
}

class _VitalTile extends StatelessWidget {
  const _VitalTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.unit,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
