import 'package:flutter/material.dart';

import '../data/volunteer_models.dart';
import '../data/volunteer_store.dart';
import '../../../models/user_model.dart';
import '../../premium/premium_plans_screen.dart';
import '../widgets/volunteer_theme.dart';

class VolunteerImpactTab extends StatelessWidget {
  const VolunteerImpactTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VolunteerStore.instance,
      builder: (context, _) {
        final s = VolunteerStore.instance;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _impactHero(s.stats),
            const SizedBox(height: 18),
            _weeklyChart(),
            const SizedBox(height: 22),
            if (!s.currentPlan.isPremium) ...[
              _premiumAnalyticsCard(context),
              const SizedBox(height: 22),
            ] else ...[
              _premiumActiveCard(context, s),
              const SizedBox(height: 22),
            ],
            const _SectionHeader(title: 'Badges', accent: Color(0xFF7C4DFF)),
            const SizedBox(height: 8),
            _badgeGrid(s.badges),
            const SizedBox(height: 22),
            const _SectionHeader(title: 'Leaderboard', accent: VolunteerTheme.brandPrimary),
            const SizedBox(height: 8),
            for (final entry in s.leaderboard) _leaderboardRow(entry, s.currentPlan),
          ],
        );
      },
    );
  }

  Widget _impactHero(VolunteerImpactStats st) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: VolunteerTheme.heroGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${st.level} · ${st.levelTitle}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${st.points} / ${st.nextLevelPoints} pts',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: st.progressToNextLevel,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(VolunteerTheme.brandAccent),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _heroStat(Icons.favorite_rounded, '${st.peopleHelped}', 'People helped')),
              const SizedBox(width: 8),
              Expanded(child: _heroStat(Icons.task_alt_rounded, '${st.tasksCompleted}', 'Tasks done')),
              const SizedBox(width: 8),
              Expanded(child: _heroStat(Icons.access_time_filled_rounded, '${st.hoursVolunteered}h', 'Hours')),
              const SizedBox(width: 8),
              Expanded(child: _heroStat(Icons.local_fire_department_rounded, '${st.streakDays}', 'Streak')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              )),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _weeklyChart() {
    const data = [3, 5, 2, 6, 4, 7, 5];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VolunteerTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VolunteerTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This week',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: VolunteerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < data.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('${data[i]}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: VolunteerTheme.textSecondary,
                              )),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            height: (data[i] / maxVal) * 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  VolunteerTheme.brandAccent,
                                  VolunteerTheme.brandAccent.withValues(alpha: 0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(days[i],
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: VolunteerTheme.textSecondary,
                                fontWeight: FontWeight.w700,
                              )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeGrid(List<VolunteerBadge> badges) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: badges.length,
      itemBuilder: (_, i) => _badgeTile(badges[i]),
    );
  }

  Widget _badgeTile(VolunteerBadge b) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VolunteerTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: b.unlocked ? b.color.withValues(alpha: 0.4) : VolunteerTheme.border,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: b.unlocked
                      ? b.color.withValues(alpha: 0.15)
                      : VolunteerTheme.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(b.icon,
                    color: b.unlocked ? b.color : VolunteerTheme.textSecondary,
                    size: 24),
              ),
              if (!b.unlocked)
                const Positioned(
                  right: 2,
                  bottom: 2,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.lock_rounded,
                        size: 10, color: VolunteerTheme.textSecondary),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: VolunteerTheme.textPrimary,
                  ),
                ),
                Text(
                  b.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: VolunteerTheme.textSecondary,
                  ),
                ),
                if (!b.unlocked && b.target > 1) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (b.progress / b.target).clamp(0, 1),
                      minHeight: 5,
                      backgroundColor: VolunteerTheme.background,
                      valueColor: AlwaysStoppedAnimation<Color>(b.color),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaderboardRow(VolunteerLeaderboardEntry e, VolunteerPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: e.isMe ? VolunteerTheme.brandAccent.withValues(alpha: 0.08) : VolunteerTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: e.isMe ? VolunteerTheme.brandAccent : VolunteerTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: e.rank <= 3
                  ? const LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFFB300)])
                  : null,
              color: e.rank <= 3 ? null : VolunteerTheme.background,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${e.rank}',
                style: TextStyle(
                  color: e.rank <= 3 ? Colors.white : VolunteerTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: e.color.withValues(alpha: 0.18),
            child: Text(
              e.name.substring(0, 1),
              style: TextStyle(
                color: e.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        e.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: VolunteerTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (e.isMe && plan.isPaid) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: plan == VolunteerPlan.pro
                                ? const [Color(0xFF5B21B6), Color(0xFFA855F7)]
                                : const [Color(0xFF1A6BD8), Color(0xFF24B6A8)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          plan.shortName.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '${e.tasksCompleted} tasks',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: VolunteerTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
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
                  '${e.points}',
                  style: const TextStyle(
                    color: VolunteerTheme.brandAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Premium upsell / status cards ─────────────────────────────────────

  Widget _premiumAnalyticsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const PremiumPlansScreen(role: UserRole.volunteer),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VolunteerTheme.border),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B21B6), Color(0xFFA855F7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.insights_rounded,
                      color: Colors.white),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Premium analytics',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: VolunteerTheme.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Unlock weekly impact PDFs, monthly mileage exports, year-end donation receipts, and 1.5× points for faster level-ups.',
              style: TextStyle(
                color: VolunteerTheme.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniPerk(Icons.bar_chart_rounded, 'PDF reports'),
                const SizedBox(width: 6),
                _miniPerk(Icons.receipt_long_rounded, 'Expense log'),
                const SizedBox(width: 6),
                _miniPerk(Icons.card_giftcard_rounded, 'Tax receipt'),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PremiumPlansScreen(role: UserRole.volunteer),
                  ),
                ),
                icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                label: const Text(
                  'See Premium plans',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniPerk(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF7C4DFF).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF7C4DFF), size: 17),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF7C4DFF),
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _premiumActiveCard(BuildContext context, VolunteerStore s) {
    final plan = s.currentPlan;
    final gradient = plan == VolunteerPlan.pro
        ? const [Color(0xFF5B21B6), Color(0xFFA855F7)]
        : const [Color(0xFF1A6BD8), Color(0xFF24B6A8)];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.insights_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.name} analytics active',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${plan.pointsMultiplier.toStringAsFixed(plan.pointsMultiplier % 1 == 0 ? 0 : 2)}× points · ${plan.maxRadiusCapKm.toInt()} km radius',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PremiumPlansScreen(role: UserRole.volunteer),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            tooltip: 'Manage plan',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.accent});

  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: VolunteerTheme.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
