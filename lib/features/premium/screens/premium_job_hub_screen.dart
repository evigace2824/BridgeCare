import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/family_models.dart';
import '../../../models/job_post_model.dart';
import '../../../services/family_service.dart';
import '../../../services/job_post_service.dart';
import '../../../models/user_model.dart';
import '../../family/create_job_post_page.dart';
import '../../family/family_job_posts_page.dart';
import '../../family/family_plan_store.dart';
import '../premium_gate.dart';

/// Premium hub for 48-hour family job posts.
class PremiumJobHubScreen extends StatefulWidget {
  const PremiumJobHubScreen({super.key});

  @override
  State<PremiumJobHubScreen> createState() => _PremiumJobHubScreenState();
}

class _PremiumJobHubScreenState extends State<PremiumJobHubScreen> {
  static const _purple = Color(0xFF7C3AED);
  LinkedUser? _linkedUser;

  @override
  void initState() {
    super.initState();
    JobPostService.instance.addListener(_refresh);
    JobPostService.instance.refreshExpirations();
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
    return ListenableBuilder(
      listenable: FamilyPlanStore.instance,
      builder: (context, _) {
        if (!FamilyPlanStore.instance.plan.familyJobPostingUnlocked) {
          return _lockedHub(context);
        }
        return _hubBody(context);
      },
    );
  }

  Widget _lockedHub(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(title: const Text('48h Job posts')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 56, color: _purple),
              const SizedBox(height: 16),
              const Text(
                'Premium family feature',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Post care-related jobs for your linked loved one. Verified volunteers apply; '
                'you choose who to accept. Each post stays active for 48 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => PremiumGate.openPlans(context, UserRole.family),
                style: FilledButton.styleFrom(backgroundColor: _purple),
                child: const Text('Upgrade to Premium'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hubBody(BuildContext context) {
    final userId =
        Supabase.instance.client.auth.currentUser?.id ?? 'family_local';
    final posts = JobPostService.instance.postsForFamily(userId);
    final active = posts.where((p) => p.effectiveStatus == JobPostStatus.active).length;

    final subtitle = active > 0
        ? '$active active post${active == 1 ? '' : 's'} — volunteers can apply now'
        : 'Post care help jobs for verified volunteers (48 hours each)';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hubHeader(context, subtitle),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _actionTile(
                  context,
                  icon: Icons.add_circle_rounded,
                  title: 'Create new job post',
                  subtitle: 'Notify nearby volunteers instantly',
                  color: _purple,
                  onTap: () async {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => CreateJobPostPage(
                            linkedUser: _linkedUser,
                          )),
                    );
                    if (ok == true && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Job live for 48 hours — volunteers notified'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                _actionTile(
                  context,
                  icon: Icons.list_alt_rounded,
                  title: 'Manage my posts',
                  subtitle: 'Active, accepted, completed & expired',
                  color: const Color(0xFF1B74E4),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FamilyJobPostsPage()),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('How it works',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 10),
                _step(1, 'Post title, care type, location & urgency'),
                _step(2, 'Volunteers apply with their Care Profile — you review applicants'),
                _step(3, 'Accept one volunteer; they start, complete, then you confirm'),
                _step(4, 'Unfilled posts expire after 48 hours automatically'),
                if (posts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('Recent posts',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 8),
                  ...posts.take(3).map(_postPreview),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hubHeader(BuildContext context, String subtitle) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '48h Job posts',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280))),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(int n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: _purple,
            child: Text('$n',
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _postPreview(JobPostModel p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(p.remainingLabel,
                    style: const TextStyle(
                        fontSize: 11, color: _purple, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}
