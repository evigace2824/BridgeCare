import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/family_models.dart';
import '../../services/family_service.dart';
import '../../services/job_post_service.dart';
import '../../services/premium_service.dart';
import '../../services/auth_service.dart';
import 'chat.dart';
import 'health.dart';
import 'homepage.dart';
import 'location.dart';
import 'profile.dart';
import 'tracking.dart';

class FamilyHomeShell extends StatefulWidget {
  const FamilyHomeShell({super.key});

  @override
  State<FamilyHomeShell> createState() => _FamilyHomeShellState();
}

class _FamilyHomeShellState extends State<FamilyHomeShell> {
  final FamilyService _service = FamilyService();
  int _index = 2;
  LinkedUser? _user;
  String _familyName = 'Family Member';
  bool _loading = true;
  String? _error;
  static const Color _brandPrimary = Color(0xFF133A63);
  static const Color _brandAccent = Color(0xFF24B6A8);

  final List<AppAlert> _alerts = [
    AppAlert(
      id: '1',
      title: 'Missed Medication',
      message: 'Morning aspirin was not taken at 8:00 AM.',
      severity: AlertSeverity.warning,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppAlert(
      id: '2',
      title: 'Inactivity Alert',
      message: 'No movement detected for 3 hours.',
      severity: AlertSeverity.info,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ];

  static const _titles = ['Health', 'Location', 'Home', 'Chat', 'Profile'];

  Future<void> _refreshDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadPremium();
  }

  Future<void> _loadPremium() async {
    try {
      final profile = await AuthService.instance.getCurrentUserProfile();
      await PremiumService.instance.loadForUser(profile: profile);
      await JobPostService.instance.loadFromRemote();
      JobPostService.instance.refreshExpirations();
    } catch (_) {}
  }

  Future<void> _load() async {
    try {
      final linked = await _service.fetchLinkedUser();
      final displayName = await _service.fetchCurrentFamilyDisplayName();
      if (!mounted) return;
      setState(() {
        _user = linked;
        _familyName = displayName;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load family dashboard.';
        _loading = false;
      });
    }
  }

  Future<void> _call() async {
    final phone = _user?.phoneNumber ?? '';
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  PreferredSizeWidget _buildChatShelfAppBar(int unreadCount) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF2F9FF),
              const Color(0xFFE8F2FC).withValues(alpha: 0.96),
              Colors.white.withValues(alpha: 0.92),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 48,
      leadingWidth: 52,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0x1424B6A8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset('assets/bridgecare_logo.png', fit: BoxFit.cover),
            ),
          ),
        ),
      ),
      title: const SizedBox.shrink(),
      actions: [
        IconButton(
          tooltip: 'Help & support',
          icon: const Icon(Icons.support_agent_rounded, color: _brandPrimary),
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Need help?'),
                content: const Text(
                  'Use alerts and chat for fast communication. For urgent help, call your care recipient using the call button.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            );
          },
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: _brandPrimary),
              onPressed: _showAlertsSheet,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE53935),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE3EAF3)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Supabase.instance.client.auth.currentUser;
    final email = auth?.email ?? '';

    final unreadCount = _alerts.where((a) => !a.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFEAF2F9),
      // Chat supplies the conversation title row; thin shelf = logo + support only (no subtitle overlap).
      appBar: _index == 3
          ? _buildChatShelfAppBar(unreadCount)
          : AppBar(
              elevation: 0,
              scrolledUnderElevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF0F8FF),
                      const Color(0xFFE4F0FB).withValues(alpha: 0.98),
                      Colors.white.withValues(alpha: 0.94),
                    ],
                  ),
                ),
              ),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 72,
              title: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0x1424B6A8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/bridgecare_logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _titles[_index],
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: _brandPrimary,
                          ),
                        ),
                        Text(
                          _user != null
                              ? 'Connected to ${_user!.fullName}'
                              : 'BridgeCare Family',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5A6A7A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Help & support',
                  icon: const Icon(Icons.support_agent_rounded, color: _brandPrimary),
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Need help?'),
                        content: const Text(
                          'Use alerts and chat for fast communication. For urgent help, call your care recipient using the call button.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: _brandPrimary),
                      onPressed: _showAlertsSheet,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _brandPrimary))
          : _error != null
              ? Center(child: Text(_error!))
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFE4F0FA),
                        Color(0xFFF2F7FC),
                        Color(0xFFEEF6FF),
                        Color(0xFFF0F4F8),
                      ],
                      stops: [0.0, 0.35, 0.72, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -50,
                        left: -30,
                        child: IgnorePointer(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF24B6A8).withValues(alpha: 0.16),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 180,
                        right: -40,
                        child: IgnorePointer(
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF7C4DFF).withValues(alpha: 0.10),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 120,
                        right: -20,
                        child: IgnorePointer(
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF1976D2).withValues(alpha: 0.09),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -24,
                        bottom: 36,
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.08,
                            child: Image.asset(
                              'assets/bridgecare_logo.png',
                              width: 150,
                              height: 150,
                            ),
                          ),
                        ),
                      ),
                      RefreshIndicator(
                        color: _brandPrimary,
                        onRefresh: _refreshDashboard,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: const Offset(0.03, 0),
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(position: slide, child: child),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(_index),
                          child: _body(email),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.98),
              const Color(0xFFF3F8FD),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF133A63).withValues(alpha: 0.10),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x280D2640),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (v) {
              if (v == _index) return;
              HapticFeedback.selectionClick();
              setState(() => _index = v);
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: _brandPrimary,
            unselectedItemColor: const Color(0xFF9AA9B7),
            selectedFontSize: 12.5,
            unselectedFontSize: 11.5,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.monitor_heart_outlined),
                activeIcon: Icon(Icons.monitor_heart_rounded),
                label: 'Health',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined),
                activeIcon: Icon(Icons.location_on_rounded),
                label: 'Location',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble_rounded),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _user == null ||
              _index == 1 ||
              _index == 3
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _call();
              },
              backgroundColor: _brandAccent,
              icon: const Icon(Icons.call_rounded, color: Colors.white),
              label: const Text(
                'Quick call',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
    );
  }

  void _showAlertsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Alerts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(_alerts.clear);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear all'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          for (final a in _alerts) {
                            a.isRead = true;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Mark all read'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_alerts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No alerts right now.'),
                  )
                else
                  ..._alerts.map(
                    (a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        a.severity == AlertSeverity.warning
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline_rounded,
                        color: a.severity == AlertSeverity.warning
                            ? const Color(0xFFFF9800)
                            : const Color(0xFF1976D2),
                      ),
                      title: Text(a.title),
                      subtitle: Text(a.message),
                      trailing: a.isRead
                          ? const SizedBox.shrink()
                          : const Icon(Icons.circle, size: 8, color: Color(0xFFE53935)),
                      onTap: () => setState(() => a.isRead = true),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _body(String email) {
    if (_user == null) {
      return _emptyLinkedUserState();
    }

    switch (_index) {
      case 0:
        return FamilyHealthPage(linkedUser: _user);
      case 1:
        return FamilyLocationPage(linkedUser: _user);
      case 2:
        return FamilyHomePage(
          linkedUser: _user,
          alerts: _alerts,
          onCallTap: _call,
          onFamilyTab: (i) => setState(() => _index = i),
          onLocationTap: () => setState(() => _index = 1),
          onReportTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FamilyTrackingPage(linkedUser: _user),
              ),
            );
          },
          onChatTap: () => setState(() => _index = 3),
          onAlertTap: (a) => setState(() => a.isRead = true),
          onReminderAction: (r, s) async {
            setState(() => r.status = s);
            if (_user != null) {
              await _service.updateReminderStatus(
                elderlyUid: _user!.uid,
                reminderId: r.id,
                status: s,
              );
            }
          },
        );
      case 3:
        return FamilyChatScreen(linkedUser: _user!, embeddedInShell: true);
      case 4:
        return FamilyProfilePage(
          name: _familyName,
          email: email,
          linkedUser: _user,
          onNameUpdated: (nextName) {
            setState(() => _familyName = nextName);
          },
          onLogout: () async {
            await _service.signOut();
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _promptLinkPatient() async {
    final codeCtrl = TextEditingController();
    final linked = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link to patient'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter the family link code from your loved one\'s BridgeCare profile '
              '("My family link code").',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Family link code',
                hintText: 'CB-2026-A4F8',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Link'),
          ),
        ],
      ),
    );
    if (linked != true || !mounted) return;

    try {
      final patientName =
          await _service.linkToPatientByCode(codeCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to $patientName.'),
          backgroundColor: _brandAccent,
        ),
      );
      await _load();
    } on FamilyLinkException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      codeCtrl.dispose();
    }
  }

  Widget _emptyLinkedUserState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x121976D2),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      child: Image(image: AssetImage('assets/bridgecare_logo.png')),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'BridgeCare Family',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _brandPrimary),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'No patient linked yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Ask your family member for their link code from Profile → '
                '"My family link code". Once linked, you will see their name here '
                'and can view health, reminders, location, and chat.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _promptLinkPatient,
          icon: const Icon(Icons.link_rounded),
          label: const Text('Enter family link code'),
        ),
      ],
    );
  }
}
