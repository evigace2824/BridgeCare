import 'package:flutter/material.dart';

enum UserPlan { free, pro, premium }

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({
    super.key,
    required this.currentPlan,
    required this.onPlanSelected,
  });

  final UserPlan currentPlan;
  final void Function(UserPlan) onPlanSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            onPlanSelected(currentPlan);
            Navigator.pop(context);
          },
          child: const Text('Keep current plan'),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

enum UserPlan { free, pro, premium }

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({
    super.key,
    required this.currentPlan,
    required this.onPlanSelected,
  });

  final UserPlan currentPlan;
  final void Function(UserPlan) onPlanSelected;

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  static const _primary = Color(0xFF1976D2);
  static const _purple = Color(0xFF7C3AED);

  late UserPlan _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPlan;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Choose Your Plan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _planCard(UserPlan.free, 'Free', '\$0 / forever', const Color(0xFF6B7280), const [
            'Basic health monitoring',
            'Location tracking',
            'Basic alerts',
          ]),
          const SizedBox(height: 12),
          _planCard(UserPlan.pro, 'Pro', '\$9.99 / month', _primary, const [
            'Advanced analytics',
            'Real-time location',
            'Detailed weekly reports',
            'Priority support',
          ]),
          const SizedBox(height: 12),
          _planCard(UserPlan.premium, 'Premium', '\$19.99 / month', _purple, const [
            'Everything in Pro',
            '24/7 priority support',
            'Up to 5 linked users',
          ]),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _selected == widget.currentPlan ? null : _confirm,
            child: Text(_selected == widget.currentPlan ? 'Current plan selected' : 'Continue'),
          ),
        ],
      ),
    );
  }

  Widget _planCard(
    UserPlan plan,
    String title,
    String price,
    Color color,
    List<String> features,
  ) {
    final selected = _selected == plan;
    return GestureDetector(
      onTap: () => setState(() => _selected = plan),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : const Color(0xFFE9ECEF),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? color : const Color(0xFFADB5BD)),
              ],
            ),
            const SizedBox(height: 4),
            Text(price, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check_rounded, size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Plan Change'),
        content: const Text('Do you want to continue with this plan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok == true) {
      widget.onPlanSelected(_selected);
      if (mounted) Navigator.pop(context);
    }
  }
}
import 'package:flutter/material.dart';

enum UserPlan { free, pro, premium }

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({
    super.key,
    required this.currentPlan,
    required this.onPlanSelected,
  });

  final UserPlan currentPlan;
  final void Function(UserPlan) onPlanSelected;

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with TickerProviderStateMixin {
  static const _primary = Color(0xFF1976D2);
  static const _gold = Color(0xFFFFB300);
  static const _purple = Color(0xFF7C3AED);

  late UserPlan _selected;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPlan;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Choose Your Plan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE9ECEF)),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            children: [
              _planCard(
                plan: UserPlan.free,
                title: 'Free',
                price: '\$0',
                period: 'forever',
                color: const Color(0xFF6B7280),
                features: const [
                  'Basic health monitoring',
                  'Location tracking',
                  'Basic alerts',
                ],
              ),
              const SizedBox(height: 14),
              _planCard(
                plan: UserPlan.pro,
                title: 'Pro',
                price: '\$9.99',
                period: 'per month',
                color: _primary,
                badge: 'MOST POPULAR',
                features: const [
                  'Advanced health analytics',
                  'Real-time location',
                  'Detailed weekly reports',
                  'Priority support',
                ],
              ),
              const SizedBox(height: 14),
              _planCard(
                plan: UserPlan.premium,
                title: 'Premium',
                price: '\$19.99',
                period: 'per month',
                color: _purple,
                features: const [
                  'Everything in Pro',
                  '24/7 priority support',
                  'Up to 5 linked users',
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selected == widget.currentPlan ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selected == UserPlan.premium ? _purple : _primary,
                  ),
                  child: Text(
                    _selected == widget.currentPlan
                        ? 'Current plan selected'
                        : (_selected == UserPlan.free ? 'Downgrade to Free' : 'Continue'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planCard({
    required UserPlan plan,
    required String title,
    required String price,
    required String period,
    required Color color,
    required List<String> features,
    String? badge,
  }) {
    final selected = _selected == plan;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => setState(() => _selected = plan),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? color : const Color(0xFFE9ECEF),
                width: selected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: selected ? color.withAlpha(60) : const Color(0x12000000),
                  blurRadius: selected ? 16 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$price / $period',
                            style: TextStyle(color: color, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                      color: selected ? color : const Color(0xFFADB5BD),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.check_rounded, size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -10,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                badge,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Plan Change'),
        content: const Text('Do you want to continue with this plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (ok == true) {
      widget.onPlanSelected(_selected);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}
import 'package:flutter/material.dart';

enum UserPlan { free, pro, premium }

class SubscriptionPage extends StatefulWidget {
  final UserPlan currentPlan;
  final void Function(UserPlan) onPlanSelected;

  const SubscriptionPage({
    super.key,
    required this.currentPlan,
    required this.onPlanSelected,
  });

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> with TickerProviderStateMixin {
  static const _primary = Color(0xFF1976D2);
  static const _primaryDark = Color(0xFF1565C0);
  static const _gold = Color(0xFFFFB300);
  static const _purple = Color(0xFF7C3AED);

  late UserPlan _selected;
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPlan;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1565C0)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Choose Your Plan',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE9ECEF)),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: _primary.withAlpha(80), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Unlock the Full BridgeCare Experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Monitor your loved ones with more power and peace of mind.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ]),
              ),
              const SizedBox(height: 28),

              // Plan cards
              _planCard(
                plan: UserPlan.free,
                title: 'Free',
                price: '\$0',
                period: 'forever',
                icon: Icons.person_outline_rounded,
                color: const Color(0xFF6B7280),
                gradient: const [Color(0xFFE9ECEF), Color(0xFFF5F8FB)],
                textColor: const Color(0xFF1A1A2E),
                features: [
                  _feature(Icons.monitor_heart_outlined, 'Basic health monitoring', true, dark: false),
                  _feature(Icons.location_on_outlined, 'Location tracking', true, dark: false),
                  _feature(Icons.notifications_outlined, 'Basic alerts', true, dark: false),
                  _feature(Icons.bar_chart_outlined, 'Weekly reports', false, dark: false),
                  _feature(Icons.support_agent_rounded, 'Priority support', false, dark: false),
                  _feature(Icons.family_restroom_rounded, 'Multiple linked users', false, dark: false),
                ],
              ),
              const SizedBox(height: 16),

              // Pro - most popular
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _planCard(
                    plan: UserPlan.pro,
                    title: 'Pro',
                    price: '\$9.99',
                    period: 'per month',
                    icon: Icons.star_rounded,
                    color: _primary,
                    gradient: const [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF42A5F5)],
                    textColor: Colors.white,
                    features: [
                      _feature(Icons.monitor_heart_outlined, 'Advanced health analytics', true),
                      _feature(Icons.location_on_outlined, 'Real-time location', true),
                      _feature(Icons.notifications_active_rounded, 'Smart alerts & SOS', true),
                      _feature(Icons.bar_chart_rounded, 'Detailed weekly reports', true),
                      _feature(Icons.support_agent_rounded, 'Priority support', true),
                      _feature(Icons.family_restroom_rounded, 'Multiple linked users', false),
                    ],
                    isPro: true,
                  ),
                  Positioned(
                    top: -10,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _gold,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: _gold.withAlpha(80), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: const Text('MOST POPULAR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _planCard(
                plan: UserPlan.premium,
                title: 'Premium',
                price: '\$19.99',
                period: 'per month',
                icon: Icons.workspace_premium_rounded,
                color: _purple,
                gradient: const [Color(0xFF5B21B6), Color(0xFF7C3AED), Color(0xFFA855F7)],
                textColor: Colors.white,
                features: [
                  _feature(Icons.monitor_heart_outlined, 'Advanced health analytics', true),
                  _feature(Icons.location_on_outlined, 'Real-time location', true),
                  _feature(Icons.notifications_active_rounded, 'Smart alerts & SOS', true),
                  _feature(Icons.bar_chart_rounded, 'Detailed weekly reports', true),
                  _feature(Icons.support_agent_rounded, '24/7 Priority support', true),
                  _feature(Icons.family_restroom_rounded, 'Up to 5 linked users', true),
                ],
              ),

              const SizedBox(height: 28),

              // CTA
              if (_selected != widget.currentPlan)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: _selected == UserPlan.premium
                            ? [const Color(0xFF5B21B6), const Color(0xFFA855F7)]
                            : _selected == UserPlan.pro
                                ? [const Color(0xFF1565C0), const Color(0xFF42A5F5)]
                                : [const Color(0xFF6B7280), const Color(0xFF9CA3AF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_selected == UserPlan.premium ? _purple : _primary).withAlpha(80),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _selected == UserPlan.free ? 'Downgrade to Free' : 'Upgrade to ${_selected == UserPlan.pro ? "Pro" : "Premium"}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),

              if (_selected == widget.currentPlan)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'This is your current plan',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50)),
                      ),
                    ]),
                  ),
                ),

              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Cancel anytime • Secure payments • No hidden fees',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planCard({
    required UserPlan plan,
    required String title,
    required String price,
    required String period,
    required IconData icon,
    required Color color,
    required List<Color> gradient,
    required Color textColor,
    required List<Widget> features,
    bool isPro = false,
  }) {
    final isSelected = _selected == plan;
    final isDark = textColor == Colors.white;

    return GestureDetector(
      onTap: () => setState(() => _selected = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: isDark
              ? LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
          color: isDark ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: isSelected ? 2.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withAlpha(60) : const Color(0x12000000),
              blurRadius: isSelected ? 20 : 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(30) : color.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: isDark ? Colors.white : color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(text: price, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
                        TextSpan(text: ' / $period', style: TextStyle(fontSize: 13, color: textColor.withAlpha(180))),
                      ]),
                    ),
                  ]),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? (isDark ? Colors.white : color) : Colors.transparent,
                    border: Border.all(
                      color: isDark ? Colors.white.withAlpha(150) : color.withAlpha(150),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 14, color: isDark ? color : Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: isDark ? Colors.white.withAlpha(40) : const Color(0xFFE9ECEF), height: 1),
            const SizedBox(height: 14),
            ...features.map((f) => Padding(padding: const EdgeInsets.only(bottom: 10), child: f)),
          ],
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String label, bool included, {bool dark = true}) {
    final tc = dark ? Colors.white : const Color(0xFF1A1A2E);
    return Row(children: [
      Icon(
        included ? Icons.check_circle_rounded : Icons.cancel_rounded,
        size: 16,
        color: included ? const Color(0xFF4CAF50) : (dark ? Colors.white.withAlpha(80) : const Color(0xFFD1D5DB)),
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: included ? tc : (dark ? Colors.white.withAlpha(120) : const Color(0xFF9CA3AF)),
        ),
      ),
    ]);
  }

  Future<void> _confirm() async {
    final planName = _selected == UserPlan.premium ? 'Premium' : _selected == UserPlan.pro ? 'Pro' : 'Free';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Switch to $planName', style: const TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
        content: Text(
          _selected == UserPlan.free
              ? 'Are you sure you want to downgrade to the Free plan? You will lose access to premium features.'
              : 'You are about to switch to the $planName plan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: Text('Confirm', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      widget.onPlanSelected(_selected);
      if (mounted) Navigator.pop(context);
    }
  }
}
