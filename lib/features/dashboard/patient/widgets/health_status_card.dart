import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../widgets/carebridge/care_bridge_card.dart';
import '../../../../widgets/carebridge/care_bridge_status_badge.dart';
import '../data/patient_models.dart';

/// Health status summary card for the patient home (Spec §7.10).
/// Shows heart rate and an overall status pill. Tapping "Enter Health Values"
/// opens the [EnterHealthValuesSheet] supplied via [onEnterValues].
class HealthStatusCard extends StatelessWidget {
  const HealthStatusCard({
    super.key,
    required this.vitals,
    required this.status,
    required this.onEnterValues,
  });

  final Vitals vitals;
  final HealthStatus status;
  final VoidCallback onEnterValues;

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor, statusBg, statusIcon) = switch (status) {
      HealthStatus.normal => (
        'Normal',
        AppColors.success,
        AppColors.successSoft,
        Icons.check_circle_rounded,
      ),
      HealthStatus.warning => (
        'Warning',
        AppColors.warning,
        AppColors.warningSoft,
        Icons.warning_amber_rounded,
      ),
      HealthStatus.emergency => (
        'Emergency',
        AppColors.emergency,
        AppColors.emergencySoft,
        Icons.priority_high_rounded,
      ),
      HealthStatus.unknown => (
        'No data',
        AppColors.textMuted,
        AppColors.border,
        Icons.help_outline_rounded,
      ),
    };

    return CareBridgeCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: AppColors.accentPink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('Health Today'),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              CareBridgeStatusBadge(
                label: context.tr(statusLabel),
                color: statusColor,
                backgroundColor: statusBg,
                icon: statusIcon,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _MetricRow(
            icon: Icons.favorite_rounded,
            color: AppColors.accentPink,
            label: 'Heart rate',
            value: vitals.heartRate != null ? '${vitals.heartRate} bpm' : '— bpm',
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onEnterValues,
              icon: const Icon(Icons.edit_rounded, size: 20),
              label: Text(context.tr('Enter health values')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            context.tr(label),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
