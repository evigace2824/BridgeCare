import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/stripe_config.dart';
import '../models/subscription_model.dart';
import '../models/user_model.dart';
import 'premium_service.dart';
import 'subscription_redirect_server.dart';

enum PaymentResult { success, failed, cancelled, usePresentationCheckout }

enum PaymentFailureReason {
  cancelled,
  verifyFailed,
  stripeNotConfigured,
  browserFailed,
  unknown,
}

enum ManageBillingResult {
  opened,
  noActiveSubscription,
  billingNotConfigured,
  launchFailed,
  usePresentationPortal,
}

class PaymentOutcome {
  const PaymentOutcome({
    required this.result,
    this.reason,
    this.userMessage,
    this.pendingSessionId,
  });

  final PaymentResult result;
  final PaymentFailureReason? reason;
  final String? userMessage;
  final String? pendingSessionId;
}

class CheckoutSession {
  const CheckoutSession({required this.url, required this.sessionId});

  final String url;
  final String sessionId;
}

class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<CheckoutSession> createCheckoutSession({
    required UserRole role,
    required BillingCycle billingCycle,
  }) async {
    final planKey = StripeConfig.planKey(role: role, billingCycle: billingCycle);
    final platform = StripeConfig.checkoutPlatform();

    final res = await _client.functions.invoke(
      'create-checkout-session',
      body: {'plan_key': planKey, 'platform': platform},
    );

    if (res.status != 200) {
      throw PaymentException(
        _extractError(res.data) ?? 'Could not start checkout (${res.status})',
      );
    }

    final data = res.data is String ? jsonDecode(res.data as String) : res.data;
    if (data is! Map) {
      throw const PaymentException('Invalid checkout response');
    }
    final url = data['url']?.toString();
    final sessionId = data['session_id']?.toString();
    if (url == null || sessionId == null) {
      throw PaymentException(
        data['error']?.toString() ?? 'Missing checkout URL',
      );
    }
    return CheckoutSession(url: url, sessionId: sessionId);
  }

  Future<PaymentOutcome> startSubscriptionCheckout({
    required UserRole role,
    required BillingCycle billingCycle,
  }) async {
    try {
      final session = await createCheckoutSession(
        role: role,
        billingCycle: billingCycle,
      );

      final platform = StripeConfig.checkoutPlatform();

      if (platform == 'desktop') {
        final sessionId = await captureSubscriptionReturnOnce(
          port: StripeConfig.subscriptionDesktopPort,
          ipv6Loopback: StripeConfig.subscriptionDesktopLocalhost,
          afterServerListening: () => _openCheckoutUrl(session.url),
        );
        if (sessionId == null) {
          return const PaymentOutcome(
            result: PaymentResult.cancelled,
            reason: PaymentFailureReason.cancelled,
          );
        }
        final verified = await _confirmPayment(sessionId);
        return PaymentOutcome(
          result: verified ? PaymentResult.success : PaymentResult.failed,
          reason: verified ? null : PaymentFailureReason.verifyFailed,
          pendingSessionId: verified ? null : sessionId,
          userMessage: verified
              ? null
              : 'Payment not confirmed yet. Finish checkout in the browser, then tap "I completed payment".',
        );
      }

      final opened = await _openCheckoutUrl(session.url);
      if (!opened) {
        return const PaymentOutcome(
          result: PaymentResult.failed,
          reason: PaymentFailureReason.browserFailed,
          userMessage: 'Could not open your browser. Set a default browser and try again.',
        );
      }

      final verified = await _confirmPayment(session.sessionId);
      return PaymentOutcome(
        result: verified ? PaymentResult.success : PaymentResult.failed,
        reason: verified ? null : PaymentFailureReason.verifyFailed,
        pendingSessionId: verified ? null : session.sessionId,
        userMessage: verified
            ? null
            : 'Complete payment in the browser, then tap "I completed payment".',
      );
    } on FunctionException catch (e) {
      debugPrint('checkout FunctionException: ${e.status} ${e.details}');
      if (!StripeConfig.stripeLiveOnly && _shouldUsePresentation(e)) {
        return const PaymentOutcome(result: PaymentResult.usePresentationCheckout);
      }
      return PaymentOutcome(
        result: PaymentResult.failed,
        reason: PaymentFailureReason.stripeNotConfigured,
        userMessage: _functionErrorMessage(e),
      );
    } on PaymentException catch (e) {
      if (!StripeConfig.stripeLiveOnly) {
        return const PaymentOutcome(result: PaymentResult.usePresentationCheckout);
      }
      return PaymentOutcome(
        result: PaymentResult.failed,
        reason: PaymentFailureReason.stripeNotConfigured,
        userMessage: e.message,
      );
    } catch (e) {
      debugPrint('checkout error: $e');
      return const PaymentOutcome(
        result: PaymentResult.failed,
        reason: PaymentFailureReason.unknown,
        userMessage: 'Something went wrong. Please try again.',
      );
    }
  }

  bool _shouldUsePresentation(FunctionException e) =>
      e.status == 404 || e.status == 500 || e.status == 502 || e.status == 503;

  Future<ManageBillingResult> openManageBilling() async {
    if (!PremiumService.instance.isPremium) {
      return ManageBillingResult.noActiveSubscription;
    }

    if (PremiumService.instance.isInAppCheckout) {
      return ManageBillingResult.usePresentationPortal;
    }

    final hasCustomer = await PremiumService.instance.hasStripeCustomer();
    if (!hasCustomer) {
      return ManageBillingResult.noActiveSubscription;
    }

    try {
      final returnUrl = StripeConfig.checkoutPlatform() == 'desktop'
          ? StripeConfig.billingPortalReturnUrl
          : 'carebridge://subscription-success';

      final res = await _client.functions.invoke(
        'create-portal-session',
        body: {'return_url': returnUrl},
      );

      if (res.status == 404 || res.status == 500) {
        return ManageBillingResult.billingNotConfigured;
      }
      if (res.status != 200) {
        return ManageBillingResult.launchFailed;
      }

      final data =
          res.data is String ? jsonDecode(res.data as String) : res.data;
      if (data is! Map) return ManageBillingResult.launchFailed;
      final url = data['url']?.toString();
      if (url == null) {
        final err = data['error']?.toString();
        if (err != null && err.contains('billing account')) {
          return ManageBillingResult.noActiveSubscription;
        }
        return ManageBillingResult.billingNotConfigured;
      }

      final opened = await _openCheckoutUrl(url);
      return opened
          ? ManageBillingResult.opened
          : ManageBillingResult.launchFailed;
    } on FunctionException catch (e) {
      debugPrint('portal FunctionException: ${e.status}');
      if (e.status == 404) return ManageBillingResult.billingNotConfigured;
      return ManageBillingResult.launchFailed;
    } catch (e) {
      debugPrint('portal error: $e');
      return ManageBillingResult.launchFailed;
    }
  }

  Future<bool> confirmPendingSession(String sessionId) =>
      _confirmPayment(sessionId);

  Future<bool> _confirmPayment(String sessionId) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      if (await verifyCheckoutSession(sessionId)) return true;
      await PremiumService.instance.refreshFromServer();
      if (PremiumService.instance.isPremium) return true;
      if (attempt < 7) {
        await Future<void>.delayed(Duration(milliseconds: 900 + attempt * 350));
      }
    }
    return false;
  }

  Future<bool> verifyCheckoutSession(String sessionId) async {
    try {
      final res = await _client.functions.invoke(
        'verify-checkout-session',
        body: {'session_id': sessionId},
      );
      if (res.status != 200) return false;
      final data =
          res.data is String ? jsonDecode(res.data as String) : res.data;
      if (data is! Map) return false;
      return data['active'] == true;
    } catch (e) {
      debugPrint('verify-checkout-session: $e');
      return false;
    }
  }

  Future<bool> _openCheckoutUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  String _functionErrorMessage(FunctionException e) {
    if (e.status == 404) {
      return 'Billing server is not set up. Deploy Supabase Edge Functions and '
          'add Stripe keys (see supabase/STRIPE_SETUP.md in the project).';
    }
    final err = e.details?.toString();
    if (err != null && err.isNotEmpty) return err;
    return 'Could not reach billing server (error ${e.status}).';
  }

  String? _extractError(dynamic data) {
    if (data is Map) return data['error']?.toString();
    if (data is String) {
      try {
        final m = jsonDecode(data);
        if (m is Map) return m['error']?.toString();
      } catch (_) {}
    }
    return null;
  }
}

class PaymentException implements Exception {
  const PaymentException(this.message);
  final String message;
  @override
  String toString() => message;
}
