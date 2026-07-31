/// Subscription tier for BridgeCare accounts (family & volunteer).
enum SubscriptionStatus {
  free,
  premium,
}

/// Billing cycle when on a paid plan.
enum BillingCycle {
  monthly,
  yearly,
}

/// Typed subscription state loaded from Supabase or local fallback.
class SubscriptionModel {
  const SubscriptionModel({
    this.status = SubscriptionStatus.free,
    this.billingCycle = BillingCycle.monthly,
    this.premiumExpiresAt,
    this.updatedAt,
    this.cancelAtPeriodEnd = false,
  });

  final SubscriptionStatus status;
  final BillingCycle billingCycle;
  final DateTime? premiumExpiresAt;
  final DateTime? updatedAt;
  final bool cancelAtPeriodEnd;

  bool get isPremium {
    if (status != SubscriptionStatus.premium) return false;
    if (premiumExpiresAt == null) return true;
    return premiumExpiresAt!.isAfter(DateTime.now());
  }

  bool get isFree => !isPremium;

  SubscriptionModel copyWith({
    SubscriptionStatus? status,
    BillingCycle? billingCycle,
    DateTime? premiumExpiresAt,
    DateTime? updatedAt,
    bool? cancelAtPeriodEnd,
  }) {
    return SubscriptionModel(
      status: status ?? this.status,
      billingCycle: billingCycle ?? this.billingCycle,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      updatedAt: updatedAt ?? this.updatedAt,
      cancelAtPeriodEnd: cancelAtPeriodEnd ?? this.cancelAtPeriodEnd,
    );
  }

  /// Persisted inside `public.profiles.extras` until dedicated columns exist.
  /// TODO: Add `subscription_status`, `premium_expires_at` columns to `public.users`
  /// or `public.profiles` and migrate off JSON extras.
  Map<String, dynamic> toExtrasMap() => {
        'subscription_status': status.name,
        'billing_cycle': billingCycle.name,
        if (premiumExpiresAt != null)
          'premium_expires_at': premiumExpiresAt!.toIso8601String(),
        if (updatedAt != null) 'subscription_updated_at': updatedAt!.toIso8601String(),
      };

  factory SubscriptionModel.fromExtras(Map<String, dynamic>? extras) {
    if (extras == null || extras.isEmpty) return const SubscriptionModel();
    final statusRaw = extras['subscription_status']?.toString().toLowerCase();
    final status = statusRaw == 'premium'
        ? SubscriptionStatus.premium
        : SubscriptionStatus.free;
    final cycleRaw = extras['billing_cycle']?.toString().toLowerCase();
    final cycle = cycleRaw == 'yearly' ? BillingCycle.yearly : BillingCycle.monthly;
    final expires = extras['premium_expires_at'];
    final updated = extras['subscription_updated_at'];
    return SubscriptionModel(
      status: status,
      billingCycle: cycle,
      premiumExpiresAt: expires is String ? DateTime.tryParse(expires) : null,
      updatedAt: updated is String ? DateTime.tryParse(updated) : null,
    );
  }
}
