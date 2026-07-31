import 'package:flutter/material.dart';

import '../data/volunteer_models.dart';
import '../data/volunteer_store.dart';
import 'volunteer_theme.dart';

class VolunteerTaskCard extends StatelessWidget {
  const VolunteerTaskCard({
    super.key,
    required this.task,
    this.compact = false,
  });

  final VolunteerTask task;
  final bool compact;

  bool get _isPremiumJobPost => task.id.startsWith('jobpost_');

  @override
  Widget build(BuildContext context) {
    final urgencyColor = VolunteerTheme.colorForUrgency(task.urgency);
    final isSos = task.urgency == VolunteerUrgency.sos;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: VolunteerTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSos ? VolunteerTheme.danger.withValues(alpha: 0.4) : VolunteerTheme.border,
          width: isSos ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSos
                ? VolunteerTheme.danger.withValues(alpha: 0.18)
                : const Color(0x140F2540),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            urgencyColor.withValues(alpha: 0.18),
                            urgencyColor.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        VolunteerTheme.iconForKind(task.kind),
                        color: urgencyColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isPremiumJobPost)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PREMIUM · 48H JOB',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF7C3AED),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: VolunteerTheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${task.requesterName} · ${VolunteerTheme.labelForKind(task.kind)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: VolunteerTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: urgencyColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        VolunteerTheme.labelForUrgency(task.urgency),
                        style: TextStyle(
                          color: urgencyColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _meta(Icons.location_on_rounded, '${task.distanceKm.toStringAsFixed(1)} km'),
                    const SizedBox(width: 12),
                    _meta(Icons.schedule_rounded, task.timeWindowLabel),
                    const SizedBox(width: 12),
                    _meta(Icons.timer_outlined, '${task.estimatedMinutes} min'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VolunteerTheme.brandAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded,
                              size: 14, color: VolunteerTheme.brandAccent),
                          const SizedBox(width: 2),
                          Text(
                            '${task.points} pts',
                            style: const TextStyle(
                              color: VolunteerTheme.brandAccent,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!compact) ...[
                  const SizedBox(height: 10),
                  Text(
                    task.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: VolunteerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _actionRow(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: VolunteerTheme.textSecondary),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            color: VolunteerTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _actionRow(BuildContext context) {
    switch (task.status) {
      case VolunteerTaskStatus.open:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  VolunteerStore.instance.declineTask(task.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Declined')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: VolunteerTheme.textSecondary,
                  side: const BorderSide(color: VolunteerTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Decline'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  VolunteerStore.instance.acceptTask(task.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Accepted: ${task.title}')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VolunteerTheme.brandAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Accept task',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        );
      case VolunteerTaskStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => VolunteerStore.instance.startTask(task.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: VolunteerTheme.brandPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start now',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        );
      case VolunteerTaskStatus.inProgress:
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  VolunteerStore.instance.completeTask(task.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Marked completed (+${task.points} pts)')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: VolunteerTheme.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Mark complete',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        );
      case VolunteerTaskStatus.completed:
      case VolunteerTaskStatus.cancelled:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: VolunteerTheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            task.status == VolunteerTaskStatus.completed
                ? 'Completed · thank you!'
                : 'Cancelled',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: VolunteerTheme.textSecondary,
            ),
          ),
        );
    }
  }

  void _openDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TaskDetailsSheet(task: task),
    );
  }
}

class _TaskDetailsSheet extends StatelessWidget {
  const _TaskDetailsSheet({required this.task});

  final VolunteerTask task;

  @override
  Widget build(BuildContext context) {
    final urgency = VolunteerTheme.colorForUrgency(task.urgency);
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: VolunteerTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VolunteerTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [urgency.withValues(alpha: 0.2), urgency.withValues(alpha: 0.06)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(VolunteerTheme.iconForKind(task.kind),
                        color: urgency, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: VolunteerTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Requested ${VolunteerTheme.shortAgo(task.createdAt)} · ${task.requesterName}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: VolunteerTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _kvRow(Icons.location_on_rounded, 'Address', task.address),
              _kvRow(Icons.schedule_rounded, 'When',
                  '${task.scheduledFor.day}/${task.scheduledFor.month} · ${task.timeWindowLabel}'),
              _kvRow(Icons.directions_walk_rounded, 'Distance',
                  '${task.distanceKm.toStringAsFixed(1)} km'),
              _kvRow(Icons.timer_outlined, 'Estimated',
                  '${task.estimatedMinutes} min'),
              _kvRow(Icons.bolt_rounded, 'Reward', '${task.points} points'),
              if (task.notes != null && task.notes!.isNotEmpty)
                _kvRow(Icons.sticky_note_2_rounded, 'Notes', task.notes!),
              const SizedBox(height: 20),
              VolunteerTaskCard(task: task, compact: false),
            ],
          ),
        );
      },
    );
  }

  Widget _kvRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: VolunteerTheme.brandAccent),
          const SizedBox(width: 10),
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: VolunteerTheme.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                color: VolunteerTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
