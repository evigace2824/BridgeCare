import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/subscription_model.dart';
import '../../models/user_model.dart';
import '../../services/premium_service.dart';
import 'manage_billing_helper.dart';
import 'payment_screen.dart';

/// Modern premium plans — family or volunteer benefits.
class PremiumPlansScreen extends StatefulWidget {
  const PremiumPlansScreen({
    super.key,
    required this.role,
  });

  final UserRole role;

  @override
  State<PremiumPlansScreen> createState() => _PremiumPlansScreenState();
}

class _PremiumPlansScreenState extends State<PremiumPlansScreen>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF1B74E4);
  static const _purple = Color(0xFF7C3AED);
  static const _violet = Color(0xFF6366F1);
  static const _gold = Color(0xFFFFC107);

  BillingCycle _selectedBilling = BillingCycle.monthly;
  late final AnimationController _glowCtrl;

  bool get _isPremium => PremiumService.instance.isPremium;
  bool get _isVolunteer => widget.role == UserRole.volunteer;

  double get _monthlyUsd => _isVolunteer ? 9.99 : 19.99;
  double get _yearlyUsd => _isVolunteer ? 99.0 : 149.0;

  String get _monthlyLabel =>
      _isVolunteer ? '\$9.99' : '\$19.99';

  String get _yearlyLabel => _isVolunteer ? '\$99' : '\$149';

  int get _yearlySavePercent {
    final fullYear = _monthlyUsd * 12;
    return (((fullYear - _yearlyUsd) / fullYear) * 100).round();
  }

  List<String> get _benefits => _isVolunteer
      ? const [
          'Search radius up to 25 km',
          'Priority queue for new requests',
          '1.5× impact points',
          'Advanced impact badges',
          'Priority visibility on family job posts',
        ]
      : const [
          '48-hour job posting for linked elderly user',
          'Weekly reports & analytics',
          'Advanced alerts & full health monitoring',
          'Safe-zone / location tracking (up to 14 zones)',
          'Multiple family caregivers',
          'Priority notifications to volunteers',
        ];

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: Stack(
        children: [
          Column(
            children: [
              _holoHero(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  children: [
                    if (_isPremium) _activeBanner(),
                    _benefitsCard(),
                    const SizedBox(height: 16),
                    _planCard(
                      title: 'Basic',
                      subtitle: 'Free forever',
                      price: '\$0',
                      period: '',
                      accent: const Color(0xFF94A3B8),
                      isFree: true,
                      highlight: false,
                    ),
                    const SizedBox(height: 12),
                    _billingToggle(),
                    const SizedBox(height: 12),
                    _planCard(
                      title: 'Premium',
                      subtitle: _selectedBilling == BillingCycle.yearly
                          ? 'Best value — save $_yearlySavePercent%'
                          : 'Full access, cancel anytime',
                      price: _selectedBilling == BillingCycle.yearly
                          ? _yearlyLabel
                          : _monthlyLabel,
                      period: _selectedBilling == BillingCycle.yearly
                          ? '/year'
                          : '/month',
                      accent: _purple,
                      isFree: false,
                      highlight: true,
                      recommended: true,
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Cancel anytime · Secure encrypted checkout',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isPremium) _bottomManageBar(context) else _bottomCta(context),
        ],
      ),
    );
  }

  Widget _holoHero(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_glowCtrl.value);
        return SizedBox(
          height: top + 200,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFEEF2FF),
                      Color(0xFFE0E7FF),
                      Color(0xFFDDD6FE),
                      Color(0xFFFCE7F3),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: -30 + t * 12,
                left: -40,
                child: _glowOrb(
                  size: 160,
                  colors: [
                    const Color(0xFF22D3EE).withValues(alpha: 0.55),
                    const Color(0xFF22D3EE).withValues(alpha: 0),
                  ],
                ),
              ),
              Positioned(
                top: 20 - t * 10,
                right: -30,
                child: _glowOrb(
                  size: 140,
                  colors: [
                    const Color(0xFFA78BFA).withValues(alpha: 0.6),
                    const Color(0xFFA78BFA).withValues(alpha: 0),
                  ],
                ),
              ),
              Positioned(
                top: 90 + t * 8,
                left: MediaQuery.sizeOf(context).width * 0.35,
                child: _glowOrb(
                  size: 100,
                  colors: [
                    const Color(0xFFF472B6).withValues(alpha: 0.45),
                    const Color(0xFFF472B6).withValues(alpha: 0),
                  ],
                ),
              ),
              Positioned(
                bottom: -20,
                left: 0,
                right: 0,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFF4F7FF).withValues(alpha: 0),
                        const Color(0xFFF4F7FF),
                      ],
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, top + 4, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _glassIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.maybePop(context),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _violet.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 16,
                        color: _isVolunteer ? _purple : _gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isVolunteer ? 'Volunteer' : 'Family',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4338CA),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _violet.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _purple.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isPremium
                                  ? 'Your Premium plan'
                                  : 'BridgeCare Premium',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E1B4B),
                                letterSpacing: -0.4,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isVolunteer
                                  ? 'Level up your impact as a helper'
                                  : 'Peace of mind for your whole family',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6366F1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _glowOrb({required double size, required List<Color> colors}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white),
              ),
              child: Icon(icon, color: const Color(0xFF4338CA), size: 22),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomManageBar(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: OutlinedButton.icon(
          onPressed: () => handleManageBilling(context, role: widget.role),
          icon: const Icon(Icons.credit_card_rounded),
          label: const Text('Manage subscription & payment method'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: _purple,
            side: const BorderSide(color: _purple, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _bottomCta(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          boxShadow: [
            BoxShadow(
              color: _purple.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _startCheckout(context),
              child: Ink(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      _selectedBilling == BillingCycle.yearly
                          ? 'Subscribe yearly · $_yearlyLabel'
                          : 'Subscribe monthly · $_monthlyLabel',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _activeBanner() {
    final exp = PremiumService.instance.subscription.premiumExpiresAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium active',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  exp != null
                      ? 'Renews ${exp.toLocal().toString().split(' ').first}'
                      : 'All premium features unlocked',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
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

  Widget _benefitsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF5)),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: 0.06),
            blurRadius: 20,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 18, color: _violet),
              ),
              const SizedBox(width: 10),
              Text(
                _isVolunteer
                    ? 'Volunteer Premium perks'
                    : 'Family Premium perks',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 14, color: _primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF334155),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billingToggle() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF5)),
      ),
      child: Row(
        children: [
          Expanded(child: _toggleChip('Monthly', BillingCycle.monthly)),
          Expanded(child: _toggleChip('Yearly', BillingCycle.yearly)),
        ],
      ),
    );
  }

  Widget _toggleChip(String label, BillingCycle cycle) {
    final on = _selectedBilling == cycle;
    return GestureDetector(
      onTap: () => setState(() => _selectedBilling = cycle),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: on
              ? const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6366F1)],
                )
              : null,
          color: on ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: _purple.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: on ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            if (cycle == BillingCycle.yearly && on) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '-$_yearlySavePercent%',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _planCard({
    required String title,
    required String subtitle,
    required String price,
    required String period,
    required Color accent,
    required bool isFree,
    required bool highlight,
    bool recommended = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlight ? accent : const Color(0xFFE8EDF5),
          width: highlight ? 2 : 1,
        ),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isFree ? 0.08 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isFree
                  ? Icons.person_outline_rounded
                  : Icons.workspace_premium_rounded,
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    if (recommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              accent.withValues(alpha: 0.15),
                              accent.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'POPULAR',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: accent,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: accent,
                  letterSpacing: -0.5,
                ),
              ),
              if (period.isNotEmpty)
                Text(
                  period,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _startCheckout(BuildContext context) async {
    final yearly = _selectedBilling == BillingCycle.yearly;
    final monthlyStr = _monthlyUsd.toStringAsFixed(2);
    final yearlyStr = _yearlyUsd == _yearlyUsd.roundToDouble()
        ? _yearlyUsd.toStringAsFixed(0)
        : _yearlyUsd.toStringAsFixed(2);
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          planTitle: yearly ? 'Premium Yearly' : 'Premium Monthly',
          amountLabel: yearly
              ? '\$$yearlyStr/year'
              : '\$$monthlyStr/month',
          amountUsd: yearly ? _yearlyUsd : _monthlyUsd,
          billingCycle: _selectedBilling,
          benefitSummary: _benefits,
          role: widget.role,
        ),
      ),
    );
    if (ok == true && context.mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Premium activated — your dashboard is unlocked!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
