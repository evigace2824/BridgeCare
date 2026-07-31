import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/user_model.dart';
import '../../../services/job_post_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/volunteer_premium_service.dart';
import '../../premium/premium_plans_screen.dart';
import '../data/volunteer_models.dart';
import '../data/volunteer_store.dart';
import '../widgets/premium_job_post_card.dart';
import '../widgets/task_card.dart';
import '../widgets/volunteer_job_view_status.dart';
import '../widgets/volunteer_theme.dart';

/// Airbnb-style Requests screen: compact search bar, premium jobs as the hero
/// section, and a single Filters button that opens a sheet.
class VolunteerRequestsTab extends StatefulWidget {
  const VolunteerRequestsTab({super.key});

  @override
  State<VolunteerRequestsTab> createState() => _VolunteerRequestsTabState();
}

enum _Section { jobs, assistance }

enum _AssistanceStatus { open, urgent, mine, completed }

class _VolunteerRequestsTabState extends State<VolunteerRequestsTab> {
  String _query = '';
  _Section _section = _Section.jobs;
  _AssistanceStatus _assistanceStatus = _AssistanceStatus.open;
  String _jobStatus = 'all';
  VolunteerTaskKind? _kind;

  @override
  void initState() {
    super.initState();
    JobPostService.instance.refreshExpirations();
    JobPostService.instance.ensureDemoPostsIfEmpty();
  }

  bool get _hasActiveFilters {
    if (_section == _Section.jobs) {
      return _jobStatus != 'all' || _kind != null;
    }
    return _assistanceStatus != _AssistanceStatus.open || _kind != null;
  }

  int get _activeFilterCount {
    var n = 0;
    if (_section == _Section.jobs && _jobStatus != 'all') n++;
    if (_section == _Section.assistance &&
        _assistanceStatus != _AssistanceStatus.open) n++;
    if (_kind != null) n++;
    return n;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        VolunteerStore.instance,
        JobPostService.instance,
        NotificationService.instance,
      ]),
      builder: (context, _) {
        final store = VolunteerStore.instance;
        final isPremium = store.currentPlan.isPremium;

        // Free volunteers can't access the Jobs section; clamp to assistance.
        if (!isPremium && _section == _Section.jobs) {
          _section = _Section.assistance;
        }

        return Column(
          children: [
            const SizedBox(height: 8),
            _searchHeader(),
            const SizedBox(height: 8),
            if (isPremium) _sectionToggle(),
            if (isPremium) const SizedBox(height: 4),
            Expanded(
              child: _section == _Section.jobs
                  ? _jobsBody(store, isPremium)
                  : _assistanceBody(store, isPremium),
            ),
          ],
        );
      },
    );
  }

  // ───────────────────────────── Header ─────────────────────────────

  Widget _searchHeader() {
    final unread = NotificationService.instance.notifications
        .where((n) =>
            !n.read &&
            (n.type == 'job_post' ||
                n.type == 'job_accepted' ||
                n.type == 'job_rejected'))
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: VolunteerTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isCollapsed: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  hintText: _section == _Section.jobs
                      ? 'Search premium jobs'
                      : 'Search tasks, names, places',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: VolunteerTheme.textSecondary,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: VolunteerTheme.textSecondary, size: 20),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _circleAction(
            icon: Icons.notifications_rounded,
            badge: unread,
            onTap: _openNotifications,
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          _circleAction(
            icon: Icons.tune_rounded,
            badge: _activeFilterCount,
            badgeColor: const Color(0xFF7C3AED),
            onTap: _openFilters,
            tooltip: 'Filters',
          ),
        ],
      ),
    );
  }

  Widget _circleAction({
    required IconData icon,
    required VoidCallback onTap,
    int badge = 0,
    String? tooltip,
    Color badgeColor = const Color(0xFFE53935),
  }) {
    final button = Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: VolunteerTheme.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: VolunteerTheme.textPrimary, size: 20),
              if (badge > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  // ─────────────────────────── Section toggle ───────────────────────────

  Widget _sectionToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF1F6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: _toggleOption(
                label: 'Premium Jobs',
                icon: Icons.work_history_rounded,
                selected: _section == _Section.jobs,
                onTap: () => setState(() => _section = _Section.jobs),
                selectedColor: const Color(0xFF7C3AED),
              ),
            ),
            Expanded(
              child: _toggleOption(
                label: 'Assistance',
                icon: Icons.volunteer_activism_rounded,
                selected: _section == _Section.assistance,
                onTap: () => setState(() => _section = _Section.assistance),
                selectedColor: VolunteerTheme.brandPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required Color selectedColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? selectedColor
                    : VolunteerTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color:
                    selected ? selectedColor : VolunteerTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Jobs body ───────────────────────────

  Widget _jobsBody(VolunteerStore store, bool isPremium) {
    if (!isPremium) return _jobsLocked(context);

    JobPostService.instance.refreshExpirations();
    final volId =
        Supabase.instance.client.auth.currentUser?.id ?? 'volunteer_local';
    var jobs = JobPostService.instance.postsForVolunteer(volId);

    if (_jobStatus != 'all') {
      jobs = jobs.where((j) {
        final label = VolunteerJobStatusHelper.label(
          VolunteerJobStatusHelper.of(j, volId),
        ).toLowerCase();
        return label.contains(_jobStatus);
      }).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      jobs = jobs
          .where((j) =>
              j.title.toLowerCase().contains(q) ||
              j.careType.toLowerCase().contains(q) ||
              j.location.toLowerCase().contains(q))
          .toList();
    }

    return Column(
      children: [
        _contextStrip(
          icon: Icons.verified_rounded,
          color: const Color(0xFF7C3AED),
          text:
              '${jobs.length} premium job${jobs.length == 1 ? '' : 's'} · up to ${store.maxRadiusKm.toStringAsFixed(0)} km · 1.5× points',
        ),
        Expanded(
          child: jobs.isEmpty
              ? _empty(assistanceOnly: false)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: jobs.length,
                  itemBuilder: (_, i) => PremiumJobPostCard(job: jobs[i]),
                ),
        ),
      ],
    );
  }

  // ─────────────────────────── Assistance body ───────────────────────────

  Widget _assistanceBody(VolunteerStore store, bool isPremium) {
    final all = store.tasks;
    Iterable<VolunteerTask> visible = all;
    switch (_assistanceStatus) {
      case _AssistanceStatus.open:
        visible = VolunteerPremiumService.instance.assistanceTasks(
          visible.where((t) => t.status == VolunteerTaskStatus.open),
        );
        break;
      case _AssistanceStatus.mine:
        visible = visible.where((t) =>
            !t.id.startsWith('jobpost_') &&
            (t.status == VolunteerTaskStatus.accepted ||
                t.status == VolunteerTaskStatus.inProgress));
        break;
      case _AssistanceStatus.urgent:
        visible = VolunteerPremiumService.instance.assistanceTasks(
          visible.where((t) =>
              t.status == VolunteerTaskStatus.open &&
              (t.urgency == VolunteerUrgency.high ||
                  t.urgency == VolunteerUrgency.sos)),
        );
        break;
      case _AssistanceStatus.completed:
        visible = visible.where((t) =>
            !t.id.startsWith('jobpost_') &&
            t.status == VolunteerTaskStatus.completed);
        break;
    }
    if (_kind != null) visible = visible.where((t) => t.kind == _kind);
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      visible = visible.where((t) =>
          t.title.toLowerCase().contains(q) ||
          t.requesterName.toLowerCase().contains(q) ||
          t.address.toLowerCase().contains(q));
    }
    final list = visible.toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    return Column(
      children: [
        _contextStrip(
          icon: Icons.volunteer_activism_rounded,
          color: VolunteerTheme.brandAccent,
          text:
              '${list.length} request${list.length == 1 ? '' : 's'} · ${_assistanceStatusLabel(_assistanceStatus)}${_kind != null ? ' · ${VolunteerTheme.labelForKind(_kind!)}' : ''}${isPremium ? ' · 1.5× points' : ''}',
        ),
        Expanded(
          child: list.isEmpty
              ? _empty(assistanceOnly: true)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) => VolunteerTaskCard(task: list[i]),
                ),
        ),
      ],
    );
  }

  Widget _contextStrip({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: 0.9)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: VolunteerTheme.textSecondary,
              ),
            ),
          ),
          if (_hasActiveFilters)
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.close_rounded, size: 14),
              label: const Text('Clear', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: VolunteerTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────── Sheets ───────────────────────────

  void _openNotifications() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return _FiltersSheet(
          isJobs: _section == _Section.jobs,
          assistanceStatus: _assistanceStatus,
          jobStatus: _jobStatus,
          kind: _kind,
          onApply: ({
            required _AssistanceStatus assistanceStatus,
            required String jobStatus,
            required VolunteerTaskKind? kind,
          }) {
            setState(() {
              _assistanceStatus = assistanceStatus;
              _jobStatus = jobStatus;
              _kind = kind;
            });
          },
          onReset: _resetFilters,
        );
      },
    );
  }

  void _resetFilters() {
    setState(() {
      _assistanceStatus = _AssistanceStatus.open;
      _jobStatus = 'all';
      _kind = null;
    });
  }

  // ─────────────────────────── Locked / Empty ───────────────────────────

  Widget _jobsLocked(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.work_history_rounded,
                  size: 40, color: Color(0xFF7C3AED)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Premium jobs unlock with Verified Premium',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: VolunteerTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'See 48-hour family job posts, wider radius (25 km), '
              'priority alerts, skill matching and 1.5× points.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: VolunteerTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      const PremiumPlansScreen(role: UserRole.volunteer),
                ),
              ),
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Upgrade to Premium'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty({required bool assistanceOnly}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              assistanceOnly ? Icons.search_off_rounded : Icons.work_off_outlined,
              size: 48,
              color: VolunteerTheme.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              assistanceOnly
                  ? 'No requests match your filters'
                  : 'No premium jobs match your filters',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: VolunteerTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              assistanceOnly
                  ? 'Try a different status, category, or clear filters.'
                  : 'Try another status or check back when families post jobs.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: VolunteerTheme.textSecondary),
            ),
            if (_hasActiveFilters) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _assistanceStatusLabel(_AssistanceStatus s) => switch (s) {
        _AssistanceStatus.open => 'Open',
        _AssistanceStatus.urgent => 'Urgent',
        _AssistanceStatus.mine => 'In progress',
        _AssistanceStatus.completed => 'Done',
      };
}

// ─────────────────────────── Notifications sheet ───────────────────────────

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            NotificationService.instance,
            JobPostService.instance,
          ]),
          builder: (_, __) {
            final notes = NotificationService.instance.notifications
                .where((n) =>
                    n.type == 'job_post' ||
                    n.type == 'job_accepted' ||
                    n.type == 'job_rejected')
                .toList();
            final activeJobs =
                JobPostService.instance.activePostsForVolunteers.length;

            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Notifications',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      if (NotificationService.instance.unreadCount > 0)
                        TextButton(
                          onPressed:
                              NotificationService.instance.markAllJobPostsRead,
                          child: const Text('Mark all read'),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
                if (activeJobs > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.campaign_rounded,
                              color: Color(0xFF7C3AED), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$activeJobs premium job${activeJobs == 1 ? '' : 's'} live now',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5B21B6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: notes.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'No notifications yet.\nYou\'ll see job alerts here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: VolunteerTheme.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scroll,
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 20),
                          itemCount: notes.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, indent: 56),
                          itemBuilder: (_, i) {
                            final n = notes[i];
                            return ListTile(
                              onTap: () =>
                                  NotificationService.instance.markRead(n.id),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: n.read
                                    ? const Color(0xFFE5E7EB)
                                    : const Color(0xFFEDE9FE),
                                child: Icon(
                                  n.read
                                      ? Icons.mark_email_read_outlined
                                      : Icons.mark_email_unread_rounded,
                                  color: n.read
                                      ? VolunteerTheme.textSecondary
                                      : const Color(0xFF7C3AED),
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                n.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: n.read
                                      ? VolunteerTheme.textSecondary
                                      : VolunteerTheme.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                n.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────── Filters sheet ───────────────────────────

typedef _FiltersApply = void Function({
  required _AssistanceStatus assistanceStatus,
  required String jobStatus,
  required VolunteerTaskKind? kind,
});

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({
    required this.isJobs,
    required this.assistanceStatus,
    required this.jobStatus,
    required this.kind,
    required this.onApply,
    required this.onReset,
  });

  final bool isJobs;
  final _AssistanceStatus assistanceStatus;
  final String jobStatus;
  final VolunteerTaskKind? kind;
  final _FiltersApply onApply;
  final VoidCallback onReset;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late _AssistanceStatus _assistanceStatus = widget.assistanceStatus;
  late String _jobStatus = widget.jobStatus;
  late VolunteerTaskKind? _kind = widget.kind;

  static const List<({String id, String label})> _jobStatusOptions = [
    (id: 'all', label: 'All'),
    (id: 'active', label: 'Active'),
    (id: 'application sent', label: 'Applied'),
    (id: 'accepted by family', label: 'Accepted'),
    (id: 'in progress', label: 'In progress'),
    (id: 'completed', label: 'Done'),
    (id: 'confirmed', label: 'Confirmed'),
    (id: 'not selected', label: 'Declined'),
    (id: 'expired', label: 'Expired'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filters',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _sectionTitle('Status'),
                  const SizedBox(height: 8),
                  if (widget.isJobs)
                    _wrapChips(
                      options: _jobStatusOptions
                          .map((o) => (id: o.id, label: o.label))
                          .toList(),
                      isSelected: (id) => _jobStatus == id,
                      onSelect: (id) => setState(() => _jobStatus = id),
                      selectedColor: const Color(0xFF7C3AED),
                    )
                  else
                    _wrapChips(
                      options: const [
                        (id: 'open', label: 'Open'),
                        (id: 'urgent', label: 'Urgent'),
                        (id: 'mine', label: 'In progress'),
                        (id: 'completed', label: 'Done'),
                      ],
                      isSelected: (id) => _assistanceStatus.name == id,
                      onSelect: (id) => setState(() {
                        _assistanceStatus = _AssistanceStatus.values
                            .firstWhere((e) => e.name == id);
                      }),
                      selectedColor: VolunteerTheme.brandPrimary,
                    ),
                  const SizedBox(height: 18),
                  _sectionTitle('Category'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _kind == null,
                        onSelected: (_) => setState(() => _kind = null),
                        avatar: const Icon(
                          Icons.all_inclusive_rounded,
                          size: 16,
                          color: VolunteerTheme.brandAccent,
                        ),
                        selectedColor: VolunteerTheme.brandAccent
                            .withValues(alpha: 0.18),
                      ),
                      for (final k in VolunteerTaskKind.values)
                        FilterChip(
                          label: Text(VolunteerTheme.labelForKind(k)),
                          selected: _kind == k,
                          onSelected: (_) => setState(() => _kind = k),
                          avatar: Icon(
                            VolunteerTheme.iconForKind(k),
                            size: 16,
                            color: VolunteerTheme.brandAccent,
                          ),
                          selectedColor: VolunteerTheme.brandAccent
                              .withValues(alpha: 0.18),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          widget.onReset();
                          Navigator.of(context).maybePop();
                        },
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () {
                          widget.onApply(
                            assistanceStatus: _assistanceStatus,
                            jobStatus: _jobStatus,
                            kind: _kind,
                          );
                          Navigator.of(context).maybePop();
                        },
                        style: FilledButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: widget.isJobs
                              ? const Color(0xFF7C3AED)
                              : VolunteerTheme.brandPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Show results',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: VolunteerTheme.textPrimary,
        ),
      );

  Widget _wrapChips({
    required List<({String id, String label})> options,
    required bool Function(String id) isSelected,
    required void Function(String id) onSelect,
    required Color selectedColor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final selected = isSelected(o.id);
        return ChoiceChip(
          label: Text(o.label),
          selected: selected,
          onSelected: (_) => onSelect(o.id),
          selectedColor: selectedColor.withValues(alpha: 0.18),
          labelStyle: TextStyle(
            color: selected ? selectedColor : VolunteerTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? selectedColor : VolunteerTheme.border,
            ),
          ),
        );
      }).toList(),
    );
  }
}
