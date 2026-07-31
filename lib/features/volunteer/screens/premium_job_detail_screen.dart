import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/job_post_model.dart';
import '../../../services/job_post_service.dart';
import '../../../services/volunteer_skill_match_service.dart';
import '../data/volunteer_store.dart';
import '../widgets/job_apply_sheet.dart';
import '../widgets/volunteer_job_view_status.dart';
import '../widgets/volunteer_theme.dart';

/// Full job details before applying (premium flow).
class PremiumJobDetailScreen extends StatefulWidget {
  const PremiumJobDetailScreen({super.key, required this.job});

  final JobPostModel job;

  @override
  State<PremiumJobDetailScreen> createState() => _PremiumJobDetailScreenState();
}

class _PremiumJobDetailScreenState extends State<PremiumJobDetailScreen> {
  String get _volunteerId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'volunteer_local';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: JobPostService.instance,
      builder: (context, _) {
        JobPostModel job = widget.job;
        for (final p in JobPostService.instance.allPosts) {
          if (p.id == widget.job.id) {
            job = p;
            break;
          }
        }
        final viewStatus =
            VolunteerJobStatusHelper.of(job, _volunteerId);
        final statusColor = VolunteerJobStatusHelper.color(viewStatus);
        final timeFmt = DateFormat('EEE d MMM · HH:mm');
        final store = VolunteerStore.instance;
        final match = VolunteerSkillMatchService.instance.matchLabel(job);

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: AppBar(
            title: const Text('Job details'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _header(job, match),
              const SizedBox(height: 16),
              _section('Description', job.description),
              _section('Care type', job.careType),
              _section('Location', job.location),
              _section('Preferred time', timeFmt.format(job.preferredAt)),
              _section('Duration', job.durationLabel),
              _section('Urgency', _urgencyLabel(job.urgency)),
              if (job.budget != null && job.budget!.isNotEmpty)
                _section('Budget', job.budget!),
              if (job.linkedElderlyName != null)
                _section('Care recipient', job.linkedElderlyName!),
              const SizedBox(height: 12),
              Row(
                children: [
                  _chip(
                    VolunteerJobStatusHelper.label(viewStatus),
                    statusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    job.remainingLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ..._actions(context, job, viewStatus, store),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _actions(
    BuildContext context,
    JobPostModel job,
    VolunteerJobViewStatus viewStatus,
    VolunteerStore store,
  ) {
    switch (viewStatus) {
      case VolunteerJobViewStatus.active:
        return [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final sent = await JobApplySheet.show(context, job);
                if (sent == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Application sent — awaiting family review'),
                    ),
                  );
                  setState(() {});
                }
              },
              icon: const Icon(Icons.send_rounded),
              label: const Text('Apply for Job'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ];
      case VolunteerJobViewStatus.applicationSent:
        return [
          _infoBanner(
            Icons.hourglass_top_rounded,
            'Application Sent',
            'The family will review your profile. You cannot start until they accept you.',
            const Color(0xFF6366F1),
          ),
        ];
      case VolunteerJobViewStatus.acceptedByFamily:
        return [
          _infoBanner(
            Icons.check_circle_rounded,
            'Accepted by Family',
            'You can start this job when you are ready.',
            const Color(0xFF1B74E4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                JobPostService.instance
                    .volunteerStartJob(job.id, _volunteerId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job started')),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Job'),
            ),
          ),
        ];
      case VolunteerJobViewStatus.inProgress:
        return [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                JobPostService.instance
                    .volunteerCompleteJob(job.id, _volunteerId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Marked completed — waiting for family confirmation'),
                  ),
                );
              },
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Mark as Completed'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
            ),
          ),
        ];
      case VolunteerJobViewStatus.completedAwaitingConfirm:
        return [
          _infoBanner(
            Icons.pending_actions_rounded,
            'Awaiting confirmation',
            'The family will confirm completion to finalize points.',
            const Color(0xFF6B7280),
          ),
        ];
      case VolunteerJobViewStatus.confirmed:
        return [
          _infoBanner(
            Icons.verified_rounded,
            'Confirmed',
            'This job is fully complete. Thank you!',
            const Color(0xFF059669),
          ),
        ];
      case VolunteerJobViewStatus.rejected:
        return [
          _infoBanner(
            Icons.info_outline_rounded,
            'Not selected',
            'Another volunteer was chosen for this job.',
            const Color(0xFFEF4444),
          ),
        ];
      case VolunteerJobViewStatus.expired:
        return [
          _infoBanner(
            Icons.timer_off_rounded,
            'Expired',
            'This posting is no longer active.',
            const Color(0xFF9CA3AF),
          ),
        ];
    }
  }

  Widget _header(JobPostModel job, String? match) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_history_rounded, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          if (match != null) ...[
            const SizedBox(height: 8),
            _chip(match, const Color(0xFF10B981)),
          ],
          const SizedBox(height: 8),
          Text(
            '+${(22 * VolunteerStore.instance.currentPlan.pointsMultiplier).round()} pts when confirmed',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: VolunteerTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: VolunteerTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: VolunteerTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static String _urgencyLabel(JobUrgency u) => switch (u) {
        JobUrgency.low => 'Low',
        JobUrgency.medium => 'Medium',
        JobUrgency.high => 'High',
        JobUrgency.urgent => 'Urgent',
      };
}
