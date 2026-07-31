import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, Supabase;
import 'package:url_launcher/url_launcher.dart';

import '../../models/family_models.dart';
import '../../models/job_application_model.dart';
import '../../models/job_post_model.dart';
import '../../services/family_service.dart';
import '../../services/job_post_service.dart';
import '../../models/user_model.dart';
import '../premium/premium_plans_screen.dart';
import 'family_plan_store.dart';
import 'subscription_page_clean.dart';
import 'widgets/two_factor_otp_dialog.dart';

// Plan state is stored in `FamilyPlanStore`. This local helper preserves the
// previous static-getter call sites without changing their signature.
class _PlanStore {
  static UserPlan get currentPlan => FamilyPlanStore.instance.plan;
  static set currentPlan(UserPlan p) => FamilyPlanStore.instance.setPlan(p);
}

class FamilyProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final LinkedUser? linkedUser;
  final ValueChanged<String>? onNameUpdated;
  final VoidCallback onLogout;

  const FamilyProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.linkedUser,
    this.onNameUpdated,
    required this.onLogout,
  });

  @override
  State<FamilyProfilePage> createState() => _FamilyProfilePageState();
}

class _FamilyProfilePageState extends State<FamilyProfilePage> {
  static const _primary = Color(0xFF1976D2);
  static const _primaryDark = Color(0xFF1565C0);
  static const _red = Color(0xFFE53935);
  static const _green = Color(0xFF4CAF50);
  static const _gold = Color(0xFFFFB300);
  static const _purple = Color(0xFF7C3AED);
  static const _shadow = Color(0x121976D2);

  final FamilyService _svc = FamilyService();
  late String _name;
  bool _notifications = true;
  bool _alerts = true;
  bool _twoFactor = false;
  bool _saving = false;

  UserPlan get _plan => _PlanStore.currentPlan;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _loadTwoFactorState();
  }

  String get _planLabel {
    switch (_plan) {
      case UserPlan.pro: return 'Pro Plan';
      case UserPlan.premium: return 'Premium Plan';
      case UserPlan.free: return 'Free Plan';
    }
  }

  Color get _planColor {
    switch (_plan) {
      case UserPlan.pro: return _primary;
      case UserPlan.premium: return _purple;
      case UserPlan.free: return const Color(0xFF6B7280);
    }
  }

  IconData get _planIcon {
    switch (_plan) {
      case UserPlan.pro: return Icons.star_rounded;
      case UserPlan.premium: return Icons.workspace_premium_rounded;
      case UserPlan.free: return Icons.person_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
    Positioned(
      top: -46,
      left: -32,
      child: IgnorePointer(
        child: Container(
          width: 185,
          height: 185,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _primary.withValues(alpha: 0.14),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ),
    Positioned(
      right: -50,
      bottom: 26,
      child: IgnorePointer(
        child: Container(
          width: 230,
          height: 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _purple.withValues(alpha: 0.09),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    ),
    SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.94),
              const Color(0xFFEAF3FF).withValues(alpha: 0.95),
            ],
          ),
          border: Border.all(color: _primary.withValues(alpha: 0.18)),
        ),
        child: const Row(
          children: [
            Icon(Icons.tips_and_updates_rounded, size: 18, color: Color(0xFF1565C0)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tap your avatar to edit name.',
                style: TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF35566F),
                  height: 1.28,
                ),
              ),
            ),
          ],
        ),
      ),
      // Avatar with plan badge
      Center(child: Column(children: [
        Stack(children: [
          Container(width: 88, height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _plan == UserPlan.premium
                    ? [const Color(0xFF5B21B6), const Color(0xFFA855F7)]
                    : _plan == UserPlan.pro
                        ? [const Color(0xFF1565C0), const Color(0xFF42A5F5)]
                        : [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_plan == UserPlan.premium ? _purple : _primary).withAlpha(70),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: Text(_name.isNotEmpty ? _name[0].toUpperCase() : 'F',
              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)))),

          // Edit button
          Positioned(bottom: 0, right: 0, child: GestureDetector(
            onTap: _editInfo,
            child: Container(padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
              child: const Icon(Icons.edit, color: Colors.white, size: 14)))),

          // Plan badge (star for Pro, crown for Premium)
          if (_plan == UserPlan.pro || _plan == UserPlan.premium)
            Positioned(top: 0, right: 0,
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: _plan == UserPlan.premium ? _gold : _gold,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [BoxShadow(color: _gold.withAlpha(100), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Icon(
                  _plan == UserPlan.premium ? Icons.workspace_premium_rounded : Icons.star_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              )),
        ]),
        const SizedBox(height: 10),
        Text(_name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
        Text(widget.email, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        const SizedBox(height: 12),

        // Current plan + upgrade button
        GestureDetector(
          onTap: _openSubscription,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _planColor.withAlpha(80), width: 1.5),
              boxShadow: [BoxShadow(color: _shadow, blurRadius: 12, offset: const Offset(0, 3))],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: _planColor.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                child: Icon(_planIcon, color: _planColor, size: 16),
              ),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_planLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _planColor)),
                if (_plan == UserPlan.free)
                  const Text('Tap to upgrade →', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                if (_plan != UserPlan.free)
                  const Text('Manage plan →', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ]),
              const SizedBox(width: 6),
            ]),
          ),
        ),
      ])),
      const SizedBox(height: 18),

      _quickActionsRow(),
      const SizedBox(height: 18),

      if (_saving) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator(color: _primary)),

      _sectionLabel('Personal Information'),
      _card(child: Column(children: [
        _infoRow(Icons.person_outline, 'Full Name', _name),
        const Divider(height: 14, color: Color(0xFFE9ECEF)),
        _infoRow(Icons.email_outlined, 'Email', widget.email),
      ])),
      const SizedBox(height: 14),

      _sectionLabel('Linked User'),
      _card(child: widget.linkedUser == null
        ? const Text('No linked user found.', style: TextStyle(color: Color(0xFF6B7280), fontSize: 13))
        : Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0x1A1976D2), shape: BoxShape.circle),
              child: Center(child: Text(widget.linkedUser!.fullName[0].toUpperCase(),
                style: const TextStyle(color: _primary, fontWeight: FontWeight.bold, fontSize: 18)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.linkedUser!.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(widget.linkedUser!.phoneNumber, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ])),
            _statusBadge(widget.linkedUser!.healthStatus),
          ])),
      const SizedBox(height: 14),

      _sectionLabel('Care snapshot'),
      _careSnapshotCard(),
      const SizedBox(height: 14),

      _sectionLabel('Trusted volunteers'),
      _trustedVolunteersCard(),
      const SizedBox(height: 14),

      _sectionLabel('Settings'),
      _card(child: Column(children: [
        _toggleRow(Icons.notifications_outlined, 'Notifications', _notifications, (v) => setState(() => _notifications = v)),
        const Divider(height: 14, color: Color(0xFFE9ECEF)),
        _toggleRow(Icons.warning_amber_rounded, 'Alerts', _alerts, (v) => setState(() => _alerts = v)),
        const Divider(height: 14, color: Color(0xFFE9ECEF)),
        _toggleRow(Icons.security_rounded, 'Two-Step Verification', _twoFactor, _handleTwoFactorToggle),
      ])),
      const SizedBox(height: 20),

      // Logout button
      SizedBox(width: double.infinity, height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
            boxShadow: [BoxShadow(color: _primary.withAlpha(77), blurRadius: 12, offset: const Offset(0, 4))]),
          child: ElevatedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            label: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))))),
      const SizedBox(height: 10),
      Center(child: TextButton(onPressed: () {}, child: const Text('Delete Account', style: TextStyle(color: _red, fontSize: 13)))),
    ]),
  )]);

  Widget _quickActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: _quickAction(
          icon: Icons.call_rounded,
          label: 'Call',
          color: _green,
          onTap: _callLinkedUser,
        )),
        const SizedBox(width: 10),
        Expanded(child: _quickAction(
          icon: Icons.location_on_rounded,
          label: 'Safe zones',
          color: _primary,
          onTap: _showSafeZonesSheet,
        )),
        const SizedBox(width: 10),
        Expanded(child: _quickAction(
          icon: Icons.emergency_rounded,
          label: 'Emergency',
          color: _red,
          onTap: _showEmergencySheet,
        )),
        const SizedBox(width: 10),
        Expanded(child: _quickAction(
          icon: Icons.group_add_rounded,
          label: 'Invite',
          color: _purple,
          onTap: _showInviteSheet,
        )),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: const [
              BoxShadow(color: _shadow, blurRadius: 10, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callLinkedUser() async {
    final phone = widget.linkedUser?.phoneNumber.trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number on file for your linked user.')),
      );
      return;
    }
    final uri = Uri.parse('tel:${phone.replaceAll(RegExp(r'\s+'), '')}');
    try {
      final ok = await launchUrl(uri);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t open the dialer for $phone.')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Couldn\'t open the dialer for $phone.')),
      );
    }
  }

  void _showSafeZonesSheet() {
    final name = widget.linkedUser?.fullName ?? 'your linked user';
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded, color: _primary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Safe zones',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              'You\'ll get an alert if $name leaves any of these locations '
              'or if their device goes offline outside of them.',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            _sheetTile(
              icon: Icons.home_rounded,
              tint: const Color(0xFF2563EB),
              title: 'Home',
              subtitle: 'Default safe zone · 80 m radius',
            ),
            _sheetTile(
              icon: Icons.local_pharmacy_rounded,
              tint: const Color(0xFF059669),
              title: 'Neighbourhood pharmacy',
              subtitle: '350 m from home',
            ),
            _sheetTile(
              icon: Icons.park_rounded,
              tint: const Color(0xFF7C3AED),
              title: 'Park bench (afternoons)',
              subtitle: 'Active weekdays 15:00–18:00',
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _primary.withValues(alpha: 0.45)),
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text('Add a safe zone'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmergencySheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emergency_rounded, color: _red),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Emergency contacts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            const Text(
              'If your linked user triggers an SOS, these contacts get a call '
              'and a push notification in this order.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            _sheetTile(
              icon: Icons.shield_moon_rounded,
              tint: _red,
              title: 'You · primary',
              subtitle: widget.email,
            ),
            _sheetTile(
              icon: Icons.local_hospital_rounded,
              tint: const Color(0xFF0EA5E9),
              title: 'Local clinic',
              subtitle: '+355 4 222 1234',
            ),
            _sheetTile(
              icon: Icons.local_police_rounded,
              tint: const Color(0xFF1F2937),
              title: 'Emergency services',
              subtitle: '112',
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit contacts',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteSheet() {
    final inviteCode = (widget.linkedUser?.fullName ?? 'CARE')
        .replaceAll(RegExp(r'[^A-Za-z]'), '')
        .toUpperCase()
        .padRight(4, 'X')
        .substring(0, 4);
    final link = 'carebridge.app/invite/$inviteCode-${DateTime.now().millisecondsSinceEpoch % 9999}';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _purple.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.group_add_rounded, color: _purple),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Invite a family member',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              'Send this link to a sibling, partner, or trusted relative to '
              'share visibility on ${widget.linkedUser?.fullName ?? 'your linked user'}\'s care.',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: link));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invite link copied'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: _primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _purple.withValues(alpha: 0.45)),
                      foregroundColor: _purple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.email_rounded),
                    label: const Text('Email link'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: link));
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Link copied · ready to share'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Copy & share',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required Color tint,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tint, size: 18),
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
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trustedVolunteersCard() {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'family_demo';
    return ListenableBuilder(
      listenable: JobPostService.instance,
      builder: (context, _) {
        final svc = JobPostService.instance;
        final myPosts = svc.postsForFamily(userId);
        final volunteers = <String, _TrustedVolunteer>{};
        for (final post in myPosts) {
          for (final app in svc.applicationsForPost(post.id)) {
            if (app.status == JobApplicationStatus.rejected) continue;
            volunteers.update(
              app.volunteerId,
              (existing) => existing.merge(app, post),
              ifAbsent: () => _TrustedVolunteer.fromApplication(app, post),
            );
          }
        }
        final list = volunteers.values.toList()
          ..sort((a, b) => b.helpsForYou.compareTo(a.helpsForYou));

        if (list.isEmpty) {
          return _card(child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x1A1976D2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.volunteer_activism_rounded,
                    color: _primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Volunteers who accept your job posts will appear here, so you can spot the helpers your family already trusts.',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ));
        }

        return _card(child: Column(
          children: [
            for (int i = 0; i < list.length && i < 4; i++) ...[
              _trustedVolunteerRow(list[i]),
              if (i < list.length - 1 && i < 3)
                const Divider(height: 16, color: Color(0xFFE9ECEF)),
            ],
          ],
        ));
      },
    );
  }

  Widget _trustedVolunteerRow(_TrustedVolunteer v) {
    final palette = <Color>[_primary, _purple, _green, _gold];
    final color = palette[v.name.hashCode.abs() % palette.length];
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withAlpha(180)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              v.name.isNotEmpty ? v.name[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      v.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  if (v.verified) ...[
                    const Icon(Icons.verified_rounded,
                        color: _primary, size: 15),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: _gold, size: 13),
                        const SizedBox(width: 3),
                        Text(
                          v.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF8A5A00),
                            fontWeight: FontWeight.w900,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${v.helpsForYou} help${v.helpsForYou == 1 ? '' : 's'} for you · ${v.completedTasks} total tasks',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _careSnapshotCard() {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'family_demo';
    return ListenableBuilder(
      listenable: JobPostService.instance,
      builder: (context, _) {
        final svc = JobPostService.instance;
        final posts = svc.postsForFamily(userId);
        final active = posts
            .where((p) => p.effectiveStatus == JobPostStatus.active)
            .length;
        final inProgress = posts
            .where((p) =>
                p.effectiveStatus == JobPostStatus.accepted ||
                p.effectiveStatus == JobPostStatus.inProgress)
            .length;
        final confirmed = posts
            .where((p) =>
                p.effectiveStatus == JobPostStatus.confirmed ||
                p.effectiveStatus == JobPostStatus.completed)
            .length;
        final lastActivity = posts.isEmpty ? null : posts.first.createdAt;
        final status = widget.linkedUser?.healthStatus;

        return _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _snapshotStat(
                    icon: Icons.flash_on_rounded,
                    color: _primary,
                    value: active.toString(),
                    label: 'Active requests',
                  )),
                  Container(width: 1, height: 36, color: const Color(0xFFE9ECEF)),
                  Expanded(child: _snapshotStat(
                    icon: Icons.directions_run_rounded,
                    color: _purple,
                    value: inProgress.toString(),
                    label: 'In progress',
                  )),
                  Container(width: 1, height: 36, color: const Color(0xFFE9ECEF)),
                  Expanded(child: _snapshotStat(
                    icon: Icons.verified_rounded,
                    color: _green,
                    value: confirmed.toString(),
                    label: 'Completed',
                  )),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE9ECEF)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: status == null
                          ? const Color(0x1A6B7280)
                          : _statusColor(status).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: 15,
                      color: status == null
                          ? const Color(0xFF6B7280)
                          : _statusColor(status),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wellness',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          status?.label ?? 'No linked user',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Last request',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _relativeTime(lastActivity),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _snapshotStat({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _statusColor(HealthStatus s) {
    return s.type == HealthStatusType.emergency
        ? _red
        : s.type == HealthStatusType.warning
            ? const Color(0xFFFF9800)
            : _green;
  }

  String _relativeTime(DateTime? when) {
    if (when == null) return '—';
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.97),
          const Color(0xFFF2F7FC),
        ],
      ),
      border: Border.all(color: _primary.withValues(alpha: 0.10)),
      boxShadow: const [BoxShadow(color: _shadow, blurRadius: 14, offset: Offset(0, 4))],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  );

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 2),
    child: Row(children: [
      Container(width: 4, height: 18, decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(4))),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primaryDark)),
    ]));

  Widget _infoRow(IconData icon, String label, String value) => Row(children: [
    Icon(icon, color: _primary, size: 18),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)))),
    Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
  ]);

  Widget _toggleRow(IconData icon, String label, bool value, void Function(bool) onChanged) => Row(children: [
    Icon(icon, color: _primary, size: 18),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)))),
    Switch(value: value, activeThumbColor: _primary, onChanged: onChanged),
  ]);

  Widget _statusBadge(HealthStatus s) {
    final color = s.type == HealthStatusType.emergency ? _red
        : s.type == HealthStatusType.warning ? const Color(0xFFFF9800) : _green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(16)),
      child: Text(s.label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)));
  }

  void _openSubscription() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PremiumPlansScreen(role: UserRole.family),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _editInfo() async {
    final ctrl = TextEditingController(text: _name);
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Edit Name', style: TextStyle(color: _primaryDark, fontWeight: FontWeight.bold)),
      content: TextField(controller: ctrl,
        decoration: InputDecoration(labelText: 'Full Name',
          prefixIcon: const Icon(Icons.person_outline, color: _primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: _primary),
          child: const Text('Save', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (ok != true) return;
    setState(() { _name = ctrl.text.trim(); _saving = true; });
    await _svc.updateProfile(fullName: _name, phoneNumber: '');
    widget.onNameUpdated?.call(_name);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _loadTwoFactorState() async {
    final enabled = await _svc.isTwoFactorEnabled();
    if (!mounted) return;
    setState(() => _twoFactor = enabled);
  }

  Future<void> _handleTwoFactorToggle(bool nextValue) async {
    if (_saving) return;
    if (nextValue == _twoFactor) return;

    if (!nextValue) {
      final disable = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Disable 2-Step Verification?'),
          content: const Text('This will reduce account protection. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: _red),
              child: const Text('Disable', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (disable != true) return;
      setState(() => _saving = true);
      await _svc.setTwoFactorEnabled(false);
      if (!mounted) return;
      setState(() {
        _twoFactor = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Two-step verification disabled.')),
      );
      return;
    }

    final hint = widget.email.trim().isEmpty ? null : widget.email.trim();
    final mailedTo = _svc.effectiveTwoFactorEmail(hintEmail: hint);
    if (mailedTo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No email on this account. Sign in with email to use two-step verification.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _svc.sendTwoFactorOtp(email: hint);
      if (!mounted) return;
      setState(() => _saving = false);
      HapticFeedback.selectionClick();
      final verified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => TwoFactorOtpDialog(
          displayEmail:
              mailedTo.isEmpty ? 'your email' : mailedTo,
        ),
      );
      if (verified != true) return;

      setState(() => _saving = true);
      await _svc.setTwoFactorEnabled(true);
      if (!mounted) return;
      setState(() {
        _twoFactor = true;
        _saving = false;
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Two-step verification is on. You\'ll verify by email when signing in.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      HapticFeedback.lightImpact();
      final msg = _friendlyError(e).trim().isNotEmpty
          ? _friendlyError(e)
          : 'Could not send verification email. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  String _friendlyError(Object e) {
    if (e is AuthException) return e.message;
    final raw = e.toString();
    if (raw.contains('invalid') || raw.contains('token')) {
      return 'Invalid code. Please check the latest email and try again.';
    }
    if (raw.contains('expired')) {
      return 'That code expired. Tap Resend and try again.';
    }
    if (raw.contains('429')) {
      return 'Too many attempts. Please wait a moment and retry.';
    }
    return raw.replaceFirst('AuthException(message: ', '').split(', statusCode:').first.trim();
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Sign Out'),
      content: const Text('Are you sure you want to sign out?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: _red),
          child: const Text('Sign Out', style: TextStyle(color: Colors.white))),
      ],
    ));
    if (ok == true) widget.onLogout();
  }
}

class _TrustedVolunteer {
  _TrustedVolunteer({
    required this.volunteerId,
    required this.name,
    required this.rating,
    required this.completedTasks,
    required this.verified,
    required this.helpsForYou,
  });

  final String volunteerId;
  final String name;
  final double rating;
  final int completedTasks;
  final bool verified;
  final int helpsForYou;

  factory _TrustedVolunteer.fromApplication(
    JobApplicationModel app,
    JobPostModel post,
  ) {
    final isHelpForYou = post.effectiveStatus == JobPostStatus.confirmed ||
        post.effectiveStatus == JobPostStatus.completed ||
        post.effectiveStatus == JobPostStatus.inProgress ||
        post.effectiveStatus == JobPostStatus.accepted;
    return _TrustedVolunteer(
      volunteerId: app.volunteerId,
      name: app.volunteerName,
      rating: app.rating,
      completedTasks: app.completedTasks,
      verified: app.verificationStatus.toLowerCase().contains('verified'),
      helpsForYou: isHelpForYou ? 1 : 0,
    );
  }

  _TrustedVolunteer merge(JobApplicationModel app, JobPostModel post) {
    final isHelpForYou = post.effectiveStatus == JobPostStatus.confirmed ||
        post.effectiveStatus == JobPostStatus.completed ||
        post.effectiveStatus == JobPostStatus.inProgress ||
        post.effectiveStatus == JobPostStatus.accepted;
    return _TrustedVolunteer(
      volunteerId: volunteerId,
      name: name,
      rating: ((rating + app.rating) / 2),
      completedTasks: app.completedTasks > completedTasks
          ? app.completedTasks
          : completedTasks,
      verified: verified || app.verificationStatus.toLowerCase().contains('verified'),
      helpsForYou: helpsForYou + (isHelpForYou ? 1 : 0),
    );
  }
}
