import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/family_models.dart';
import '../../models/job_post_model.dart';
import '../../services/family_service.dart';
import '../../services/job_post_service.dart';
import '../../services/notification_service.dart';
import 'create_job_post_page.dart';
import 'family_job_post_detail_page.dart';
import 'widgets/family_job_notifications_panel.dart';

/// Lists family's premium 48-hour job posts with status and time remaining.
class FamilyJobPostsPage extends StatefulWidget {
  const FamilyJobPostsPage({super.key});

  @override
  State<FamilyJobPostsPage> createState() => _FamilyJobPostsPageState();
}

class _FamilyJobPostsPageState extends State<FamilyJobPostsPage> {
  static const _bg = Color(0xFFF5F7FB);
  LinkedUser? _linkedUser;

  @override
  void initState() {
    super.initState();
    JobPostService.instance.addListener(_refresh);
    JobPostService.instance.loadFromRemote();
    NotificationService.instance.loadPersisted();
    _loadLinked();
  }

  Future<void> _loadLinked() async {
    try {
      final u = await FamilyService().fetchLinkedUser();
      if (mounted) setState(() => _linkedUser = u);
    } catch (_) {}
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
    final userId =
        Supabase.instance.client.auth.currentUser?.id ?? 'family_local';
    final posts = JobPostService.instance.postsForFamily(userId);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('My job posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                    builder: (_) => CreateJobPostPage(linkedUser: _linkedUser)),
              );
              if (created == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Job posted — volunteers notified. Active for 48 hours.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const FamilyJobNotificationsPanel(),
          Expanded(
            child: posts.isEmpty
                ? _emptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: posts.length,
                    itemBuilder: (_, i) => _card(posts[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _card(JobPostModel job) {
    final status = job.effectiveStatus;
    final (color, label) = switch (status) {
      JobPostStatus.active => (const Color(0xFF10B981), 'Active'),
      JobPostStatus.accepted => (const Color(0xFF1B74E4), 'Accepted'),
      JobPostStatus.inProgress => (const Color(0xFFF59E0B), 'In progress'),
      JobPostStatus.completed => (const Color(0xFF6B7280), 'Completed'),
      JobPostStatus.confirmed => (const Color(0xFF059669), 'Confirmed'),
      JobPostStatus.expired => (const Color(0xFF9CA3AF), 'Expired'),
    };

    final pendingApps =
        JobPostService.instance.pendingApplicationCount(job.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => FamilyJobPostDetailPage(job: job),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(job.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(job.careType,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF6B7280))),
          if (job.linkedElderlyName != null) ...[
            const SizedBox(height: 4),
            Text('For ${job.linkedElderlyName}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7C3AED))),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF7C3AED)),
              const SizedBox(width: 4),
              Text(
                status == JobPostStatus.active
                    ? job.remainingLabel
                    : 'Posted ${_formatDate(job.createdAt)}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(job.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12)),
          if (pendingApps > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.people_outline_rounded,
                    size: 14, color: Color(0xFF6366F1)),
                const SizedBox(width: 4),
                Text(
                  '$pendingApps application${pendingApps == 1 ? '' : 's'} to review',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF9CA3AF)),
              ],
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final hasUnreadApps = NotificationService.instance.familyUnreadCount > 0;

    // Find first job with pending applications (e.g. demo data).
    JobPostModel? reviewJob;
    for (final p in JobPostService.instance.allPosts) {
      if (JobPostService.instance.pendingApplicationCount(p.id) > 0) {
        reviewJob = p;
        break;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.work_history_outlined,
                size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            const Text(
              'No job posts yet',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            if (reviewJob != null) ...[
              const SizedBox(height: 8),
              Text(
                hasUnreadApps
                    ? 'You have a volunteer application waiting for review.'
                    : 'Tap a notification above or review applicants below.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => FamilyJobPostDetailPage(job: reviewJob!),
                  ),
                ),
                icon: const Icon(Icons.people_rounded),
                label: Text('Review applicants · ${reviewJob.title}'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B74E4),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Post a 48-hour care job with + to reach verified volunteers.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}
