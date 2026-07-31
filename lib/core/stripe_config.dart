import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import '../models/subscription_model.dart';
import '../models/user_model.dart';

/// Stripe + presentation checkout configuration.
class StripeConfig {
  StripeConfig._();

  static const String _stripeLiveEnv =
      String.fromEnvironment('STRIPE_LIVE', defaultValue: '');

  /// When true, only use Supabase Edge Functions + Stripe (no presentation fallback).
  static bool get stripeLiveOnly => _stripeLiveEnv == 'true';

  static const int subscriptionDesktopPort = int.fromEnvironment(
    'SUBSCRIPTION_DESKTOP_PORT',
    defaultValue: 54722,
  );

  static const bool subscriptionDesktopLocalhost = bool.fromEnvironment(
    'SUBSCRIPTION_DESKTOP_LOCALHOST',
    defaultValue: false,
  );

  static String get subscriptionDesktopHost =>
      subscriptionDesktopLocalhost ? 'localhost' : '127.0.0.1';

  static String get billingPortalReturnUrl =>
      'http://$subscriptionDesktopHost:$subscriptionDesktopPort/?portal=done';

  static String planKey({
    required UserRole role,
    required BillingCycle billingCycle,
  }) {
    final r = role == UserRole.volunteer ? 'volunteer' : 'family';
    final c = billingCycle == BillingCycle.yearly ? 'yearly' : 'monthly';
    return '${r}_$c';
  }

  static String checkoutPlatform() {
    if (kIsWeb) return 'web';
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      return 'desktop';
    }
    return 'mobile';
  }

  /// In-app secure checkout (not hosted Stripe portal).
  static bool isInAppCheckoutSubscription(String? id) =>
      id != null && (id.startsWith('sub_') || id.startsWith('pres_'));
}
