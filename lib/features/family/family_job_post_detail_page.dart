import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/volunteer/data/volunteer_store.dart';
import '../../features/volunteer/widgets/volunteer_care_profile_card.dart';
import '../../models/job_application_model.dart';
import '../../models/job_post_model.dart';
import '../../services/job_post_service.dart';

/// Family reviews volunteer applications and confirms completion.
class FamilyJobPostDetailPage extends StatefulWidget {
  const FamilyJobPostDetailPage({super.key, required this.job});

  final JobPostModel job;

  @override
  State<FamilyJobPostDetailPage> createState() =>
      _FamilyJobPostDetailPageState();
}

class _FamilyJobPostDetailPageState extends State<FamilyJobPostDetailPage> {
  @override
  void initState() {
    super.initState();
    JobPostService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    JobPostService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    JobPostModel job = widget.job;
    for (final p in JobPostService.instance.allPosts) {
      if (p.id == widget.job.id) {
        job = p;
        break;
      }
    }
    final apps = JobPostService.instance.applicationsForPost(job.id);
    final pending = apps
        .where((a) => a.status == JobApplicationStatus.pending)
        .length;
    final timeFmt = DateFormat('EEE d MMM · HH:mm');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(title: Text(job.title)),
      body: ListenableBuilder(
        listenable: JobPostService.instance,
        builder: (context, _) {
          JobPostModel current = job;
          for (final p in JobPostService.instance.allPosts) {
            if (p.id == widget.job.id) {
              current = p;
              break;
            }
          }
          final applications =
              JobPostService.instance.applicationsForPost(current.id);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _statusCard(current),
              const SizedBox(height: 12),
              _detailTile('Care type', current.careType),
              _detailTile('Location', current.location),
              _detailTile('When', timeFmt.format(current.preferredAt)),
              _detailTile('Duration', current.durationLabel),
              if (current.description.isNotEmpty)
                _detailTile('Description', current.description),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Applications',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (pending > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$pending pending',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (applications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No applications yet. Verified volunteers can apply from the Jobs tab.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                )
              else
                ...applications.map((a) => _applicationCard(current, a)),
              if (JobPostService.instance.canFamilyConfirm(current.id)) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      JobPostService.instance.confirmCompletion(current.id);
                      VolunteerStore.instance
                          .awardPremiumJobPoints(current.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Completion confirmed — job closed'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('Confirm Completion'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _statusCard(JobPostModel job) {
    final status = job.effectiveStatus;
    final (color, label) = switch (status) {
      JobPostStatus.active => (const Color(0xFF10B981), 'Active'),
      JobPostStatus.accepted => (const Color(0xFF1B74E4), 'Accepted'),
      JobPostStatus.inProgress => (const Color(0xFFF59E0B), 'In progress'),
      JobPostStatus.completed => (const Color(0xFF6B7280), 'Completed'),
      JobPostStatus.confirmed => (const Color(0xFF059669), 'Confirmed'),
      JobPostStatus.expired => (const Color(0xFF9CA3AF), 'Expired'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const Spacer(),
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            job.remainingLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _applicationCard(JobPostModel job, JobApplicationModel app) {
    final canAct = app.status == JobApplicationStatus.pending &&
        job.effectiveStatus == JobPostStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  app.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: switch (app.status) {
                      JobApplicationStatus.accepted =>
                        const Color(0xFF10B981),
                      JobApplicationStatus.rejected =>
                        const Color(0xFFEF4444),
                      _ => const Color(0xFF6366F1),
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          VolunteerCareProfileCard(application: app),
          if (app.availabilityConfirmed) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event_available_rounded,
                    size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                const Text(
                  'Confirmed available for preferred time',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
          if (app.message != null && app.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              'Why they are suitable',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                app.message!,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
          if (canAct) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      JobPostService.instance.rejectApplication(app.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Declined ${app.volunteerName}'),
                        ),
                      );
                    },
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      JobPostService.instance.acceptApplication(app.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Accepted ${app.volunteerName} — they can start the job'),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B74E4),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

}
