import 'package:flutter/material.dart';

import '../../../services/job_post_service.dart';
import '../../../services/notification_service.dart';
import '../widgets/volunteer_theme.dart';

/// Volunteer inbox for new premium job post alerts.
class JobNotificationsPanel extends StatelessWidget {
  const JobNotificationsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        NotificationService.instance,
        JobPostService.instance,
      ]),
      builder: (context, _) {
        final notes = NotificationService.instance.notifications
            .where((n) =>
                n.type == 'job_post' ||
                n.type == 'job_accepted' ||
                n.type == 'job_rejected')
            .take(5)
            .toList();
        final activeJobs = JobPostService.instance.activePostsForVolunteers;

        if (notes.isEmpty && activeJobs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign_rounded,
                      color: Color(0xFF7C3AED), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    activeJobs.isNotEmpty
                        ? '${activeJobs.length} premium job${activeJobs.length == 1 ? '' : 's'} live'
                        : 'Job alerts',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF5B21B6),
                    ),
                  ),
                  const Spacer(),
                  if (NotificationService.instance.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: VolunteerTheme.brandAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${NotificationService.instance.unreadCount} new',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...notes.map((n) => _noteTile(context, n)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _noteTile(BuildContext context, AppNotification n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => NotificationService.instance.markRead(n.id),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                n.read ? Icons.mark_email_read_outlined : Icons.mark_email_unread_rounded,
                size: 18,
                color: n.read ? VolunteerTheme.textSecondary : const Color(0xFF7C3AED),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: n.read
                              ? VolunteerTheme.textSecondary
                              : VolunteerTheme.textPrimary,
                        )),
                    Text(n.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
