import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/volunteer_store.dart';
import '../../../models/user_model.dart';
import '../../premium/premium_plans_screen.dart';
import '../widgets/volunteer_theme.dart';

class VolunteerProfileTab extends StatelessWidget {
  const VolunteerProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VolunteerStore.instance,
      builder: (context, _) {
        final s = VolunteerStore.instance;
        final auth = Supabase.instance.client.auth.currentUser;
        final email = auth?.email ?? '';
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
          children: [
            _profileHeader(s.volunteerName, s.volunteerCity, email, s.currentPlan),
            const SizedBox(height: 14),
            _planSection(context, s),
            const SizedBox(height: 18),
            _availabilitySection(context, s),
            const SizedBox(height: 18),
            _radiusSection(context, s),
            const SizedBox(height: 18),
            _skillsSection(s),
            const SizedBox(height: 18),
            _preferencesSection(s),
            const SizedBox(height: 18),
            _supportSection(context),
          ],
        );
      },
    );
  }

  Widget _profileHeader(
      String name, String city, String email, VolunteerPlan plan) {
    final isPremium = plan.isPaid;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isPremium
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: plan == VolunteerPlan.pro
                    ? const [Color(0xFF5B21B6), Color(0xFF7C4DFF), Color(0xFFA855F7)]
                    : const [Color(0xFF133A63), Color(0xFF1A6BD8), Color(0xFF24B6A8)],
              )
            : VolunteerTheme.heroGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: (plan == VolunteerPlan.pro
                          ? const Color(0xFFA855F7)
                          : const Color(0xFF24B6A8))
                      .withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'V',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              if (isPremium)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  email.isEmpty ? city : '$city · $email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: VolunteerTheme.brandAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Verified Volunteer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11.5,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    if (isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
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
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'VERIFIED PREMIUM',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11.5,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Plan / Subscription card ────────────────────────────────────────

  Widget _planSection(BuildContext context, VolunteerStore s) {
    final plan = s.currentPlan;
    final isPaid = plan.isPaid;
    final renews = s.planRenewsOn;
    final renewLabel = renews == null
        ? null
        : '${_monthName(renews.month)} ${renews.day}, ${renews.year}';

    final gradient = plan == VolunteerPlan.pro
        ? const [Color(0xFF5B21B6), Color(0xFFA855F7)]
        : plan == VolunteerPlan.plus
            ? const [Color(0xFF1A6BD8), Color(0xFF24B6A8)]
            : const [Color(0xFFEFF4FA), Color(0xFFF8FAFC)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isPaid
            ? null
            : Border.all(color: VolunteerTheme.border),
        boxShadow: isPaid
            ? [
                BoxShadow(
                  color: gradient.last.withValues(alpha: 0.30),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.white.withValues(alpha: 0.22)
                      : const Color(0xFFFFB300).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  color: isPaid ? Colors.white : const Color(0xFFFFB300),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPaid ? 'You are on ${plan.name}' : 'Volunteer Premium',
                      style: TextStyle(
                        color: isPaid
                            ? Colors.white
                            : VolunteerTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.5,
                      ),
                    ),
                    Text(
                      isPaid
                          ? (renewLabel == null
                              ? 'Active perks'
                              : 'Renews $renewLabel')
                          : 'Get more reach, recognition & faster level-ups',
                      style: TextStyle(
                        color: isPaid
                            ? Colors.white.withValues(alpha: 0.85)
                            : VolunteerTheme.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPaid)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'NEW',
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
          const SizedBox(height: 14),
          if (!isPaid) ...[
            Row(
              children: [
                _planTeaser(
                    Icons.flash_on_rounded, 'Priority queue', 'on new requests'),
                const SizedBox(width: 8),
                _planTeaser(Icons.explore_rounded, 'Wider radius',
                    'up to 25 km'),
                const SizedBox(width: 8),
                _planTeaser(Icons.trending_up_rounded, '1.5×',
                    'impact points'),
              ],
            ),
            const SizedBox(height: 14),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _activePerk(Icons.flash_on_rounded, 'Priority queue'),
                _activePerk(Icons.explore_rounded,
                    'Up to ${plan.maxRadiusCapKm.toInt()} km'),
                _activePerk(
                    Icons.trending_up_rounded,
                    '${plan.pointsMultiplier.toStringAsFixed(plan.pointsMultiplier % 1 == 0 ? 0 : 2)}× points'),
                if (plan == VolunteerPlan.pro)
                  _activePerk(Icons.bolt_rounded, 'First-pick on SOS'),
                if (plan == VolunteerPlan.pro)
                  _activePerk(Icons.receipt_long_rounded, 'Expense tracker'),
              ],
            ),
            const SizedBox(height: 14),
          ],
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PremiumPlansScreen(role: UserRole.volunteer),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPaid
                    ? Colors.white
                    : VolunteerTheme.brandPrimary,
                foregroundColor: isPaid
                    ? VolunteerTheme.brandPrimary
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: Icon(
                  isPaid ? Icons.tune_rounded : Icons.rocket_launch_rounded,
                  size: 19),
              label: Text(
                isPaid ? 'Manage plan' : 'Upgrade — see plans',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planTeaser(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: VolunteerTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: VolunteerTheme.brandAccent, size: 19),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
                color: VolunteerTheme.textPrimary,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: VolunteerTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activePerk(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m - 1];

  Widget _availabilitySection(BuildContext context, VolunteerStore s) {
    return _card(
      title: 'Availability',
      icon: Icons.toggle_on_rounded,
      accent: VolunteerTheme.brandAccent,
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Available right now',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              s.isAvailableNow
                  ? 'You will receive nearby tasks immediately.'
                  : 'You won\'t receive new tasks until you turn this on.',
              style: const TextStyle(
                color: VolunteerTheme.textSecondary,
                fontSize: 12.5,
              ),
            ),
            value: s.isAvailableNow,
            onChanged: (_) => s.toggleAvailability(),
            activeThumbColor: VolunteerTheme.brandAccent,
          ),
        ],
      ),
    );
  }

  Widget _radiusSection(BuildContext context, VolunteerStore s) {
    return _card(
      title: 'Search radius',
      icon: Icons.radar_rounded,
      accent: VolunteerTheme.brandPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Up to ',
                  style: TextStyle(color: VolunteerTheme.textSecondary)),
              Text(
                '${s.maxRadiusKm.toStringAsFixed(0)} km',
                style: const TextStyle(
                  color: VolunteerTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Text(' from your location',
                  style: TextStyle(color: VolunteerTheme.textSecondary)),
            ],
          ),
          Slider(
            value: s.maxRadiusKm.clamp(1.0, s.currentPlan.maxRadiusCapKm),
            min: 1,
            max: s.currentPlan.maxRadiusCapKm,
            divisions: (s.currentPlan.maxRadiusCapKm - 1).toInt(),
            activeColor: VolunteerTheme.brandPrimary,
            label: '${s.maxRadiusKm.toStringAsFixed(0)} km',
            onChanged: s.setMaxRadius,
          ),
          if (s.currentPlan == VolunteerPlan.helper)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.lock_rounded,
                      size: 14, color: Color(0xFF7C4DFF)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Free plan caps the radius at 5 km. Upgrade for up to 25 km.',
                      style: TextStyle(
                        color: VolunteerTheme.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PremiumPlansScreen(role: UserRole.volunteer),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Upgrade'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _skillsSection(VolunteerStore s) {
    return _card(
      title: 'Skills & transport',
      icon: Icons.handshake_rounded,
      accent: const Color(0xFF7C4DFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in s.skills)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x227C4DFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    skill,
                    style: const TextStyle(
                      color: Color(0xFF7C4DFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.directions_walk_rounded,
                  size: 16, color: VolunteerTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                s.transport,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: VolunteerTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _preferencesSection(VolunteerStore s) {
    return _card(
      title: 'Notifications',
      icon: Icons.notifications_active_rounded,
      accent: const Color(0xFFFB8C00),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nearby task alerts',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Push when a task appears in your radius',
                style: TextStyle(fontSize: 12, color: VolunteerTheme.textSecondary)),
            value: s.notifyNearby,
            onChanged: s.toggleNotifyNearby,
            activeThumbColor: const Color(0xFFFB8C00),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Urgent / SOS alerts',
                style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Always notify for SOS and urgent requests',
                style: TextStyle(fontSize: 12, color: VolunteerTheme.textSecondary)),
            value: s.notifyUrgent,
            onChanged: s.toggleNotifyUrgent,
            activeThumbColor: VolunteerTheme.danger,
          ),
        ],
      ),
    );
  }

  Widget _supportSection(BuildContext context) {
    return _card(
      title: 'Account',
      icon: Icons.person_rounded,
      accent: VolunteerTheme.textSecondary,
      child: Column(
        children: [
          _menuTile(Icons.workspace_premium_rounded,
              'Certifications & licences', () => _showLicences(context)),
          _menuTile(Icons.shield_rounded, 'Background check',
              () => _showBackgroundCheck(context)),
          _menuTile(Icons.help_outline_rounded, 'Help & support',
              () => _showHelp(context)),
          _menuTile(Icons.info_outline_rounded, 'Legal & info',
              () => _showLegalAndInfo(context)),
          const Divider(height: 14, color: VolunteerTheme.border),
          _menuTile(
            Icons.logout_rounded,
            'Sign out',
            () => _confirmSignOut(context),
            danger: true,
          ),
        ],
      ),
    );
  }

  void _showLegalAndInfo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _InfoSheet(
        title: 'Legal & info',
        icon: Icons.info_outline_rounded,
        accent: VolunteerTheme.brandPrimary,
        sections: const [
          _InfoSection(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy — your data is yours',
            body:
                'We store only what is needed to match you with people who need help. Location is used only while you are on duty and is never shared with other volunteers. Email privacy@bridgecare.app to export or delete your data.',
          ),
          _InfoSection(
            icon: Icons.handshake_rounded,
            title: 'Terms — volunteer commitment',
            body:
                'By accepting a task you commit to arrive on time and treat the elderly user with dignity. Volunteers never administer medication, never give medical advice, and accept no money beyond reimbursement.',
          ),
          _InfoSection(
            icon: Icons.gavel_rounded,
            title: 'Suspension policy',
            body:
                'Three no-shows or any verified safety report results in account suspension pending review.',
          ),
          _InfoSection(
            icon: Icons.favorite_rounded,
            title: 'About BridgeCare',
            body:
                'BridgeCare v1.0.0 — connecting elderly people, their families, and trusted volunteers so no one ages alone.',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You\'ll need to sign in again to receive new volunteer tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VolunteerTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  // ─── Real elderly-care credentials volunteers can hold ─────────────────

  static const List<_VolunteerCredential> _credentials = [
    _VolunteerCredential(
      icon: Icons.medical_services_rounded,
      color: Color(0xFFE53935),
      title: 'First Aid & CPR Certificate',
      issuer: 'Red Cross / European Resuscitation Council',
      durationLabel: 'Valid 2 years',
      summary:
          'Recognised first-aid and cardiopulmonary resuscitation training, including AED use and choking response.',
    ),
    _VolunteerCredential(
      icon: Icons.psychology_alt_rounded,
      color: Color(0xFF7C4DFF),
      title: 'Mental Health First Aid (MHFA)',
      issuer: 'Mental Health First Aid International',
      durationLabel: 'Valid 3 years',
      summary:
          'Recognising mental-health crises in elderly adults — depression, anxiety, suicidal ideation — and approaching them safely.',
    ),
    _VolunteerCredential(
      icon: Icons.elderly_rounded,
      color: Color(0xFF24B6A8),
      title: 'Dementia Care Awareness',
      issuer: 'Alzheimer Europe accredited course',
      durationLabel: 'Lifetime',
      summary:
          'Communication, behavioural cues, safe environment design, and supporting families of people living with dementia.',
    ),
    _VolunteerCredential(
      icon: Icons.shield_rounded,
      color: Color(0xFF1976D2),
      title: 'Safeguarding Adults at Risk',
      issuer: 'Local social services authority',
      durationLabel: 'Refresh every 3 years',
      summary:
          'Identifying abuse, neglect or exploitation of vulnerable adults; mandatory reporting procedures.',
    ),
    _VolunteerCredential(
      icon: Icons.accessibility_new_rounded,
      color: Color(0xFFFB8C00),
      title: 'Manual Handling & Mobility Aid Use',
      issuer: 'Health & Safety Authority',
      durationLabel: 'Valid 2 years',
      summary:
          'Safe lifting, transferring with hoists, walking aids, wheelchairs — protects you and the person you help.',
    ),
    _VolunteerCredential(
      icon: Icons.medication_rounded,
      color: Color(0xFF26A69A),
      title: 'Medication Awareness (non-administering)',
      issuer: 'Ministry of Health certified',
      durationLabel: 'Refresh every 2 years',
      summary:
          'Verifying pharmacy receipts, recognising adverse reactions, never administering drugs yourself.',
    ),
    _VolunteerCredential(
      icon: Icons.policy_rounded,
      color: Color(0xFF455A64),
      title: 'Police / Criminal Record Clearance',
      issuer: 'Ministry of Justice',
      durationLabel: 'Renew yearly',
      summary:
          'Required for any volunteer working with vulnerable adults. Uploaded under Background Check.',
    ),
    _VolunteerCredential(
      icon: Icons.directions_car_filled_rounded,
      color: Color(0xFFEC407A),
      title: 'Driving Licence (Cat. B)',
      issuer: 'National driver registry',
      durationLabel: 'Valid 10 years',
      summary:
          'Required only if you offer transport assistance. Insurance documents must also be on file.',
    ),
  ];

  void _showLicences(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: VolunteerTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F5DA0), Color(0xFF24B6A8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Certifications & licences',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16.5,
                              color: VolunteerTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Recognised credentials for elderly-care volunteers',
                            style: TextStyle(
                              color: VolunteerTheme.textSecondary,
                              fontSize: 12.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: VolunteerTheme.border),
              Expanded(
                child: ListView.builder(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: _credentials.length,
                  itemBuilder: (ctx, i) => _CredentialCard(
                    credential: _credentials[i],
                    onUpload: () => _pickCredentialFile(context, _credentials[i]),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCredentialFile(
      BuildContext context, _VolunteerCredential cred) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Choose ${cred.title} (PDF, JPG, PNG)',
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (!context.mounted) return;
      final sizeKb = (file.size / 1024).toStringAsFixed(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: VolunteerTheme.brandAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${cred.title} uploaded · ${file.name} ($sizeKb KB)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file picker: $e')),
      );
    }
  }

  void _showBackgroundCheck(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: VolunteerTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Status hero
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF24B6A8), Color(0xFF1FA59A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
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
                      child: const Icon(Icons.verified_rounded,
                          color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Background check · Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 15.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Last reviewed Apr 14, 2026 · Renews in 11 months',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Step rows
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Documents on file',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: VolunteerTheme.textPrimary,
                    fontSize: 14.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _bgcRow(
                icon: Icons.badge_rounded,
                color: const Color(0xFF1976D2),
                title: 'Government photo ID',
                subtitle: 'Verified at sign-up · Apr 12, 2026',
                trailing: 'Verified',
              ),
              _bgcRow(
                icon: Icons.policy_rounded,
                color: const Color(0xFFE53935),
                title: 'Police / Criminal record clearance',
                subtitle: 'Issued by Ministry of Justice',
                trailing: 'Renew in 30d',
                trailingColor: const Color(0xFFFB8C00),
              ),
              _bgcRow(
                icon: Icons.contact_emergency_rounded,
                color: const Color(0xFF7C4DFF),
                title: 'Two character references',
                subtitle: 'Both confirmed by phone',
                trailing: 'Verified',
              ),
              _bgcRow(
                icon: Icons.medical_information_rounded,
                color: const Color(0xFF26A69A),
                title: 'Health & vaccination declaration',
                subtitle: 'Self-attested — upload optional',
                trailing: 'On file',
              ),
              const SizedBox(height: 14),
              // Upload zone
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _UploadZone(
                  onPickFromPc: () => _pickBackgroundCheckFile(context),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Accepted: PDF, JPG, PNG · Max 10 MB · We never share these documents with third parties.',
                  style: TextStyle(
                    color: VolunteerTheme.textSecondary,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Done',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bgcRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String trailing,
    Color trailingColor = const Color(0xFF2E7D32),
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: VolunteerTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VolunteerTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: VolunteerTheme.textPrimary,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: VolunteerTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: trailingColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trailing,
                style: TextStyle(
                  color: trailingColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBackgroundCheckFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select your police clearance document',
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (!context.mounted) return;
      Navigator.pop(context); // close the bottom sheet
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF24B6A8), Color(0xFF1FA59A)],
                  ),
                ),
                child: const Icon(Icons.cloud_done_rounded,
                    color: Colors.white, size: 36),
              ),
              const SizedBox(height: 12),
              const Text(
                'Document uploaded',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                file.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: VolunteerTheme.textSecondary,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(file.size / 1024).toStringAsFixed(0)} KB · awaiting review (24–48 h)',
                style: const TextStyle(
                  color: VolunteerTheme.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open file picker: $e')),
      );
    }
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _InfoSheet(
        title: 'Help & support',
        icon: Icons.help_outline_rounded,
        accent: VolunteerTheme.brandPrimary,
        sections: const [
          _InfoSection(
            icon: Icons.email_rounded,
            title: 'Email us',
            body: 'support@bridgecare.app — replies within 24 hours.',
          ),
          _InfoSection(
            icon: Icons.phone_rounded,
            title: 'Volunteer hotline',
            body: '+355 4 222 1234 (Mon–Fri, 9:00–18:00)',
          ),
          _InfoSection(
            icon: Icons.chat_bubble_rounded,
            title: 'In-app chat',
            body:
                'Tap a task you accepted to chat directly with the family member.',
          ),
          _InfoSection(
            icon: Icons.report_problem_rounded,
            title: 'Report a safety issue',
            body:
                'For urgent volunteer-safety concerns during a task, call 112 first, then contact us.',
          ),
        ],
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? VolunteerTheme.danger : VolunteerTheme.textPrimary;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: VolunteerTheme.textSecondary),
      onTap: onTap,
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Color accent,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: VolunteerTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VolunteerTheme.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0F0F2540), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: VolunteerTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoSection {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({
    required this.title,
    required this.icon,
    required this.accent,
    required this.sections,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<_InfoSection> sections;
  String? get primaryAction => null;
  VoidCallback? get onPrimary => null;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: VolunteerTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: VolunteerTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: VolunteerTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                itemCount: sections.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final s = sections[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: VolunteerTheme.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s.icon, color: accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: VolunteerTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: VolunteerTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (primaryAction != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onPrimary,
                    child: Text(
                      primaryAction!,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Volunteer credential model & card ─────────────────────────────────────

class _VolunteerCredential {
  const _VolunteerCredential({
    required this.icon,
    required this.color,
    required this.title,
    required this.issuer,
    required this.durationLabel,
    required this.summary,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String issuer;
  final String durationLabel;
  final String summary;
}

class _CredentialCard extends StatelessWidget {
  const _CredentialCard({required this.credential, required this.onUpload});

  final _VolunteerCredential credential;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: VolunteerTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VolunteerTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: credential.color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(credential.icon, color: credential.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credential.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: VolunteerTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${credential.issuer} · ${credential.durationLabel}',
                  style: TextStyle(
                    color: credential.color,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  credential.summary,
                  style: const TextStyle(
                    color: VolunteerTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onUpload,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: credential.color,
                        side: BorderSide(color: credential.color),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text(
                        'Upload from PC',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadZone extends StatefulWidget {
  const _UploadZone({required this.onPickFromPc});
  final VoidCallback onPickFromPc;

  @override
  State<_UploadZone> createState() => _UploadZoneState();
}

class _UploadZoneState extends State<_UploadZone> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPickFromPc,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _hover
                ? VolunteerTheme.brandAccent.withValues(alpha: 0.10)
                : const Color(0xFFF5FBFA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hover
                  ? VolunteerTheme.brandAccent
                  : VolunteerTheme.brandAccent.withValues(alpha: 0.45),
              width: 1.6,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF24B6A8), Color(0xFF1FA59A)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color:
                          VolunteerTheme.brandAccent.withValues(alpha: 0.40),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.cloud_upload_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              const Text(
                'Upload from your computer',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: VolunteerTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tap to browse, or drag a PDF / JPG / PNG file here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: VolunteerTheme.textSecondary,
                  fontSize: 12.2,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: widget.onPickFromPc,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text(
                    'Choose file',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: VolunteerTheme.brandAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
