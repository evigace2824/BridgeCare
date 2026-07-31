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
  static const _primary = Color(0xFF1B74E4);
  static const _purple = Color(0xFF7C3AED);
  static const _gold = Color(0xFFFFB300);
  static const _bg = Color(0xFFF5F8FC);

  late UserPlan _selected;
  bool _yearly = false;
  bool _processing = false;
  final _checkoutKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _cardholderCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.currentPlan;
  }

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _cardholderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Upgrade Plan'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: _gold),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Unlock premium caregiver features with smart alerts and advanced engagement.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: _yearly,
                  onChanged: (v) => setState(() => _yearly = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _planCard(
            plan: UserPlan.free,
            title: 'Free',
            subtitle: 'Basic family monitoring',
            price: _yearly ? '\$0/year' : '\$0/mo',
            color: const Color(0xFF6B7280),
            perks: const ['Live location', 'Chat support', 'Basic reminders'],
          ),
          const SizedBox(height: 10),
          _planCard(
            plan: UserPlan.pro,
            title: 'Pro',
            subtitle: 'Most popular for families',
            price: _yearly ? '\$79/year' : '\$9.99/mo',
            color: _primary,
            badge: 'MOST POPULAR',
            perks: const ['Priority alerts', 'Routine insights', 'Smart reminder nudges'],
          ),
          const SizedBox(height: 10),
          _planCard(
            plan: UserPlan.premium,
            title: 'Premium',
            subtitle: 'Best for multi-patient care',
            price: _yearly ? '\$149/year' : '\$19.99/mo',
            color: _purple,
            perks: const ['AI check-in insights', 'Escalation workflows', 'Up to 5 linked patients'],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _processing ? null : _activatePlan,
              icon: _processing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.flash_on_rounded),
              label: Text(_processing ? 'Processing...' : 'Activate ${_selected.name.toUpperCase()}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selected == UserPlan.premium ? _purple : _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Secure checkout • Cancel anytime',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required UserPlan plan,
    required String title,
    required String subtitle,
    required String price,
    required Color color,
    required List<String> perks,
    String? badge,
  }) {
    final selected = _selected == plan;
    return GestureDetector(
      onTap: () => setState(() => _selected = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : const Color(0xFFE5E7EB), width: selected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: selected ? color.withAlpha(40) : Colors.black.withAlpha(8),
              blurRadius: selected ? 12 : 6,
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
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(20)),
                    child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(price, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 22)),
            const SizedBox(height: 8),
            ...perks.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _activatePlan() async {
    if (_selected == UserPlan.free) {
      await _completeUpgrade();
      return;
    }
    await _openCheckout();
  }

  Future<void> _openCheckout() async {
    _cardholderCtrl.clear();
    _cardNumberCtrl.clear();
    _expiryCtrl.clear();
    _cvvCtrl.clear();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final amount = _selected == UserPlan.premium
            ? (_yearly ? '\$149.00/year' : '\$19.99/month')
            : (_yearly ? '\$79.00/year' : '\$9.99/month');
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Form(
              key: _checkoutKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lock_rounded, color: _primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Secure Checkout',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      const Spacer(),
                      Text(amount, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cardholderCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Cardholder name'),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Enter full name' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cardNumberCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Card number'),
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(' ', '');
                      return digits.length < 16 ? 'Enter a valid card number' : null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryCtrl,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(labelText: 'MM/YY'),
                          validator: (v) => RegExp(r'^\d{2}/\d{2}$').hasMatch(v ?? '')
                              ? null
                              : 'MM/YY',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'CVV'),
                          obscureText: true,
                          validator: (v) => RegExp(r'^\d{3,4}$').hasMatch(v ?? '') ? null : 'CVV',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_checkoutKey.currentState?.validate() != true) return;
                        Navigator.pop(ctx, true);
                      },
                      icon: const Icon(Icons.payment_rounded),
                      label: const Text('Pay now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected == UserPlan.premium ? _purple : _primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (ok == true) {
      await _completeUpgrade();
    }
  }

  Future<void> _completeUpgrade() async {
    setState(() => _processing = true);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    widget.onPlanSelected(_selected);
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _selected == UserPlan.free
              ? 'Switched to FREE plan.'
              : 'Payment successful. ${_selected.name.toUpperCase()} activated.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }
}
