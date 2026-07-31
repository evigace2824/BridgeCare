import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/payment_service.dart';
import '../../services/premium_service.dart';
import 'presentation_billing_sheet.dart';
import 'premium_plans_screen.dart';

Future<void> handleManageBilling(
  BuildContext context, {
  required UserRole role,
}) async {
  if (!context.mounted) return;

  if (!PremiumService.instance.isPremium) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Subscribe to Premium first to manage billing.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => PremiumPlansScreen(role: role)),
    );
    return;
  }

  if (PremiumService.instance.isInAppCheckout) {
    showPresentationBillingSheet(context);
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Opening billing portal…'),
            ],
          ),
        ),
      ),
    ),
  );

  final result = await PaymentService.instance.openManageBilling();

  if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

  if (!context.mounted) return;

  if (result == ManageBillingResult.usePresentationPortal) {
    showPresentationBillingSheet(context);
    return;
  }

  final message = switch (result) {
    ManageBillingResult.opened =>
      'Billing portal opened in your browser.',
    ManageBillingResult.noActiveSubscription =>
      'No billing account found. Complete checkout first.',
    ManageBillingResult.billingNotConfigured =>
      'Stripe portal not configured — using in-app billing for this demo.',
    ManageBillingResult.launchFailed =>
      'Could not open billing portal.',
    ManageBillingResult.usePresentationPortal => '',
  };

  if (message.isEmpty) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ),
  );

  if (result == ManageBillingResult.billingNotConfigured && context.mounted) {
    showPresentationBillingSheet(context);
  }
}
