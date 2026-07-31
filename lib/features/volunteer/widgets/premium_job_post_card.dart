import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/job_post_model.dart';
import '../../../services/volunteer_skill_match_service.dart';
import '../data/volunteer_models.dart';
import '../data/volunteer_store.dart';
import '../screens/premium_job_detail_screen.dart';
import 'volunteer_job_view_status.dart';
import 'volunteer_theme.dart';

/// Summary card for premium job posts — tap for full details and actions.
class PremiumJobPostCard extends StatelessWidget {
  const PremiumJobPostCard({
    super.key,
    required this.job,
  });

  final JobPostModel job;

  String get _volunteerId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'volunteer_local';

  @override
  Widget build(BuildContext context) {
    final viewStatus = VolunteerJobStatusHelper.of(job, _volunteerId);
    final statusColor = VolunteerJobStatusHelper.color(viewStatus);
    final match = VolunteerSkillMatchService.instance.matchLabel(job);
    final urgColor = VolunteerTheme.colorForUrgency(_mapUrgency(job.urgency));
    final timeFmt = DateFormat('EEE d MMM · HH:mm');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PremiumJobDetailScreen(job: job),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.work_history_rounded,
                          color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  job.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              _chip('PREMIUM JOB', const Color(0xFF7C3AED)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.careType,
                            style: const TextStyle(
                              fontSize: 12,
                              color: VolunteerTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: VolunteerTheme.textSecondary),
                  ],
                ),
                if (match != null) ...[
                  const SizedBox(height: 8),
                  _chip(
                    match,
                    match == 'Best Match'
                        ? const Color(0xFF10B981)
                        : const Color(0xFF1B74E4),
                  ),
                ],
                const SizedBox(height: 10),
                _infoRow(Icons.place_rounded, job.location),
                _infoRow(
                  Icons.straighten_rounded,
                  'Within ${VolunteerStore.instance.maxRadiusKm.toStringAsFixed(0)} km',
                ),
                _infoRow(Icons.event_rounded, timeFmt.format(job.preferredAt)),
                _infoRow(Icons.schedule_rounded, job.durationLabel),
                _infoRow(Icons.flag_rounded, _urgencyLabel(job.urgency),
                    color: urgColor),
                if (job.budget != null && job.budget!.isNotEmpty)
                  _infoRow(Icons.payments_outlined, job.budget!),
                if (job.linkedElderlyName != null)
                  _infoRow(Icons.person_rounded,
                      'Care for ${job.linkedElderlyName}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chip(
                        VolunteerJobStatusHelper.label(viewStatus),
                        statusColor),
                    const SizedBox(width: 8),
                    Icon(Icons.timer_outlined, size: 14, color: statusColor),
                    Text(
                      job.remainingLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '+${(22 * VolunteerStore.instance.currentPlan.pointsMultiplier).round()} pts',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _ctaHint(viewStatus),
                  style: const TextStyle(
                    fontSize: 12,
                    color: VolunteerTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _ctaHint(VolunteerJobViewStatus s) => switch (s) {
        VolunteerJobViewStatus.active => 'Tap to view details · Apply for Job',
        VolunteerJobViewStatus.applicationSent =>
          'Application sent — waiting for family',
        VolunteerJobViewStatus.acceptedByFamily =>
          'Tap to start job when ready',
        VolunteerJobViewStatus.inProgress => 'Tap to mark as completed',
        VolunteerJobViewStatus.completedAwaitingConfirm =>
          'Waiting for family to confirm',
        VolunteerJobViewStatus.confirmed => 'Job confirmed — complete',
        VolunteerJobViewStatus.rejected => 'Tap for details',
        VolunteerJobViewStatus.expired => 'Posting expired',
      };

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color ?? VolunteerTheme.textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color ?? VolunteerTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static VolunteerUrgency _mapUrgency(JobUrgency u) => switch (u) {
        JobUrgency.low => VolunteerUrgency.low,
        JobUrgency.high => VolunteerUrgency.high,
        JobUrgency.urgent => VolunteerUrgency.sos,
        JobUrgency.medium => VolunteerUrgency.medium,
      };

  static String _urgencyLabel(JobUrgency u) => switch (u) {
        JobUrgency.low => 'Low urgency',
        JobUrgency.medium => 'Medium urgency',
        JobUrgency.high => 'High urgency',
        JobUrgency.urgent => 'Urgent',
      };
}
