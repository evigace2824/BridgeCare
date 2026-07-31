import 'package:flutter/material.dart';

import 'data/volunteer_store.dart';
import 'widgets/volunteer_theme.dart';

/// Subscription / "go premium" screen for volunteers.
///
/// Tiers:
///   • Helper (free)            — basic, no cap on the public-good features.
///   • Active Helper (Plus)     — priority queue, wider radius, weekly report.
///   • Trusted Hero (Pro)       — first-pick on SOS, 1.5× points, expense
///     tracking, exclusive certifications, year-end donation receipt.
class VolunteerSubscriptionPage extends StatefulWidget {
  const VolunteerSubscriptionPage({super.key});

  @override
  State<VolunteerSubscriptionPage> createState() =>
      _VolunteerSubscriptionPageState();
}

class _VolunteerSubscriptionPageState extends State<VolunteerSubscriptionPage>
    with TickerProviderStateMixin {
  static const _navy = Color(0xFF133A63);
  static const _teal = Color(0xFF24B6A8);
  static const _violet = Color(0xFF7C4DFF);
  static const _gold = Color(0xFFFFB300);

  late VolunteerPlan _selected;
  bool _yearly = false;
  bool _processing = false;

  // Checkout form
  final _formKey = GlobalKey<FormState>();
  final _cardholderCtrl = TextEditingController();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  late final AnimationController _heroAnim;

  @override
  void initState() {
    super.initState();
    _selected = VolunteerStore.instance.currentPlan;
    _yearly = VolunteerStore.instance.isYearlyBilling;
    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _cardholderCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _heroAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = VolunteerStore.instance;
    return Scaffold(
      backgroundColor: VolunteerTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHero(),
                const SizedBox(height: 16),
                _buildBillingToggle(),
                const SizedBox(height: 16),
                _buildPlanCard(
                  plan: VolunteerPlan.helper,
                  title: 'Helper',
                  tagline: 'Volunteer the basics, free forever',
                  monthly: 0,
                  yearly: 0,
                  gradient: const [Color(0xFF8B97A8), Color(0xFFB6C0CD)],
                  icon: Icons.volunteer_activism_rounded,
                  perks: const [
                    _Perk(Icons.search_rounded, 'See open requests within 5 km'),
                    _Perk(Icons.task_alt_rounded, 'Up to 3 active tasks at once'),
                    _Perk(Icons.chat_bubble_outline_rounded,
                        'In-app chat with families'),
                    _Perk(Icons.emoji_events_outlined,
                        'Earn impact points & badges'),
                  ],
                ),
                const SizedBox(height: 14),
                _buildPlanCard(
                  plan: VolunteerPlan.plus,
                  title: 'Active Helper',
                  tagline: 'Show up first. Help more often.',
                  monthly: 4.99,
                  yearly: 39,
                  gradient: const [Color(0xFF1A6BD8), Color(0xFF24B6A8)],
                  icon: Icons.bolt_rounded,
                  badge: 'MOST POPULAR',
                  perks: const [
                    _Perk(Icons.flash_on_rounded,
                        '30-second priority queue on new requests'),
                    _Perk(Icons.explore_rounded, 'Search radius up to 15 km'),
                    _Perk(Icons.task_alt_rounded,
                        'Unlimited concurrent active tasks'),
                    _Perk(Icons.bar_chart_rounded,
                        'Weekly impact report & shareable card'),
                    _Perk(Icons.event_available_rounded,
                        'Recurring availability slots'),
                    _Perk(Icons.star_rounded,
                        '1.25× impact points · faster level-up'),
                    _Perk(Icons.verified_rounded,
                        'Plus badge on your leaderboard entry'),
                    _Perk(Icons.block_rounded, 'Ad-free experience'),
                  ],
                ),
                const SizedBox(height: 14),
                _buildPlanCard(
                  plan: VolunteerPlan.pro,
                  title: 'Trusted Hero',
                  tagline: 'For volunteers who do this every week',
                  monthly: 9.99,
                  yearly: 79,
                  gradient: const [Color(0xFF5B21B6), Color(0xFFA855F7)],
                  icon: Icons.workspace_premium_rounded,
                  perks: const [
                    _Perk(Icons.bolt_rounded,
                        'First-match on SOS / emergency requests'),
                    _Perk(Icons.explore_rounded, 'Search radius up to 25 km'),
                    _Perk(Icons.trending_up_rounded,
                        '1.5× impact points & streak bonuses'),
                    _Perk(Icons.shield_rounded,
                        'Verified Pro badge shown to families'),
                    _Perk(Icons.school_rounded,
                        'CPR & mental-health first-aid courses'),
                    _Perk(Icons.receipt_long_rounded,
                        'Mileage & expense tracker (PDF export)'),
                    _Perk(Icons.card_giftcard_rounded,
                        'Year-end donation tax receipt'),
                    _Perk(Icons.support_agent_rounded,
                        'Dedicated concierge support'),
                    _Perk(Icons.fast_forward_rounded,
                        'Early access to new features'),
                  ],
                ),
                const SizedBox(height: 22),
                _buildCta(s),
                const SizedBox(height: 12),
                _buildLegal(),
                const SizedBox(height: 18),
                _buildFaq(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sliver app bar with gradient hero ────────────────────────────────

  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      backgroundColor: _navy,
      foregroundColor: Colors.white,
      expandedHeight: 110,
      title: const Text(
        'Volunteer Premium',
        style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_navy, Color(0xFF1F5DA0), _teal],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _heroAnim, curve: Curves.easeOutBack),
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF133A63), Color(0xFF1F5DA0), Color(0xFF24B6A8)],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.30),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: _gold,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Do more good. Get more recognition.',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      height: 1.15,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Premium funds new volunteer training and grows the community.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Monthly / Yearly toggle ──────────────────────────────────────────

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VolunteerTheme.border),
      ),
      child: Row(
        children: [
          Expanded(child: _toggleBtn('Monthly', !_yearly, () => _setYearly(false))),
          Expanded(
            child: _toggleBtn(
              'Yearly · save 35%',
              _yearly,
              () => _setYearly(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: active ? VolunteerTheme.heroGradient : null,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : VolunteerTheme.textSecondary,
            fontSize: 13.5,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  void _setYearly(bool v) {
    setState(() => _yearly = v);
  }

  // ─── Plan card ─────────────────────────────────────────────────────────

  Widget _buildPlanCard({
    required VolunteerPlan plan,
    required String title,
    required String tagline,
    required double monthly,
    required double yearly,
    required List<Color> gradient,
    required IconData icon,
    required List<_Perk> perks,
    String? badge,
  }) {
    final selected = _selected == plan;
    final current = VolunteerStore.instance.currentPlan == plan;
    final price = _yearly ? yearly : monthly;
    final periodLabel = monthly == 0
        ? 'forever'
        : (_yearly ? 'per year' : 'per month');
    final priceLabel = monthly == 0 ? '\$0' : '\$${price.toStringAsFixed(2)}';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => setState(() => _selected = plan),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: gradient.last.withValues(alpha: selected ? 0.40 : 0.18),
                  blurRadius: selected ? 24 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 19,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            tagline,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.25),
                      ),
                      child: selected
                          ? Icon(
                              Icons.check_rounded,
                              color: gradient.last,
                              size: 18,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        periodLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (current) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'CURRENT',
                            style: TextStyle(
                              color: gradient.last,
                              fontWeight: FontWeight.w900,
                              fontSize: 9.5,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.20),
                ),
                const SizedBox(height: 12),
                ...perks.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(p.icon, color: Colors.white, size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            p.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.2,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
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
        ),
        if (badge != null)
          Positioned(
            top: -10,
            right: 18,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.50),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Confirm / Pay button ──────────────────────────────────────────────

  Widget _buildCta(VolunteerStore s) {
    final current = s.currentPlan;
    final yearlyMatches = s.isYearlyBilling == _yearly;
    final isCurrent = current == _selected && yearlyMatches;
    final downgrade = _selected.index < current.index;

    final label = _processing
        ? 'Processing…'
        : isCurrent
            ? 'You\'re on this plan'
            : downgrade
                ? 'Downgrade to ${_selected.shortName}'
                : _selected == VolunteerPlan.helper
                    ? 'Continue with Free'
                    : 'Activate ${_selected.shortName}';

    final gradient = switch (_selected) {
      VolunteerPlan.helper => const [Color(0xFF8B97A8), Color(0xFFB6C0CD)],
      VolunteerPlan.plus => const [Color(0xFF1A6BD8), Color(0xFF24B6A8)],
      VolunteerPlan.pro => const [Color(0xFF5B21B6), Color(0xFFA855F7)],
    };

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: isCurrent
                ? const [Color(0xFFCBD5E0), Color(0xFFE2E8F0)]
                : gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: isCurrent
              ? null
              : [
                  BoxShadow(
                    color: gradient.last.withValues(alpha: 0.40),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton.icon(
          onPressed: isCurrent || _processing ? null : _handleActivate,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: VolunteerTheme.textSecondary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          icon: _processing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  isCurrent
                      ? Icons.check_circle_rounded
                      : Icons.flash_on_rounded,
                ),
          label: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegal() {
    return const Center(
      child: Text(
        'Cancel anytime · Secure checkout · Pricing in USD',
        style: TextStyle(
          color: VolunteerTheme.textSecondary,
          fontSize: 11.5,
        ),
      ),
    );
  }

  // ─── FAQ ──────────────────────────────────────────────────────────────

  Widget _buildFaq() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: VolunteerTheme.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.question_answer_rounded, color: _violet),
              SizedBox(width: 8),
              Text(
                'Frequently asked',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: VolunteerTheme.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _FaqItem(
            q: 'Can I still volunteer for free?',
            a:
                'Yes. The Helper plan is free forever and includes everything needed to do good in your neighborhood.',
          ),
          _FaqItem(
            q: 'How do I cancel?',
            a:
                'Open Profile → Plan and switch back to Helper anytime. Your perks stay active until the period you already paid for ends.',
          ),
          _FaqItem(
            q: 'What does the money pay for?',
            a:
                'Premium funds volunteer training programs, background-check renewals, and grows the BridgeCare community.',
          ),
          _FaqItem(
            q: 'Is my payment secure?',
            a:
                'Payments are processed by industry-standard providers. We never store your full card number on our servers.',
          ),
        ],
      ),
    );
  }

  // ─── Activate / checkout flow ──────────────────────────────────────────

  Future<void> _handleActivate() async {
    if (_selected == VolunteerPlan.helper) {
      await _commitPlan();
      return;
    }
    final ok = await _showCheckoutSheet();
    if (ok == true) {
      await _commitPlan();
    }
  }

  Future<bool?> _showCheckoutSheet() {
    final amount = _yearly
        ? (_selected == VolunteerPlan.pro ? '\$79.00 / year' : '\$39.00 / year')
        : (_selected == VolunteerPlan.pro
            ? '\$9.99 / month'
            : '\$4.99 / month');
    _cardholderCtrl.clear();
    _cardNumberCtrl.clear();
    _expiryCtrl.clear();
    _cvvCtrl.clear();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: _navy),
                    const SizedBox(width: 8),
                    const Text(
                      'Secure checkout',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _teal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        amount,
                        style: const TextStyle(
                          color: _teal,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cardholderCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Cardholder name',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 3)
                          ? 'Enter the name on the card'
                          : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cardNumberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Card number',
                    prefixIcon: Icon(Icons.credit_card_rounded),
                    hintText: '1234 5678 9012 3456',
                  ),
                  validator: (v) {
                    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    return digits.length < 13 ? 'Enter a valid card number' : null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryCtrl,
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'MM/YY',
                          prefixIcon: Icon(Icons.calendar_month_rounded),
                        ),
                        validator: (v) =>
                            RegExp(r'^\d{2}/\d{2}$').hasMatch(v ?? '')
                                ? null
                                : 'MM/YY',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvCtrl,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          prefixIcon: Icon(Icons.shield_rounded),
                        ),
                        validator: (v) =>
                            RegExp(r'^\d{3,4}$').hasMatch(v ?? '')
                                ? null
                                : 'CVV',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selected == VolunteerPlan.pro
                          ? _violet
                          : _navy,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (_formKey.currentState?.validate() != true) return;
                      Navigator.pop(ctx, true);
                    },
                    icon: const Icon(Icons.payment_rounded),
                    label: const Text(
                      'Pay now',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        size: 14, color: VolunteerTheme.textSecondary),
                    SizedBox(width: 6),
                    Text(
                      '256-bit encryption · PCI-DSS compliant',
                      style: TextStyle(
                        color: VolunteerTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _commitPlan() async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    VolunteerStore.instance.setPlan(_selected, yearly: _yearly);
    setState(() => _processing = false);
    await _showSuccess();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _showSuccess() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _selected == VolunteerPlan.pro
                      ? const [Color(0xFF5B21B6), Color(0xFFA855F7)]
                      : _selected == VolunteerPlan.plus
                          ? const [Color(0xFF1A6BD8), Color(0xFF24B6A8)]
                          : const [Color(0xFF8B97A8), Color(0xFFB6C0CD)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _selected == VolunteerPlan.helper
                  ? 'Switched to Helper'
                  : 'Welcome to ${_selected.name}!',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selected == VolunteerPlan.helper
                  ? 'Premium perks expire at the end of your billing period.'
                  : 'Your perks are active right now. Go help someone today.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: VolunteerTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ─── Local helpers ────────────────────────────────────────────────────────

class _Perk {
  const _Perk(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _FaqItem extends StatelessWidget {
  const _FaqItem({required this.q, required this.a});
  final String q;
  final String a;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.2,
              color: VolunteerTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            a,
            style: const TextStyle(
              fontSize: 12.5,
              color: VolunteerTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
