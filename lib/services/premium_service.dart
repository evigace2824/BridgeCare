import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/stripe_config.dart';
import '../features/family/family_plan_store.dart';
import '../features/volunteer/data/volunteer_store.dart';
import '../models/subscription_model.dart';
import '../models/user_model.dart';

/// Central subscription state — premium only with a verified Stripe subscription.
class PremiumService extends ChangeNotifier {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  SubscriptionModel _subscription = const SubscriptionModel();
  UserRole? _role;
  bool _loaded = false;
  String? _stripeSubscriptionId;
  String? _cardLast4;
  String? _cardBrand;

  SubscriptionModel get subscription => _subscription;
  String? get stripeSubscriptionId => _stripeSubscriptionId;
  bool get isLoaded => _loaded;
  UserRole? get role => _role;

  /// True only when Stripe subscription is active (real paid plan).
  bool get isPremium {
    if (!_subscription.isPremium) return false;
    final sid = _stripeSubscriptionId;
    if (sid == null || sid.isEmpty) return false;
    return true;
  }

  bool get familyIsPremium =>
      isPremium && (_role == UserRole.family || _role == null);

  bool get volunteerIsPremium =>
      isPremium && (_role == UserRole.volunteer || _role == null);

  bool get isInAppCheckout =>
      StripeConfig.isInAppCheckoutSubscription(_stripeSubscriptionId);

  String get paymentMethodLabel {
    final brand = (_cardBrand ?? 'card').toUpperCase();
    final last4 = _cardLast4 ?? '••••';
    if (brand == 'VISA') return 'Visa •••• $last4';
    if (brand == 'MASTERCARD') return 'Mastercard •••• $last4';
    if (brand == 'AMEX') return 'Amex •••• $last4';
    return 'Card •••• $last4';
  }

  Future<void> loadForUser({UserModel? profile}) async {
    _role = profile?.role;
    _subscription = const SubscriptionModel();
    _stripeSubscriptionId = null;
    _cardLast4 = null;
    _cardBrand = null;
    _loaded = false;
    notifyListeners();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _applyToStores();
      _loaded = true;
      notifyListeners();
      return;
    }

    var loadedFromDb = false;

    try {
      final subRow = await Supabase.instance.client
          .from('subscriptions')
          .select(
            'status, plan_role, billing_cycle, current_period_end, '
            'stripe_subscription_id, cancel_at_period_end',
          )
          .eq('user_id', userId)
          .inFilter('status', ['active', 'trialing'])
          .order('current_period_end', ascending: false)
          .limit(1)
          .maybeSingle();

      if (subRow != null) {
        _subscription = _subscriptionFromRow(subRow);
        _stripeSubscriptionId = subRow['stripe_subscription_id']?.toString();
        loadedFromDb = _subscription.status == SubscriptionStatus.premium &&
            _stripeSubscriptionId != null;
      }
    } catch (e) {
      debugPrint('subscriptions table read failed (run migration 009?): $e');
    }

    if (!loadedFromDb) {
      try {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('extras')
            .eq('id', userId)
            .maybeSingle();
        if (row != null && row['extras'] is Map) {
          final extras = Map<String, dynamic>.from(row['extras'] as Map);
          _stripeSubscriptionId = extras['stripe_subscription_id']?.toString();
          if (_stripeSubscriptionId != null &&
              _stripeSubscriptionId!.isNotEmpty) {
            _subscription = SubscriptionModel.fromExtras(extras);
            _cardLast4 = extras['card_last4']?.toString();
            _cardBrand = extras['card_brand']?.toString();
          }
        }
      } catch (_) {}
    }

    // Local cache when profiles row is missing (common for volunteers on `users`).
    if (!_subscription.isPremium || _stripeSubscriptionId == null) {
      final local = await _loadLocal(userId);
      if (local != null && local.isPremium) {
        _subscription = local;
      }
    }

    // Remove stale premium with no subscription id (old demo cache).
    if (_subscription.status == SubscriptionStatus.premium &&
        (_stripeSubscriptionId == null || _stripeSubscriptionId!.isEmpty)) {
      await _clearPremiumState(userId);
    }

    _applyToStores();
    _loaded = true;
    notifyListeners();
  }

  Future<bool> refreshFromServer({UserModel? profile, int retries = 5}) async {
    for (var i = 0; i < retries; i++) {
      await loadForUser(profile: profile);
      if (isPremium) return true;
      if (i < retries - 1) {
        await Future<void>.delayed(Duration(milliseconds: 900 * (i + 1)));
      }
    }
    return isPremium;
  }

  Future<bool> hasStripeCustomer() async {
    if (isInAppCheckout) return true;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final row = await Supabase.instance.client
          .from('stripe_customers')
          .select('stripe_customer_id')
          .eq('user_id', userId)
          .maybeSingle();
      return row != null &&
          row['stripe_customer_id']?.toString().isNotEmpty == true;
    } catch (_) {
      return false;
    }
  }

  SubscriptionModel _subscriptionFromRow(Map<String, dynamic> row) {
    final statusRaw = row['status']?.toString();
    final isActive = statusRaw == 'active' || statusRaw == 'trialing';
    final cycleRaw = row['billing_cycle']?.toString();
    final cycle =
        cycleRaw == 'yearly' ? BillingCycle.yearly : BillingCycle.monthly;
    final periodEnd = row['current_period_end'];
    DateTime? expires;
    if (periodEnd is String) expires = DateTime.tryParse(periodEnd);

    final planRole = row['plan_role']?.toString();
    if (planRole == 'family') _role = UserRole.family;
    if (planRole == 'volunteer') _role = UserRole.volunteer;

    return SubscriptionModel(
      status: isActive ? SubscriptionStatus.premium : SubscriptionStatus.free,
      billingCycle: cycle,
      premiumExpiresAt: expires,
      updatedAt: DateTime.now(),
      cancelAtPeriodEnd: row['cancel_at_period_end'] == true,
    );
  }

  /// After card checkout (secure in-app or verified Stripe webhook).
  Future<bool> activatePaidSubscription({
    required BillingCycle billingCycle,
    required UserRole role,
    required String subscriptionId,
    String billingSource = 'stripe',
    String? cardLast4,
    String? cardBrand,
  }) async {
    _role = role;
    final duration = billingCycle == BillingCycle.yearly
        ? const Duration(days: 365)
        : const Duration(days: 30);
    _stripeSubscriptionId = subscriptionId;
    _cardLast4 = cardLast4;
    _cardBrand = cardBrand;
    _subscription = SubscriptionModel(
      status: SubscriptionStatus.premium,
      billingCycle: billingCycle,
      premiumExpiresAt: DateTime.now().add(duration),
      updatedAt: DateTime.now(),
    );
    _applyToStores();
    notifyListeners();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return true;

    Map<String, dynamic> extras = {..._subscription.toExtrasMap()};
    extras['stripe_subscription_id'] = subscriptionId;
    extras['billing_source'] = billingSource;
    if (cardLast4 != null) extras['card_last4'] = cardLast4;
    if (cardBrand != null) extras['card_brand'] = cardBrand;

    await _saveSubscriptionLocal(userId, role, extras);

    // Upsert profiles (volunteers often only have `users` row — create profiles if needed).
    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'role': _roleForDb(role),
        'extras': extras,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('activatePaidSubscription upsert: $e');
      try {
        await Supabase.instance.client.from('profiles').update({
          'extras': extras,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      } catch (e2) {
        debugPrint('activatePaidSubscription update: $e2');
      }
    }

    // Premium is active in memory + local cache even if remote sync lags.
    return true;
  }

  static String _roleForDb(UserRole role) {
    switch (role) {
      case UserRole.family:
        return 'family';
      case UserRole.volunteer:
        return 'volunteer';
      case UserRole.elderly:
        return 'elderly';
      case UserRole.admin:
        return 'elderly';
    }
  }

  Future<void> _saveSubscriptionLocal(
    String userId,
    UserRole role,
    Map<String, dynamic> extras,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'subscription_$userId',
        jsonEncode({
          ...extras,
          'role': role.name,
        }),
      );
    } catch (_) {}
  }

  Future<void> downgradeToFree() async {
    _subscription = const SubscriptionModel();
    _stripeSubscriptionId = null;
    _cardLast4 = null;
    _cardBrand = null;
    _applyToStores();
    notifyListeners();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await _clearPremiumState(userId);
  }

  Future<void> _clearPremiumState(String userId) async {
    _subscription = const SubscriptionModel();
    _stripeSubscriptionId = null;
    _cardLast4 = null;
    _cardBrand = null;
    await _clearLocal(userId);
    try {
      final existing = await Supabase.instance.client
          .from('profiles')
          .select('extras')
          .eq('id', userId)
          .maybeSingle();
      Map<String, dynamic> extras = {};
      if (existing != null && existing['extras'] is Map) {
        extras = Map<String, dynamic>.from(existing['extras'] as Map);
      }
      extras['subscription_status'] = 'free';
      extras.remove('premium_expires_at');
      extras.remove('stripe_subscription_id');
      extras.remove('billing_source');
      extras.remove('card_last4');
      extras.remove('card_brand');
      extras['subscription_updated_at'] = DateTime.now().toIso8601String();
      await Supabase.instance.client
          .from('profiles')
          .update({'extras': extras})
          .eq('id', userId);
    } catch (_) {}
  }

  void _applyToStores() {
    switch (_role) {
      case UserRole.family:
        FamilyPlanStore.instance.applySubscription(_subscription);
        break;
      case UserRole.volunteer:
        VolunteerStore.instance.applySubscription(_subscription);
        break;
      case null:
        FamilyPlanStore.instance.applySubscription(_subscription);
        VolunteerStore.instance.applySubscription(_subscription);
        break;
      default:
        break;
    }
  }

  Future<void> _clearLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('subscription_$userId');
    } catch (_) {}
  }

  Future<SubscriptionModel?> _loadLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('subscription_$userId');
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final sub = SubscriptionModel.fromExtras(map);
      if (!sub.isPremium) return null;
      final roleName = map['role']?.toString();
      if (roleName == 'family') _role = UserRole.family;
      if (roleName == 'volunteer') _role = UserRole.volunteer;
      _stripeSubscriptionId = map['stripe_subscription_id']?.toString();
      _cardLast4 = map['card_last4']?.toString();
      _cardBrand = map['card_brand']?.toString();
      return sub;
    } catch (_) {
      return null;
    }
  }
}
