import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/subscription_model.dart';
import '../../models/user_model.dart';
import '../../services/payment_service.dart';
import '../../services/premium_service.dart';
import 'payment_success_screen.dart';
import 'presentation_checkout_screen.dart';

enum PaymentUiState { idle, processing, failed }

/// Real Stripe Checkout — card is entered on Stripe only.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.planTitle,
    required this.amountLabel,
    required this.amountUsd,
    required this.billingCycle,
    required this.benefitSummary,
    required this.role,
  });

  final UserRole role;
  final String planTitle;
  final String amountLabel;
  final double amountUsd;
  final BillingCycle billingCycle;
  final List<String> benefitSummary;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _primary = Color(0xFF1B74E4);
  static const _purple = Color(0xFF7C3AED);
  static const _bg = Color(0xFFF5F8FC);

  PaymentUiState _state = PaymentUiState.idle;
  String? _errorMessage;
  bool _awaitingReturn = false;
  String? _pendingSessionId;

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  Future<void> _onSuccess() async {
    final ok = await PremiumService.instance.refreshFromServer(retries: 6);
    if (!ok || !PremiumService.instance.isPremium) {
      if (!mounted) return;
      setState(() {
        _state = PaymentUiState.failed;
        _errorMessage =
            'Payment received but subscription is still syncing. '
            'Wait a moment and tap "I completed payment".';
      });
      return;
    }
    if (!mounted) return;
    final done = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSuccessScreen(
          role: widget.role,
          planTitle: widget.planTitle,
        ),
      ),
    );
    if (!mounted) return;
    if (done == true) Navigator.pop(context, true);
  }

  Future<void> _pay() async {
    setState(() {
      _state = PaymentUiState.processing;
      _errorMessage = null;
      _awaitingReturn = _isDesktop;
      _pendingSessionId = null;
    });

    var outcome = await PaymentService.instance.startSubscriptionCheckout(
      role: widget.role,
      billingCycle: widget.billingCycle,
    );

    if (!mounted) return;

    if (outcome.result == PaymentResult.usePresentationCheckout) {
      setState(() {
        _state = PaymentUiState.idle;
        _awaitingReturn = false;
      });
      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PresentationCheckoutScreen(
            role: widget.role,
            billingCycle: widget.billingCycle,
            amountLabel: widget.amountLabel,
            planTitle: widget.planTitle,
          ),
        ),
      );
      if (!mounted) return;
      if (paid == true) {
        await _onSuccess();
      }
      return;
    }

    _pendingSessionId = outcome.pendingSessionId;

    if (outcome.result == PaymentResult.cancelled) {
      setState(() {
        _state = PaymentUiState.idle;
        _awaitingReturn = false;
      });
      return;
    }

    if (outcome.result == PaymentResult.success) {
      setState(() => _awaitingReturn = false);
      await _onSuccess();
      return;
    }

    setState(() {
      _state = PaymentUiState.failed;
      _awaitingReturn = false;
      _errorMessage = outcome.userMessage ??
          'Payment was not completed. Enter your card on Stripe and try again.';
    });
  }

  Future<void> _confirmCompleted() async {
    final sessionId = _pendingSessionId;
    if (sessionId == null) {
      setState(() => _errorMessage = 'Start checkout first.');
      return;
    }
    setState(() {
      _state = PaymentUiState.processing;
      _errorMessage = null;
    });
    final ok = await PaymentService.instance.confirmPendingSession(sessionId);
    if (!mounted) return;
    if (ok) {
      await _onSuccess();
      return;
    }
    setState(() {
      _state = PaymentUiState.failed;
      _errorMessage =
          'Still confirming payment. If you paid on Stripe, wait 10 seconds and try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Subscribe with Stripe'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _secureBanner(),
          const SizedBox(height: 16),
          _billingSummary(),
          const SizedBox(height: 16),
          _stripeInfoCard(),
          if (_awaitingReturn) ...[
            const SizedBox(height: 16),
            _waitingCard(),
          ],
          if (_state == PaymentUiState.failed && _errorMessage != null) ...[
            const SizedBox(height: 12),
            _errorBox(_errorMessage!),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _state == PaymentUiState.processing ? null : _pay,
              icon: _state == PaymentUiState.processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_rounded),
              label: Text(
                _state == PaymentUiState.processing
                    ? (_awaitingReturn
                        ? 'Complete payment in browser…'
                        : 'Opening Stripe…')
                    : 'Continue to Stripe — ${widget.amountLabel}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_pendingSessionId != null &&
              _state != PaymentUiState.processing) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _confirmCompleted,
              child: const Text('I completed payment on Stripe'),
            ),
          ],
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Powered by Stripe · Recurring billing · Cancel anytime',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _secureBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF133A63), Color(0xFF1B74E4)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'You will enter card details on Stripe. We never store your card number.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_rounded, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _billingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Billing summary',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'BridgeCare Premium',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                widget.amountLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _purple,
                ),
              ),
            ],
          ),
          Text(
            widget.planTitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const Divider(height: 20),
          ...widget.benefitSummary.take(4).map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: _primary),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(b, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _stripeInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 12),
          _step('1', 'Continue to Stripe\'s secure page'),
          _step('2', 'Enter your card (or Apple Pay / Google Pay)'),
          _step(
            '3',
            _isDesktop
                ? 'Return here automatically after payment'
                : 'Return to BridgeCare after payment',
          ),
        ],
      ),
    );
  }

  Widget _step(String n, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: _primary.withValues(alpha: 0.12),
            child: Text(
              n,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _waitingCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Waiting for you to pay in the browser…',
              style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
            ),
          ),
        ],
      ),
    );
  }
}
