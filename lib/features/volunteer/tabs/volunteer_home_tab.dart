import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../services/job_post_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/premium_status_card.dart';
import '../../premium/premium_plans_screen.dart';
import '../data/volunteer_store.dart';
import '../widgets/task_card.dart';
import '../widgets/volunteer_theme.dart';

class VolunteerHomeTab extends StatelessWidget {
  const VolunteerHomeTab({
    super.key,
    required this.onSeeAllRequests,
    required this.onOpenMap,
    this.onVolunteerTab,
  });

  final VoidCallback onSeeAllRequests;
  final VoidCallback onOpenMap;
  final void Function(int tabIndex)? onVolunteerTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VolunteerStore.instance,
      builder: (context, _) {
        final s = VolunteerStore.instance;
        final urgent = s.urgentAssistanceNearby;
        final today = s.openAssistanceNearby.take(3).toList();
        final mine = s.myTasks;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _heroCard(context, s),
            const SizedBox(height: 12),
            if (s.currentPlan.isPremium) ...[
              PremiumStatusCard(
                role: UserRole.volunteer,
                summary: '25 km · Jobs · 1.5× points',
                onVolunteerTab: onVolunteerTab,
              ),
              const SizedBox(height: 10),
            ] else ...[
              _premiumSpotlight(context),
              const SizedBox(height: 12),
            ],
            _liveJobsLink(context, s),
            const SizedBox(height: 12),
            _quickStatsRow(s),
            const SizedBox(height: 22),
            if (urgent.isNotEmpty) ...[
              _sectionHeader('Needs you now', VolunteerTheme.danger,
                  trailing: TextButton(
                    onPressed: onSeeAllRequests,
                    child: const Text('See all'),
                  )),
              const SizedBox(height: 6),
              for (final t in urgent.take(2)) VolunteerTaskCard(task: t),
              const SizedBox(height: 14),
            ],
            _sectionHeader('Quick actions', VolunteerTheme.brandPrimary),
            const SizedBox(height: 8),
            _quickActions(context),
            const SizedBox(height: 22),
            if (mine.isNotEmpty) ...[
              _sectionHeader('In progress', VolunteerTheme.brandAccent),
              const SizedBox(height: 6),
              for (final t in mine.take(3)) VolunteerTaskCard(task: t),
              const SizedBox(height: 14),
            ],
            _sectionHeader('Open near you', VolunteerTheme.brandPrimary,
                trailing: TextButton(
                  onPressed: onOpenMap,
                  child: const Text('View map'),
                )),
            const SizedBox(height: 6),
            for (final t in today) VolunteerTaskCard(task: t),
          ],
        );
      },
    );
  }

  Widget _heroCard(BuildContext context, VolunteerStore s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: VolunteerTheme.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33133A63),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0x3324B6A8),
                child: Icon(Icons.volunteer_activism_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Hello, ${s.volunteerName} 👋',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (s.currentPlan.isPaid) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  s.currentPlan.shortName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.5,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Level ${s.stats.level} · ${s.stats.levelTitle}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: s.isAvailableNow
                      ? VolunteerTheme.brandAccent
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      s.isAvailableNow
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s.isAvailableNow ? 'Available' : 'Off duty',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: s.stats.progressToNextLevel,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(VolunteerTheme.brandAccent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${s.stats.points} / ${s.stats.nextLevelPoints} pts to next level',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _heroPill(
                  Icons.task_alt_rounded,
                  '${s.openAssistanceNearby.length} open',
                  'requests',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _heroPill(
                  Icons.local_fire_department_rounded,
                  '${s.stats.streakDays}-day',
                  'streak',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _heroPill(
                  Icons.favorite_rounded,
                  '${s.stats.peopleHelped}',
                  'helped',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Eye-catching upsell banner shown to free volunteers.
  Widget _premiumSpotlight(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PremiumPlansScreen(role: UserRole.volunteer),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF5B21B6),
              Color(0xFF7C4DFF),
              Color(0xFFA855F7),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.50),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Volunteer Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Priority queue · 1.5× points · 25 km · expense tracker',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11.8,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'From \$9.99',
                    style: TextStyle(
                      color: Color(0xFF5B21B6),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF5B21B6),
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveJobsLink(BuildContext context, VolunteerStore s) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        JobPostService.instance,
        NotificationService.instance,
      ]),
      builder: (_, __) {
        final active =
            JobPostService.instance.activePostsForVolunteers.length;
        final unread = NotificationService.instance.notifications
            .where((n) =>
                !n.read &&
                (n.type == 'job_post' ||
                    n.type == 'job_accepted' ||
                    n.type == 'job_rejected'))
            .length;

        if (active == 0 && unread == 0) return const SizedBox.shrink();

        final isPremium = s.currentPlan.isPremium;
        final color = isPremium
            ? const Color(0xFF7C3AED)
            : VolunteerTheme.brandPrimary;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSeeAllRequests,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: VolunteerTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.campaign_rounded,
                        color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active > 0
                              ? '$active premium job${active == 1 ? '' : 's'} live'
                              : 'New job updates',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: VolunteerTheme.textPrimary,
                          ),
                        ),
                        Text(
                          unread > 0
                              ? '$unread unread alert${unread == 1 ? '' : 's'} · tap to review'
                              : 'See open jobs in your area',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: VolunteerTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: color),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _heroPill(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickStatsRow(VolunteerStore s) {
    return Row(
      children: [
        _kpiCard(Icons.task_alt_rounded, '${s.stats.tasksCompleted}', 'Tasks done',
            VolunteerTheme.brandAccent),
        const SizedBox(width: 8),
        _kpiCard(Icons.access_time_filled_rounded, '${s.stats.hoursVolunteered}h',
            'Volunteered', VolunteerTheme.brandPrimary),
        const SizedBox(width: 8),
        _kpiCard(Icons.bolt_rounded, '${s.stats.points}', 'Points',
            const Color(0xFFFB8C00)),
      ],
    );
  }

  Widget _kpiCard(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: VolunteerTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VolunteerTheme.border),
          boxShadow: const [
            BoxShadow(color: Color(0x0F0F2540), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: VolunteerTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: VolunteerTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color accent, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: VolunteerTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _quickActions(BuildContext context) {
    final actions = [
      _ActionItem(Icons.search_rounded, 'Find tasks',
          VolunteerTheme.brandPrimary, onSeeAllRequests),
      _ActionItem(Icons.map_rounded, 'Map view', VolunteerTheme.brandAccent,
          onOpenMap),
      _ActionItem(Icons.bolt_rounded, 'Boost mode', const Color(0xFFFB8C00),
          () => _showBoostMode(context)),
      _ActionItem(Icons.school_rounded, 'Training', const Color(0xFF7C4DFF),
          () => _showTraining(context)),
      _ActionItem(Icons.workspace_premium_rounded, 'Badges',
          const Color(0xFFEC407A), () => _showBadgesInfo(context)),
      _ActionItem(Icons.settings_rounded, 'Preferences',
          VolunteerTheme.textSecondary, () => _showPreferences(context)),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final a in actions) _quickActionTile(context, a),
      ],
    );
  }

  Widget _quickActionTile(BuildContext context, _ActionItem a) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 32 - 16) / 3,
      child: Material(
        color: VolunteerTheme.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: a.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VolunteerTheme.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: a.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(a.icon, color: a.color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  a.label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: VolunteerTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBoostMode(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: VolunteerTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFB8C00).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.bolt_rounded,
                  color: Color(0xFFFB8C00), size: 30),
            ),
            const SizedBox(height: 12),
            const Text(
              'Boost mode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: VolunteerTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Earn 2× points for the next 60 minutes by accepting any open task in your area.',
              textAlign: TextAlign.center,
              style: TextStyle(color: VolunteerTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFFFB8C00),
                      content: Text('Boost mode activated for 60 minutes! 2× points enabled.'),
                    ),
                  );
                  onSeeAllRequests();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFB8C00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.flash_on_rounded),
                label: const Text('Start boost',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTraining(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: Color(0xFF7C4DFF)),
            SizedBox(width: 8),
            Text('Volunteer training'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TrainingItem('First aid basics', '15 min · video'),
            _TrainingItem('Communicating with elderly', '10 min · video'),
            _TrainingItem('Medication safety', '8 min · article'),
            _TrainingItem('Emergency response', '12 min · video'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBadgesInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Open the Impact tab to see all badges and progress.'),
      ),
    );
  }

  void _showPreferences(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Open the Profile tab to customize preferences.'),
      ),
    );
  }
}

class _ActionItem {
  const _ActionItem(this.icon, this.label, this.color, this.onTap);
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _TrainingItem extends StatelessWidget {
  const _TrainingItem(this.title, this.subtitle);
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.play_circle_fill_rounded,
                color: Color(0xFF7C4DFF), size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: VolunteerTheme.textPrimary,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: VolunteerTheme.textSecondary,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
