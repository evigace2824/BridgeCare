import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_theme.dart';
import '../../../core/i18n/app_i18n.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/heart_rate_notification_service.dart';
import '../../../utils/care_bridge_layout.dart';
import 'data/patient_store.dart';
import 'tabs/health_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/reminders_tab.dart';

/// Top-level shell for the patient dashboard.
/// 4 tabs: Home · Reminders · Health · Profile
class PatientHomeShell extends StatefulWidget {
  const PatientHomeShell({super.key});

  @override
  State<PatientHomeShell> createState() => _PatientHomeShellState();
}

class _PatientHomeShellState extends State<PatientHomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  UserModel? _profile;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HeartRateNotificationService.instance.initialize();
    _loadProfile();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    PatientStore.instance.handleAppLifecycle(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final p = await AuthService.instance.getCurrentUserProfile();
    await PatientStore.instance.refreshFamilyConnection();
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loadingProfile = false;
    });
  }

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeTab(
        profile: _profile,
        onOpenReminders: () => _go(1),
        onOpenHealth: () => _go(2),
      ),
      const RemindersTab(),
      const HealthTab(),
      ProfileTab(profile: _profile),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loadingProfile
          ? const _ShellLoading()
          : ListenableBuilder(
              listenable: PatientStore.instance,
              builder: (context, _) {
                final mq = MediaQuery.of(context);
                final store = PatientStore.instance;
                final effectiveScale = store.biggerTextMode
                    ? (store.textScale < 1.4 ? 1.4 : store.textScale)
                    : store.textScale;
                final theme = Theme.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    textScaler: TextScaler.linear(
                      effectiveScale,
                    ),
                  ),
                  child: Theme(
                    data: store.highContrastMode
                        ? theme.copyWith(
                            cardColor: Colors.white,
                            scaffoldBackgroundColor: Colors.white,
                            textTheme: theme.textTheme.apply(
                              bodyColor: Colors.black,
                              displayColor: Colors.black,
                            ),
                          )
                        : theme,
                    child: ColorFiltered(
                      colorFilter: store.highContrastMode
                          ? const ColorFilter.matrix(<double>[
                              1.35, 0, 0, 0, -25,
                              0, 1.35, 0, 0, -25,
                              0, 0, 1.35, 0, -25,
                              0, 0, 0, 1, 0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                      child: IndexedStack(index: _index, children: tabs),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onChanged: _go,
      ),
    );
  }
}

class _ShellLoading extends StatelessWidget {
  const _ShellLoading();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/bridgecare_logo.png',
              height: 56,
              semanticLabel: 'BridgeCare',
            ),
            const SizedBox(height: 16),
            Text(
              'BridgeCare',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Loading your dashboard…'),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _tabs = <_BottomTabSpec>[
    _BottomTabSpec(
      icon: Icons.home_rounded,
      iconOutlined: Icons.home_outlined,
      label: 'Home',
    ),
    _BottomTabSpec(
      icon: Icons.medication_rounded,
      iconOutlined: Icons.medication_outlined,
      label: 'Reminders',
    ),
    _BottomTabSpec(
      icon: Icons.favorite_rounded,
      iconOutlined: Icons.favorite_outline_rounded,
      label: 'Health',
    ),
    _BottomTabSpec(
      icon: Icons.person_rounded,
      iconOutlined: Icons.person_outline_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final selected = i == index;
            final t = _tabs[i];
            return Expanded(
              child: Semantics(
                selected: selected,
                label: context.tr(t.label),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onChanged(i);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      constraints: BoxConstraints(
                        minHeight: CareBridgeLayout.bottomNavTouchMinHeight,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primarySoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected ? t.icon : t.iconOutlined,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr(t.label),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              height: 1.15,
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _BottomTabSpec {
  const _BottomTabSpec({
    required this.icon,
    required this.iconOutlined,
    required this.label,
  });

  final IconData icon;
  final IconData iconOutlined;
  final String label;
}
