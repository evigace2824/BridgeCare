import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/job_post_service.dart';
import '../../services/notification_service.dart';
import '../../services/premium_service.dart';
import '../../services/volunteer_premium_service.dart';
import 'data/volunteer_store.dart';
import 'tabs/volunteer_home_tab.dart';
import 'tabs/volunteer_impact_tab.dart';
import 'tabs/volunteer_map_tab.dart';
import 'tabs/volunteer_profile_tab.dart';
import 'tabs/volunteer_requests_tab.dart';
import 'widgets/volunteer_theme.dart';

class VolunteerHomeShell extends StatefulWidget {
  const VolunteerHomeShell({super.key});

  @override
  State<VolunteerHomeShell> createState() => _VolunteerHomeShellState();
}

class _VolunteerHomeShellState extends State<VolunteerHomeShell> {
  int _index = 0;

  static const _titles = ['Home', 'Requests', 'Map', 'Impact', 'Profile'];

  @override
  void initState() {
    super.initState();
    _hydrateProfile();
  }

  Future<void> _hydrateProfile() async {
    try {
      final profile = await AuthService.instance.getCurrentUserProfile();
      if (!mounted || profile == null) return;
      await PremiumService.instance.loadForUser(profile: profile);
      await NotificationService.instance.loadPersisted();
      await JobPostService.instance.loadFromRemote();
      JobPostService.instance.refreshExpirations();
      await VolunteerPremiumService.instance.loadSettings();
      VolunteerStore.instance.hydrateFromProfile(
        name: profile.fullName,
        email: profile.email,
        city: profile.address,
        transportLabel: profile.transport,
        skillsList: _splitSkills(profile.volunteerSkills),
      );
    } catch (_) {
      // Non-fatal: keep defaults if profile load fails.
    }
  }

  List<String>? _splitSkills(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return raw
        .split(RegExp(r'[,;\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      VolunteerHomeTab(
        onSeeAllRequests: () => setState(() => _index = 1),
        onOpenMap: () => setState(() => _index = 2),
        onVolunteerTab: (i) => setState(() => _index = i),
      ),
      const VolunteerRequestsTab(),
      const VolunteerMapTab(),
      const VolunteerImpactTab(),
      const VolunteerProfileTab(),
    ];

    return Scaffold(
      backgroundColor: VolunteerTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
                child: Image.asset(
                  'assets/bridgecare_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _titles[_index],
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: VolunteerTheme.brandPrimary,
                    ),
                  ),
                  const Text(
                    'BridgeCare Volunteer',
                    style: TextStyle(
                      fontSize: 12,
                      color: VolunteerTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: VolunteerStore.instance,
            builder: (context, _) {
              final s = VolunteerStore.instance;
              return GestureDetector(
                onTap: s.toggleAvailability,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: s.isAvailableNow
                        ? VolunteerTheme.brandAccent
                        : VolunteerTheme.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: s.isAvailableNow
                          ? Colors.transparent
                          : VolunteerTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        s.isAvailableNow
                            ? Icons.toggle_on_rounded
                            : Icons.toggle_off_rounded,
                        color: s.isAvailableNow
                            ? Colors.white
                            : VolunteerTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s.isAvailableNow ? 'On duty' : 'Off duty',
                        style: TextStyle(
                          color: s.isAvailableNow
                              ? Colors.white
                              : VolunteerTheme.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: tabs[_index],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F0F2540),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (v) => setState(() => _index = v),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: VolunteerTheme.brandPrimary,
            unselectedItemColor: const Color(0xFF9AA9B7),
            selectedFontSize: 12,
            unselectedFontSize: 11.5,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_outlined),
                activeIcon: Icon(Icons.list_alt_rounded),
                label: 'Requests',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map_rounded),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.workspace_premium_outlined),
                activeIcon: Icon(Icons.workspace_premium_rounded),
                label: 'Impact',
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
    );
  }
}
