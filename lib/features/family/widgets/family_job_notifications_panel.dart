import 'package:flutter/material.dart';

import '../../../services/job_post_service.dart';
import '../../../services/notification_service.dart';
import '../family_job_post_detail_page.dart';

/// Family inbox for new volunteer applications — tappable to review applicants.
class FamilyJobNotificationsPanel extends StatelessWidget {
  const FamilyJobNotificationsPanel({super.key});

  void _openApplicationReview(BuildContext context, AppNotification note) {
    NotificationService.instance.markRead(
      note.id,
      audience: NotificationAudience.family,
    );

    final job = JobPostService.instance.postById(note.relatedId);
    if (job == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job post not found. Pull to refresh or check My job posts.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FamilyJobPostDetailPage(job: job),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        NotificationService.instance,
        JobPostService.instance,
      ]),
      builder: (context, _) {
        final notes = NotificationService.instance.familyApplicationNotifications
            .where((n) => !n.read)
            .take(5)
            .toList();

        if (notes.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1B74E4).withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded,
                        color: Color(0xFF1B74E4), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${NotificationService.instance.familyUnreadCount} application update${NotificationService.instance.familyUnreadCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF1B74E4),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed:
                          NotificationService.instance.markAllFamilyJobRead,
                      child: const Text('Mark all read',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
              ...notes.map((n) => _NotificationTile(
                    note: n,
                    onReview: () => _openApplicationReview(context, n),
                  )),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.note,
    required this.onReview,
  });

  final AppNotification note;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final job = JobPostService.instance.postById(note.relatedId);
    final pending = job != null
        ? JobPostService.instance.pendingApplicationCount(job.id)
        : 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onReview,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.body,
                      style: const TextStyle(fontSize: 12, height: 1.35),
                    ),
                    if (pending > 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        '$pending pending — tap to review care profile',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B74E4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: onReview,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B74E4).withValues(alpha: 0.12),
                  foregroundColor: const Color(0xFF1B74E4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text(
                  'Review',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
