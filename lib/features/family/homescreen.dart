import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/family_models.dart';
import '../../services/family_service.dart';
import 'chat.dart';
import 'health.dart';
import 'homepage.dart';
import 'location.dart';
import 'profile.dart';

class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen> {
  final FamilyService _service = FamilyService();

  int _currentIndex = 2;
  LinkedUser? _linkedUser;
  bool _isLoading = true;
  String? _error;

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await _service.fetchLinkedUser();
      if (!mounted) return;
      setState(() {
        _linkedUser = user;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load data. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _callLinkedUser() async {
    final phone = _linkedUser?.phoneNumber ?? '';
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildBody(String name, String email) {
    final user = _linkedUser;
    switch (_currentIndex) {
      case 0:
        return FamilyHealthPage(linkedUser: user);
      case 1:
        return FamilyLocationPage(linkedUser: user);
      case 2:
        return FamilyHomePage(
          linkedUser: user,
          alerts: _alerts,
          onCallTap: _callLinkedUser,
          onLocationTap: () => setState(() => _currentIndex = 1),
          onReportTap: () => setState(() => _currentIndex = 0),
          onChatTap: () => setState(() => _currentIndex = 3),
          onAlertTap: (alert) => setState(() => alert.isRead = true),
          onReminderAction: (reminder, status) async {
            setState(() => reminder.status = status);
            if (user != null) {
              await _service.updateReminderStatus(
                elderlyUid: user.uid,
                reminderId: reminder.id,
                status: status,
              );
            }
          },
        );
      case 3:
        if (user == null) {
          return const Center(
            child: Text(
              'No linked user found yet.',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          );
        }
        return FamilyChatScreen(linkedUser: user);
      case 4:
        return FamilyProfilePage(
          name: name,
          email: email,
          linkedUser: user,
          onLogout: () async {
            await _service.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Supabase.instance.client.auth.currentUser;
    final name =
        (authUser?.userMetadata?['name'] as String?) ?? authUser?.email ?? 'Family Member';
    final email = authUser?.email ?? '';
    final unreadCount = _alerts.where((a) => !a.isRead).length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          titleSpacing: 8,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0x1A1976D2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite, color: Color(0xFF1976D2), size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                _titles[_currentIndex],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1976D2)),
                  onPressed: () => setState(() => _currentIndex = 2),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
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
            child: Divider(height: 1, color: Color(0xFFE9ECEF)),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Color(0xFF6B7280), size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: Color(0xFF6B7280))),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = null;
                            });
                            _load();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildBody(name, email),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1976D2),
          unselectedItemColor: const Color(0xFFADB5BD),
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
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/family_models.dart';
import '../../services/family_service.dart';
import 'chat.dart';
import 'health.dart';
import 'homepage.dart';
import 'location.dart';
import 'profile.dart';

class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen> {
  int _currentIndex = 2;
  final FamilyService _service = FamilyService();

  LinkedUser? _linkedUser;
  bool _isLoading = true;
  String? _error;

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

  final _titles = const ['Health', 'Location', 'Home', 'Chat', 'Profile'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await _service.fetchLinkedUser();
      if (!mounted) return;
      setState(() {
        _linkedUser = user;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load data. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  void _onTab(int i) {
    if (i == _currentIndex) return;
    setState(() => _currentIndex = i);
  }

  Future<void> _call() async {
    final phone = _linkedUser?.phoneNumber ?? '';
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supaUser = Supabase.instance.client.auth.currentUser;
    final name = (supaUser?.userMetadata?['name'] as String?) ??
        supaUser?.email ??
        'Family Member';
    final email = supaUser?.email ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FB),
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
            : _error != null
                ? _buildError()
                : _buildBody(name, email),
        bottomNavigationBar: _buildNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final unread = _alerts.where((a) => !a.isRead).length;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0x1A1976D2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite, color: Color(0xFF1976D2), size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            _titles[_currentIndex],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1976D2)),
              onPressed: () => _onTab(2),
            ),
            if (unread > 0)
              Positioned(
                top: 8,
                right: 8,
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
        child: Divider(height: 1, color: Color(0xFFE9ECEF)),
      ),
    );
  }

  Widget _buildNav() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onTab,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF1976D2),
      unselectedItemColor: const Color(0xFFADB5BD),
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
    );
  }

  Widget _buildBody(String name, String email) {
    final user = _linkedUser;
    switch (_currentIndex) {
      case 0:
        return FamilyHealthPage(linkedUser: user);
      case 1:
        return FamilyLocationPage(linkedUser: user);
      case 2:
        return FamilyHomePage(
          linkedUser: user,
          alerts: _alerts,
          onCallTap: _call,
          onLocationTap: () => _onTab(1),
          onReportTap: () => _onTab(0),
          onChatTap: () => _onTab(3),
          onAlertTap: (a) => setState(() => a.isRead = true),
          onReminderAction: (r, s) async {
            setState(() => r.status = s);
            if (user != null) {
              await _service.updateReminderStatus(
                elderlyUid: user.uid,
                reminderId: r.id,
                status: s,
              );
            }
          },
        );
      case 3:
        return user == null
            ? const Center(
                child: Text(
                  'No linked user found yet.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              )
            : FamilyChatScreen(linkedUser: user);
      case 4:
        return FamilyProfilePage(
          name: name,
          email: email,
          linkedUser: user,
          onLogout: () async {
            await _service.signOut();
            if (mounted) Navigator.pushReplacementNamed(context, '/login');
          },
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFF6B7280), size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _load();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/family_models.dart';
import '../../services/family_service.dart';
import 'chat.dart';
import 'health.dart';
import 'homepage.dart';
import 'location.dart';
import 'profile.dart';

class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 2;
  final FamilyService _service = FamilyService();
  LinkedUser? _linkedUser;
  bool _isLoading = true;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

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

  final _titles = const ['Health', 'Location', 'Home', 'Chat', 'Profile'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await _service.fetchLinkedUser();
      if (!mounted) return;
      setState(() {
        _linkedUser = user;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load data. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  void _onTab(int i) {
    if (i == _currentIndex) return;
    setState(() => _currentIndex = i);
    _fadeCtrl
      ..reset()
      ..forward();
  }

  Future<void> _call() async {
    final phone = _linkedUser?.phoneNumber ?? '';
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supaUser = Supabase.instance.client.auth.currentUser;
    final name = (supaUser?.userMetadata?['name'] as String?) ??
        supaUser?.email ??
        'Family Member';
    final email = supaUser?.email ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FB),
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1976D2)),
              )
            : _error != null
                ? _buildError()
                : FadeTransition(opacity: _fadeAnim, child: _buildBody(name, email)),
        bottomNavigationBar: _buildNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final unread = _alerts.where((a) => !a.isRead).length;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0x1A1976D2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite, color: Color(0xFF1976D2), size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            _titles[_currentIndex],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF1976D2),
              ),
              onPressed: () => _onTab(2),
            ),
            if (unread > 0)
              Positioned(
                top: 8,
                right: 8,
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
        const SizedBox(width: 4),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE9ECEF)),
      ),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1976D2),
          unselectedItemColor: const Color(0xFFADB5BD),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
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
    );
  }

  Widget _buildBody(String name, String email) {
    final user = _linkedUser;
    switch (_currentIndex) {
      case 0:
        return FamilyHealthPage(linkedUser: user);
      case 1:
        return FamilyLocationPage(linkedUser: user);
      case 2:
        return FamilyHomePage(
          linkedUser: user,
          alerts: _alerts,
          onCallTap: _call,
          onLocationTap: () => _onTab(1),
          onReportTap: () => _onTab(0),
          onChatTap: () => _onTab(3),
          onAlertTap: (a) => setState(() => a.isRead = true),
          onReminderAction: (r, s) async {
            setState(() => r.status = s);
            if (user != null) {
              await _service.updateReminderStatus(
                elderlyUid: user.uid,
                reminderId: r.id,
                status: s,
              );
            }
          },
        );
      case 3:
        return user == null
            ? const Center(
                child: Text(
                  'No linked user found yet.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              )
            : FamilyChatScreen(linkedUser: user);
      case 4:
        return FamilyProfilePage(
          name: name,
          email: email,
          linkedUser: user,
          onLogout: () async {
            await _service.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFF6B7280), size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _load();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/family_models.dart';
import '../../services/family_service.dart';
import 'chat.dart';
import 'health.dart';
import 'homepage.dart';
import 'location.dart';
import 'profile.dart';

class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 2;
  final FamilyService _service = FamilyService();
  LinkedUser? _linkedUser;
  bool _isLoading = true;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

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

  final _titles = const ['Health', 'Location', 'Home', 'Chat', 'Profile'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await _service.fetchLinkedUser();
      if (!mounted) return;
      setState(() {
        _linkedUser = user;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load data. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  void _onTab(int i) {
    if (i == _currentIndex) return;
    setState(() => _currentIndex = i);
    _fadeCtrl
      ..reset()
      ..forward();
  }

  Future<void> _call() async {
    final phone = _linkedUser?.phoneNumber ?? '';
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supaUser = Supabase.instance.client.auth.currentUser;
    final name = (supaUser?.userMetadata?['name'] as String?) ??
        supaUser?.email ??
        'Family Member';
    final email = supaUser?.email ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FB),
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1976D2)),
              )
            : _error != null
                ? _buildError()
                : FadeTransition(opacity: _fadeAnim, child: _buildBody(name, email)),
        bottomNavigationBar: _buildNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final unread = _alerts.where((a) => !a.isRead).length;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0x1A1976D2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite, color: Color(0xFF1976D2), size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            _titles[_currentIndex],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF1976D2),
              ),
              onPressed: () => _onTab(2),
            ),
            if (unread > 0)
              Positioned(
                top: 8,
                right: 8,
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
        const SizedBox(width: 4),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE9ECEF)),
      ),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1976D2),
          unselectedItemColor: const Color(0xFFADB5BD),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
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
    );
  }

  Widget _buildBody(String name, String email) {
    final user = _linkedUser;
    switch (_currentIndex) {
      case 0:
        return FamilyHealthPage(linkedUser: user);
      case 1:
        return FamilyLocationPage(linkedUser: user);
      case 2:
        return FamilyHomePage(
          linkedUser: user,
          alerts: _alerts,
          onCallTap: _call,
          onLocationTap: () => _onTab(1),
          onReportTap: () => _onTab(0),
          onChatTap: () => _onTab(3),
          onAlertTap: (a) => setState(() => a.isRead = true),
          onReminderAction: (r, s) async {
            setState(() => r.status = s);
            if (user != null) {
              await _service.updateReminderStatus(
                elderlyUid: user.uid,
                reminderId: r.id,
                status: s,
              );
            }
          },
        );
      case 3:
        return user == null
            ? const Center(
                child: Text(
                  'No linked user found yet.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              )
            : FamilyChatScreen(linkedUser: user);
      case 4:
        return FamilyProfilePage(
          name: name,
          email: email,
          linkedUser: user,
          onLogout: () async {
            await _service.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFF6B7280), size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _load();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/family_models.dart';
import '../../services/family_service.dart';
import 'chat.dart';
import 'health.dart';
import 'homepage.dart';
import 'location.dart';
import 'profile.dart';

class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 2;
  final FamilyService _service = FamilyService();

  LinkedUser? _linkedUser;
  bool _isLoading = true;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

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

  final _titles = const ['Health', 'Location', 'Home', 'Chat', 'Profile'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await _service.fetchLinkedUser();
      if (!mounted) return;
      setState(() {
        _linkedUser = user;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load data. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  void _onTab(int i) {
    if (i == _currentIndex) return;
    setState(() => _currentIndex = i);
    _fadeCtrl
      ..reset()
      ..forward();
  }

  Future<void> _call() async {
    final phone = _linkedUser?.phoneNumber ?? '';
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final supaUser = Supabase.instance.client.auth.currentUser;
    final name = (supaUser?.userMetadata?['name'] as String?) ??
        supaUser?.email ??
        'Family Member';
    final email = supaUser?.email ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FB),
        appBar: _buildAppBar(),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1976D2)),
              )
            : _error != null
                ? _buildError()
                : FadeTransition(opacity: _fadeAnim, child: _buildBody(name, email)),
        bottomNavigationBar: _buildNav(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final unread = _alerts.where((a) => !a.isRead).length;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0x1A1976D2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite, color: Color(0xFF1976D2), size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            _titles[_currentIndex],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0),
            ),
          ),
        ],
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF1976D2),
              ),
              onPressed: () => _onTab(2),
            ),
            if (unread > 0)
              Positioned(
                top: 8,
                right: 8,
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
        const SizedBox(width: 4),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Color(0xFFE9ECEF)),
      ),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1976D2),
          unselectedItemColor: const Color(0xFFADB5BD),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
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
    );
  }

  Widget _buildBody(String name, String email) {
    final user = _linkedUser;
    switch (_currentIndex) {
      case 0:
        return FamilyHealthPage(linkedUser: user);
      case 1:
        return FamilyLocationPage(linkedUser: user);
      case 2:
        return FamilyHomePage(
          linkedUser: user,
          alerts: _alerts,
          onCallTap: _call,
          onLocationTap: () => _onTab(1),
          onReportTap: () => _onTab(0),
          onChatTap: () => _onTab(3),
          onAlertTap: (a) => setState(() => a.isRead = true),
          onReminderAction: (r, s) async {
            setState(() => r.status = s);
            if (user != null) {
              await _service.updateReminderStatus(
                elderlyUid: user.uid,
                reminderId: r.id,
                status: s,
              );
            }
          },
        );
      case 3:
        if (user == null) {
          return _buildNoLinkedUser();
        }
        return FamilyChatScreen(linkedUser: user);
      case 4:
        return FamilyProfilePage(
          name: name,
          email: email,
          linkedUser: user,
          onLogout: () async {
            await _service.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildNoLinkedUser() => const Center(
        child: Text(
          'No linked user found yet.',
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFF6B7280), size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _load();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/family_models.dart';
import '../../services/family_service.dart';
import 'homepage.dart';
import 'health.dart';
import 'location.dart';
import 'profile.dart';
import 'chat.dart';

class FamilyHomeScreen extends StatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  State<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends State<FamilyHomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 2;
  final FamilyService _service = FamilyService();

  LinkedUser? _linkedUser;
  bool _isLoading = true;
  String? _error;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

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

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _load();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await _service.fetchLinkedUser();
      if (mounted) setState(() { _linkedUser = user; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load data. Please check your connection.'; _isLoading = false; });
    }
  }

  void _onTab(int i) {
    if (i == _currentIndex) return;
    setState(() => _currentIndex = i);
    _fadeCtrl..reset()..forward();
  }

  Future<void> _call() async {
    final phone = _linkedUser?.phoneNumber ?? '';
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // Tabs: Health(0), Location(1), Home(2), Profile(3)
  final _titles = ['Health', 'Location', 'Home', 'Chat', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final supaUser = Supabase.instance.client.auth.currentUser;
    final name = supaUser?.userMetadata?['name'] as String? ?? supaUser?.email ?? 'Family Member';
    final email = supaUser?.email ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FB),
        appBar: _buildAppBar(name),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
            : _error != null
                ? _buildError()
                : FadeTransition(opacity: _fadeAnim, child: _buildBody(name, email)),
        bottomNavigationBar: _buildNav(),
       
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String name) {
    final unread = _alerts.where((a) => !a.isRead).length;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: const Color(0x1A1976D2), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.favorite, color: Color(0xFF1976D2), size: 18),
        ),
        const SizedBox(width: 10),
        Text(_titles[_currentIndex], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
      ]),
      actions: [
        Stack(children: [
          IconButton(icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1976D2)), onPressed: () => _onTab(2)),
          if (unread > 0)
            Positioned(top: 8, right: 8, child: Container(width: 9, height: 9,
              decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle))),
        ]),
        const SizedBox(width: 4),
      ],
      bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: Color(0xFFE9ECEF))),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1976D2),
          unselectedItemColor: const Color(0xFFADB5BD),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          elevation: 0,
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
    );
  }

  Widget _buildBody(String name, String email) {
    final user = _linkedUser;
  switch (_currentIndex) {
  case 0:
    return FamilyHealthPage(linkedUser: user);
  case 1:
    return FamilyLocationPage(linkedUser: user);
  case 2:
    return FamilyHomePage(
      linkedUser: user,
      alerts: _alerts,
      onCallTap: _call,
      onLocationTap: () => _onTab(1),
      onReportTap: () => _onTab(0),
      onChatTap: () => _onTab(3), // 🔥 ndryshuar
      onAlertTap: (a) => setState(() => a.isRead = true),
      onReminderAction: (r, s) async {
        setState(() => r.status = s);
        if (user != null) {
          await _service.updateReminderStatus(
            elderlyUid: user.uid,
            reminderId: r.id,
            status: s,
          );
        }
      },
    );
  case 3:
    return FamilyChatScreen(linkedUser: user!);
  case 4:
    return FamilyProfilePage(
      name: name,
      email: email,
      linkedUser: user,
      onLogout: () async {
        await _service.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
    );
  default:
    return const SizedBox();
}
  }

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.wifi_off_rounded, color: Color(0xFF6B7280), size: 48),
    const SizedBox(height: 16),
    Text(_error!, style: const TextStyle(color: Color(0xFF6B7280))),
    const SizedBox(height: 20),
    ElevatedButton(onPressed: () { setState(() { _isLoading = true; _error = null; }); _load(); },
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), foregroundColor: Colors.white),
      child: const Text('Retry')),
  ]));

  Widget _buildChatFAB() => FloatingActionButton.extended(
    onPressed: _openChat,
    backgroundColor: const Color(0xFF1976D2),
    icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
    label: const Text('Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  );

  void _openChat() {
    if (_linkedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No linked user found.')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => FamilyChatScreen(linkedUser: _linkedUser!)));
  }
}
