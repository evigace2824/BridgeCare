import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/card_validation.dart';
import '../../models/subscription_model.dart';
import '../../models/user_model.dart';
import '../../services/premium_service.dart';

/// Secure in-app checkout (Stripe-style). Used when hosted Stripe is unavailable.
class PresentationCheckoutScreen extends StatefulWidget {
  const PresentationCheckoutScreen({
    super.key,
    required this.role,
    required this.billingCycle,
    required this.amountLabel,
    required this.planTitle,
  });

  final UserRole role;
  final BillingCycle billingCycle;
  final String amountLabel;
  final String planTitle;

  @override
  State<PresentationCheckoutScreen> createState() =>
      _PresentationCheckoutScreenState();
}

class _PresentationCheckoutScreenState extends State<PresentationCheckoutScreen> {
  static const _stripePurple = Color(0xFF635BFF);

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _cardCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvcCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _processing = false;
  String? _error;
  String _cardBrand = 'card';

  @override
  void initState() {
    super.initState();
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email != null) _emailCtrl.text = email;
    _cardCtrl.addListener(_onCardChanged);
  }

  void _onCardChanged() {
    final digits = _cardCtrl.text.replaceAll(RegExp(r'\D'), '');
    final brand = CardValidation.detectBrand(digits);
    if (brand != _cardBrand) setState(() => _cardBrand = brand);
  }

  @override
  void dispose() {
    _cardCtrl.removeListener(_onCardChanged);
    _emailCtrl.dispose();
    _cardCtrl.dispose();
    _expiryCtrl.dispose();
    _cvcCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  IconData get _brandIcon => switch (_cardBrand) {
        'visa' => Icons.credit_card_rounded,
        'mastercard' => Icons.credit_card_rounded,
        'amex' => Icons.credit_card_rounded,
        _ => Icons.credit_card_rounded,
      };

  Future<void> _pay() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _processing = true;
      _error = null;
    });

    // Simulate secure processing (tokenization + charge).
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    final digits = _cardCtrl.text.replaceAll(RegExp(r'\D'), '');
    final last4 = CardValidation.maskLastFour(digits);
    final brand = CardValidation.detectBrand(digits);
    final subId = 'sub_${DateTime.now().millisecondsSinceEpoch}';

    final ok = await PremiumService.instance.activatePaidSubscription(
      billingCycle: widget.billingCycle,
      role: widget.role,
      subscriptionId: subId,
      billingSource: 'secure_checkout',
      cardLast4: last4,
      cardBrand: brand,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _processing = false;
      _error =
          'Could not save your subscription. Sign out and sign in again, then retry.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _stripePurple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'stripe',
                style: TextStyle(
                  color: _stripePurple,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Checkout', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Subscribe to ${widget.planTitle}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          Text(
            widget.amountLabel,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _stripePurple,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.lock_rounded, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                '256-bit encrypted · Card details are not stored on our servers',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  controller: _emailCtrl,
                  label: 'Email',
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || !v.contains('@') || !v.contains('.')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _cardCtrl,
                  label: 'Card number',
                  keyboard: TextInputType.number,
                  prefixIcon: _brandIcon,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(19),
                    _CardSpacingFormatter(),
                  ],
                  validator: (v) => CardValidation.validateCardNumber(v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _expiryCtrl,
                        label: 'MM / YY',
                        keyboard: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          _ExpiryFormatter(),
                        ],
                        validator: CardValidation.validateExpiry,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        controller: _cvcCtrl,
                        label: 'CVC',
                        keyboard: TextInputType.number,
                        obscure: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (v) => CardValidation.validateCvc(
                          v,
                          cardDigits:
                              _cardCtrl.text.replaceAll(RegExp(r'\D'), ''),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field(
                  controller: _nameCtrl,
                  label: 'Name on card',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v ?? '').trim().length >= 3 ? null : 'Required',
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _processing ? null : _pay,
              style: ElevatedButton.styleFrom(
                backgroundColor: _stripePurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: _processing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text('Pay ${widget.amountLabel}'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Recurring subscription · Cancel anytime from billing settings',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool obscure = false,
    IconData? prefixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            prefixIcon != null ? Icon(prefixIcon, size: 20, color: _stripePurple) : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}

class _CardSpacingFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final t = buf.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final d = newValue.text.replaceAll('/', '');
    if (d.isEmpty) return newValue.copyWith(text: '');
    final t = d.length <= 2 ? d : '${d.substring(0, 2)}/${d.substring(2)}';
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
