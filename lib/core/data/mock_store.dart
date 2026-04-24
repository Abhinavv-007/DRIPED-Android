import 'dart:math';

import 'package:uuid/uuid.dart';

import '../models/app_category.dart';
import '../models/app_user.dart';
import '../models/billing_cycle.dart';
import '../models/payment_history_entry.dart';
import '../models/payment_method.dart';
import '../models/subscription.dart';
import '../theme/category_palette.dart';

/// In-memory mock data for Phase A.
/// Phase C: replaced by an API-backed repository that hits the Worker.
class MockStore {
  MockStore._();
  static final MockStore instance = MockStore._();

  static const _uuid = Uuid();
  static final _rng = Random(42); // deterministic demo data

  late AppUser user;
  late List<AppCategory> categories;
  late List<PaymentMethod> paymentMethods;
  late List<Subscription> subscriptions;
  late List<PaymentHistoryEntry> history;

  bool _seeded = false;

  void seed() {
    if (_seeded) return;
    _seeded = true;

    user = AppUser(
      id: 'mock-user-1',
      email: 'you@driped.app',
      fullName: 'Abhinav',
      avatarUrl: null,
      currency: 'INR',
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
    );

    categories = CategoryPalette.defaults
        .map((p) => AppCategory(
              id: 'cat_${p.slug}',
              userId: user.id,
              name: p.name,
              slug: p.slug,
              colour: p.colour,
              iconName: p.icon.codePoint.toString(),
              budgetLimit: _defaultBudgets[p.slug],
              isDefault: true,
            ))
        .toList();

    paymentMethods = [
      PaymentMethod(
        id: 'pm_hdfc',
        userId: user.id,
        name: 'HDFC Millennia',
        type: PaymentMethodType.creditCard,
        iconSlug: 'visa',
        lastFour: '4182',
        expiryMonth: 8,
        expiryYear: 2028,
        isDefault: true,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
      PaymentMethod(
        id: 'pm_icici',
        userId: user.id,
        name: 'ICICI Amazon Pay',
        type: PaymentMethodType.creditCard,
        iconSlug: 'amazonpay',
        lastFour: '0914',
        expiryMonth: 4,
        expiryYear: 2027,
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      PaymentMethod(
        id: 'pm_gpay',
        userId: user.id,
        name: 'Google Pay UPI',
        type: PaymentMethodType.gpay,
        iconSlug: 'gpay',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      PaymentMethod(
        id: 'pm_paypal',
        userId: user.id,
        name: 'PayPal',
        type: PaymentMethodType.paypal,
        iconSlug: 'paypal',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
    ];

    subscriptions = _seedSubs();
    history = _seedHistory(subscriptions);
  }

  List<Subscription> _seedSubs() {
    final now = DateTime.now();
    DateTime d(int offsetDays) => now.add(Duration(days: offsetDays));

    List<Subscription> s = [
      _sub(
        slug: 'netflix', name: 'Netflix',
        amount: 649, cycle: BillingCycle.monthly, category: 'entertainment',
        renewal: d(3), pm: 'pm_hdfc',
      ),
      _sub(
        slug: 'spotify', name: 'Spotify',
        amount: 119, cycle: BillingCycle.monthly, category: 'music',
        renewal: d(12), pm: 'pm_hdfc',
        trial: true, trialEnd: d(2),
      ),
      _sub(
        slug: 'notion', name: 'Notion',
        amount: 10, currency: 'USD', cycle: BillingCycle.monthly,
        category: 'productivity', renewal: d(18), pm: 'pm_paypal',
      ),
      _sub(
        slug: 'github_pro', name: 'GitHub Pro',
        amount: 4, currency: 'USD', cycle: BillingCycle.monthly,
        category: 'development', renewal: d(6), pm: 'pm_paypal',
      ),
      _sub(
        slug: 'chatgpt_plus', name: 'ChatGPT Plus',
        amount: 20, currency: 'USD', cycle: BillingCycle.monthly,
        category: 'development', renewal: d(9), pm: 'pm_paypal',
      ),
      _sub(
        slug: 'adobe_cc', name: 'Adobe Creative Cloud',
        amount: 5290, cycle: BillingCycle.monthly,
        category: 'productivity', renewal: d(1), pm: 'pm_icici',
      ),
      _sub(
        slug: 'swiggy_one', name: 'Swiggy One',
        amount: 299, cycle: BillingCycle.quarterly,
        category: 'shopping', renewal: d(21), pm: 'pm_icici',
      ),
      _sub(
        slug: 'amazon_prime', name: 'Amazon Prime',
        amount: 1499, cycle: BillingCycle.yearly,
        category: 'entertainment', renewal: d(42), pm: 'pm_icici',
      ),
      _sub(
        slug: 'figma', name: 'Figma',
        amount: 12, currency: 'USD', cycle: BillingCycle.monthly,
        category: 'productivity', renewal: d(15), pm: 'pm_paypal',
      ),
      _sub(
        slug: 'canva', name: 'Canva Pro',
        amount: 499, cycle: BillingCycle.monthly,
        category: 'productivity', renewal: d(8), pm: 'pm_hdfc',
      ),
      _sub(
        slug: 'youtube_premium', name: 'YouTube Premium',
        amount: 189, cycle: BillingCycle.monthly,
        category: 'entertainment', renewal: d(5), pm: 'pm_gpay',
      ),
      _sub(
        slug: 'headspace', name: 'Headspace',
        amount: 69, currency: 'USD', cycle: BillingCycle.yearly,
        category: 'health_fitness', renewal: d(170), pm: 'pm_paypal',
        ghost: true, // example graveyard sub
      ),
      _sub(
        slug: 'dropbox', name: 'Dropbox',
        amount: 11.99, currency: 'USD', cycle: BillingCycle.monthly,
        category: 'productivity', renewal: d(-3),
        status: SubscriptionStatus.paused, pm: 'pm_paypal',
      ),
    ];
    return s;
  }

  Subscription _sub({
    required String slug,
    required String name,
    required double amount,
    String currency = 'INR',
    required BillingCycle cycle,
    required String category,
    required DateTime renewal,
    String? pm,
    bool trial = false,
    DateTime? trialEnd,
    bool ghost = false,
    SubscriptionStatus status = SubscriptionStatus.active,
  }) {
    final id = _uuid.v4();
    return Subscription(
      id: id,
      userId: user.id,
      serviceName: name,
      serviceSlug: slug,
      categoryId: 'cat_$category',
      amount: amount,
      currency: currency,
      billingCycle: cycle,
      startDate: renewal.subtract(Duration(days: cycle.periodDays)),
      nextRenewalDate: renewal,
      trialEndDate: trialEnd,
      isTrial: trial,
      status: trial ? SubscriptionStatus.trial : status,
      paymentMethodId: pm,
      notes: null,
      source: SubscriptionSource.manual,
      lastEmailDetectedAt: ghost
          ? DateTime.now().subtract(const Duration(days: 92))
          : DateTime.now().subtract(Duration(days: 4 + _rng.nextInt(10))),
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      updatedAt: DateTime.now(),
    );
  }

  List<PaymentHistoryEntry> _seedHistory(List<Subscription> subs) {
    final out = <PaymentHistoryEntry>[];
    final now = DateTime.now();
    for (final sub in subs) {
      if (sub.status == SubscriptionStatus.paused) continue;
      for (int i = 1; i <= 6; i++) {
        final charge = sub.nextRenewalDate == null
            ? now.subtract(Duration(days: sub.billingCycle.periodDays * i))
            : sub.nextRenewalDate!.subtract(
                Duration(days: sub.billingCycle.periodDays * i));
        if (charge.isAfter(now)) continue;
        out.add(PaymentHistoryEntry(
          id: _uuid.v4(),
          userId: user.id,
          subscriptionId: sub.id,
          amount: sub.amount,
          currency: sub.currency,
          chargedAt: charge,
          emailSubject: 'Payment receipt — ${sub.serviceName}',
          paymentMethodHint: sub.paymentMethodId,
        ));
      }
    }
    out.sort((a, b) => b.chargedAt.compareTo(a.chargedAt));
    return out;
  }

  static const _defaultBudgets = <String, double>{
    'entertainment': 1500,
    'music': 500,
    'productivity': 2500,
    'development': 3000,
    'shopping': 1000,
  };
}
