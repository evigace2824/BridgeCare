import 'package:flutter/material.dart';

import '../../services/premium_service.dart';

/// Billing management for in-app checkout subscriptions.
void showPresentationBillingSheet(BuildContext context) {
  final premium = PremiumService.instance;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Billing & subscription',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            premium.subscription.cancelAtPeriodEnd
                ? 'Cancels at end of billing period'
                : 'Manage your plan and payment method',
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.credit_card_rounded, color: Color(0xFF635BFF)),
            title: const Text('Payment method'),
            subtitle: Text(premium.paymentMethodLabel),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF635BFF)),
            title: const Text('BridgeCare Premium'),
            subtitle: Text(
              premium.subscription.billingCycle.name == 'yearly'
                  ? 'Yearly · ${premium.subscription.premiumExpiresAt != null ? _formatDate(premium.subscription.premiumExpiresAt!) : ''}'
                  : 'Monthly · renews automatically',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await PremiumService.instance.downgradeToFree();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subscription cancelled.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFDC2626)),
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Cancel subscription'),
          ),
        ],
      ),
    ),
  );
}

String _formatDate(DateTime d) =>
    'Renews ${d.month}/${d.day}/${d.year}';
