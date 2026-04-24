import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';
import '../api/repositories/category_repository.dart';
import '../api/repositories/currency_repository.dart';
import '../api/repositories/insights_repository.dart';
import '../api/repositories/payment_history_repository.dart';
import '../api/repositories/payment_method_repository.dart';
import '../api/repositories/receipt_repository.dart';
import '../api/repositories/scan_log_repository.dart';
import '../api/repositories/subscription_repository.dart';
import '../api/repositories/user_repository.dart';
import '../constants/categories_config.dart';
import '../models/app_category.dart';
import '../models/app_user.dart';
import '../models/payment_history_entry.dart';
import '../models/payment_method.dart';
import '../models/subscription.dart';
import '../utils/currency.dart';

const _uuid = Uuid();
const _categoriesCacheKey = 'categories';
const _paymentMethodsCacheKey = 'payment_methods';
const _subscriptionsCacheKey = 'subscriptions';

List<PaymentMethod> _cachedPaymentMethods(Box cache) {
  try {
    final cached = cache.get(_paymentMethodsCacheKey);
    if (cached is! List) return const [];
    return cached
        .map((e) {
          try {
            return PaymentMethod.fromMap(Map<String, dynamic>.from(e));
          } catch (_) {
            return null;
          }
        })
        .whereType<PaymentMethod>()
        .toList();
  } catch (_) {
    return const [];
  }
}

List<Subscription> _cachedSubscriptions(Box cache) {
  try {
    final cached = cache.get(_subscriptionsCacheKey);
    if (cached is! List) return const [];
    return cached
        .map((e) {
          try {
            return Subscription.fromMap(Map<String, dynamic>.from(e));
          } catch (_) {
            return null;
          }
        })
        .whereType<Subscription>()
        .toList();
  } catch (_) {
    return const [];
  }
}

List<Subscription> _sanitizeSubscriptions(List<Subscription> input) {
  final now = DateTime.now();
  final seen = <String>{};
  final sanitized = <Subscription>[];

  for (final sub in input) {
    if (sub.id.trim().isEmpty || !seen.add(sub.id)) continue;
    if (sub.serviceName.trim().isEmpty || sub.serviceSlug.trim().isEmpty)
      continue;

    final safeAmount =
        sub.amount.isFinite && sub.amount >= 0 ? sub.amount : 0.0;
    final safeCurrency =
        CurrencyUtil.supported.contains(sub.currency) ? sub.currency : 'INR';
    final safeCreatedAt = sub.createdAt.year < 2000 ? now : sub.createdAt;
    final safeUpdatedAt =
        sub.updatedAt.year < 2000 ? safeCreatedAt : sub.updatedAt;
    final safeRenewal = sub.nextRenewalDate != null &&
            sub.nextRenewalDate!.year >= 2000 &&
            sub.nextRenewalDate!.year <= now.year + 20
        ? sub.nextRenewalDate
        : null;
    final safeTrialEnd = sub.trialEndDate != null &&
            sub.trialEndDate!.year >= 2000 &&
            sub.trialEndDate!.year <= now.year + 20
        ? sub.trialEndDate
        : null;
    final safeLastEmail = sub.lastEmailDetectedAt != null &&
            sub.lastEmailDetectedAt!.year >= 2000 &&
            sub.lastEmailDetectedAt!.year <= now.year + 1
        ? sub.lastEmailDetectedAt
        : null;

    sanitized.add(
      Subscription(
        id: sub.id,
        userId: sub.userId,
        serviceName: sub.serviceName.trim(),
        serviceSlug: sub.serviceSlug.trim(),
        categoryId: sub.categoryId,
        amount: safeAmount,
        currency: safeCurrency,
        billingCycle: sub.billingCycle,
        startDate: sub.startDate,
        nextRenewalDate: safeRenewal,
        trialEndDate: safeTrialEnd,
        isTrial: sub.isTrial,
        status: sub.status,
        paymentMethodId: sub.paymentMethodId,
        notes: sub.notes,
        source: sub.source,
        lastEmailDetectedAt: safeLastEmail,
        createdAt: safeCreatedAt,
        updatedAt: safeUpdatedAt,
        remind7d: sub.remind7d,
        remind3d: sub.remind3d,
        remind1d: sub.remind1d,
      ),
    );
  }

  sanitized.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sanitized;
}

List<PaymentMethod> _sanitizePaymentMethods(List<PaymentMethod> input) {
  final seen = <String>{};
  final sanitized = <PaymentMethod>[];

  for (final pm in input) {
    if (pm.id.trim().isEmpty || !seen.add(pm.id)) continue;
    if (pm.name.trim().isEmpty) continue;

    final safeMonth = (pm.expiryMonth != null &&
            pm.expiryMonth! >= 1 &&
            pm.expiryMonth! <= 12)
        ? pm.expiryMonth
        : null;
    final safeYear = (pm.expiryYear != null &&
            pm.expiryYear! >= 2000 &&
            pm.expiryYear! <= DateTime.now().year + 30)
        ? pm.expiryYear
        : null;

    sanitized.add(
      PaymentMethod(
        id: pm.id,
        userId: pm.userId,
        name: pm.name.trim(),
        type: pm.type,
        iconSlug: pm.iconSlug,
        lastFour: pm.lastFour,
        expiryMonth: safeMonth,
        expiryYear: safeYear,
        isDefault: pm.isDefault,
        createdAt: pm.createdAt,
      ),
    );
  }

  sanitized.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sanitized;
}

List<AppCategory> _seededCategories() {
  return CategoriesConfig.defaults
      .map(
        (c) => AppCategory.fromMap({
          'id': 'cat_${c.slug}',
          'user_id': '',
          'name': c.name,
          'slug': c.slug,
          'colour_hex': c.colourHex,
          'icon_name': c.iconName,
          'is_default': 1,
        }),
      )
      .toList();
}

// ═══════════════════════════════════════
// Repository providers
// ═══════════════════════════════════════
final _cacheBoxProvider = Provider<Box>((ref) => Hive.box('driped_cache'));

final userRepoProvider = Provider<UserRepository>((ref) {
  return UserRepository(
      ref.watch(apiClientProvider), ref.watch(_cacheBoxProvider));
});
final subscriptionRepoProvider = Provider<SubscriptionRepository>((ref) {
  return SubscriptionRepository(
      ref.watch(apiClientProvider), ref.watch(_cacheBoxProvider));
});
final paymentMethodRepoProvider = Provider<PaymentMethodRepository>((ref) {
  return PaymentMethodRepository(
      ref.watch(apiClientProvider), ref.watch(_cacheBoxProvider));
});
final categoryRepoProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
      ref.watch(apiClientProvider), ref.watch(_cacheBoxProvider));
});
final paymentHistoryRepoProvider = Provider<PaymentHistoryRepository>((ref) {
  return PaymentHistoryRepository(
      ref.watch(apiClientProvider), ref.watch(_cacheBoxProvider));
});
final insightsRepoProvider = Provider<InsightsRepository>((ref) {
  return InsightsRepository(
      ref.watch(apiClientProvider), ref.watch(_cacheBoxProvider));
});
final receiptRepoProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepository(
      ref.watch(apiClientProvider), ref.watch(_cacheBoxProvider));
});

/// ─── V2 async providers ───
final savingsInsightsProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final res = await ref.watch(insightsRepoProvider).savings();
  return res.data ?? const {};
});

final forecastProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, months) async {
  final res = await ref.watch(insightsRepoProvider).forecast(months: months);
  return res.data ?? const [];
});

final calendarProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
  final res = await ref.watch(insightsRepoProvider).calendar(days: days);
  return res.data ?? const [];
});

final receiptsForSubscriptionProvider =
    FutureProvider.family<List<ReceiptRef>, String>((ref, subId) async {
  final res = await ref.watch(receiptRepoProvider).forSubscription(subId);
  return res.data ?? const [];
});
final currencyRepoProvider = Provider<CurrencyRepository>((ref) {
  return CurrencyRepository(
      ref.watch(apiClientProvider), ref.watch(_cacheBoxProvider));
});
final scanLogRepoProvider = Provider<ScanLogRepository>((ref) {
  return ScanLogRepository(ref.watch(apiClientProvider));
});

// ═══════════════════════════════════════
// User
// ═══════════════════════════════════════
final currentUserProvider = StateProvider<AppUser>((ref) {
  final cached = ref.read(userRepoProvider).getCachedUser();
  return cached.data ??
      AppUser(
        id: '',
        email: '',
        fullName: 'Demo User',
        currency: 'INR',
        createdAt: DateTime.now(),
      );
});

final preferredCurrencyProvider = StateProvider<String>((ref) {
  return ref.watch(currentUserProvider).currency;
});

// ═══════════════════════════════════════
// Categories
// ═══════════════════════════════════════
class CategoriesNotifier extends StateNotifier<List<AppCategory>> {
  final CategoryRepository _repo;
  final Box _cache;
  CategoriesNotifier(this._repo, this._cache)
      : super(_loadInitialCategories(_cache));

  static List<AppCategory> _loadInitialCategories(Box cache) {
    final cached = cache.get(_categoriesCacheKey);
    if (cached is List && cached.isNotEmpty) {
      return cached
          .map((e) => AppCategory.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    final seeded = _seededCategories();
    cache.put(_categoriesCacheKey, seeded.map((c) => c.toMap()).toList());
    return seeded;
  }

  void _persist() {
    _cache.put(_categoriesCacheKey, state.map((c) => c.toMap()).toList());
  }

  Future<void> fetch() async {
    final result = await _repo.getAll();
    result.when(
      success: (list) {
        if (list.isNotEmpty) {
          state = list;
          _persist();
        }
      },
      failure: (_) {},
    );
  }

  Future<void> setBudget(String id, double? limit) async {
    final result = await _repo.updateBudget(id, limit);
    result.when(
      success: (cat) {
        state = [
          for (final c in state)
            if (c.id == id) cat else c,
        ];
        _persist();
      },
      failure: (_) {
        // Optimistic local update
        state = [
          for (final c in state)
            if (c.id == id) c.copyWith(budgetLimit: limit) else c,
        ];
        _persist();
      },
    );
  }

  void add(AppCategory c) {
    state = [...state, c];
    _persist();
  }

  void remove(String id) {
    state = state.where((c) => c.id != id).toList();
    _persist();
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<AppCategory>>(
  (ref) {
    final notifier = CategoriesNotifier(
      ref.watch(categoryRepoProvider),
      ref.watch(_cacheBoxProvider),
    );
    notifier.fetch();
    return notifier;
  },
);

// ═══════════════════════════════════════
// Payment Methods
// ═══════════════════════════════════════
class PaymentMethodsNotifier extends StateNotifier<List<PaymentMethod>> {
  final PaymentMethodRepository _repo;
  final Box _cache;
  PaymentMethodsNotifier(this._repo, this._cache)
      : super(_cachedPaymentMethods(_cache));

  void _persist() {
    _cache.put(_paymentMethodsCacheKey, state.map((p) => p.toMap()).toList());
  }

  List<PaymentMethod> _dedupe(List<PaymentMethod> list) {
    final byId = <String, PaymentMethod>{};
    for (final pm in list) {
      byId[pm.id] = pm;
    }
    return byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<PaymentMethod> _applyDefault(
      PaymentMethod pm, List<PaymentMethod> list) {
    if (!pm.isDefault) return list;
    return [
      for (final item in list)
        if (item.id == pm.id) pm else item.copyWith(isDefault: false),
    ];
  }

  Future<void> fetch() async {
    final result = await _repo.getAll();
    result.when(
      success: (list) {
        state = _dedupe([...state, ...list]);
        _persist();
      },
      failure: (_) {},
    );
  }

  Future<void> add(PaymentMethod pm) async {
    state = _applyDefault(pm, [pm, ...state.where((p) => p.id != pm.id)]);
    _persist();

    final data = pm.toMap()
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at');
    data['is_default'] = pm.isDefault;
    final result = await _repo.create(data);
    result.when(
      success: (created) {
        state = _applyDefault(
          created,
          [created, ...state.where((p) => p.id != pm.id && p.id != created.id)],
        );
        _persist();
      },
      failure: (_) => _persist(),
    );
  }

  Future<void> update(PaymentMethod pm) async {
    state = _applyDefault(
      pm,
      [
        for (final p in state)
          if (p.id == pm.id) pm else p,
      ],
    );
    _persist();

    final data = pm.toMap()
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at');
    data['is_default'] = pm.isDefault;
    final result = await _repo.update(pm.id, data);
    result.when(
      success: (updated) {
        state = _applyDefault(
          updated,
          [
            for (final p in state)
              if (p.id == updated.id) updated else p,
          ],
        );
        _persist();
      },
      failure: (_) => _persist(),
    );
  }

  Future<void> delete(String id) async {
    state = state.where((p) => p.id != id).toList();
    _persist();

    final result = await _repo.delete(id);
    result.when(
      success: (_) => _persist(),
      failure: (_) => _persist(),
    );
  }

  void makeDefault(String id) {
    state = [
      for (final p in state) p.copyWith(isDefault: p.id == id),
    ];
    _persist();
    final pm = state.firstWhere((p) => p.id == id);
    update(pm);
  }
}

final paymentMethodsProvider =
    StateNotifierProvider<PaymentMethodsNotifier, List<PaymentMethod>>(
  (ref) {
    final notifier = PaymentMethodsNotifier(
      ref.watch(paymentMethodRepoProvider),
      ref.watch(_cacheBoxProvider),
    );
    notifier.fetch();
    return notifier;
  },
);

final safePaymentMethodsProvider = Provider<List<PaymentMethod>>((ref) {
  return _sanitizePaymentMethods(ref.watch(paymentMethodsProvider));
});

// ═══════════════════════════════════════
// Subscriptions
// ═══════════════════════════════════════
class SubscriptionsNotifier extends StateNotifier<List<Subscription>> {
  final SubscriptionRepository _repo;
  final Box _cache;
  SubscriptionsNotifier(this._repo, this._cache)
      : super(_cachedSubscriptions(_cache));

  void _persist() {
    _cache.put(_subscriptionsCacheKey, state.map((s) => s.toMap()).toList());
  }

  List<Subscription> _dedupe(List<Subscription> list) {
    // Primary dedup: by ID (canonical)
    final byId = <String, Subscription>{};
    for (final sub in list) {
      final existing = byId[sub.id];
      if (existing == null || sub.updatedAt.isAfter(existing.updatedAt)) {
        byId[sub.id] = sub;
      }
    }
    // Secondary dedup: by serviceSlug — keep only the most recently-updated
    // entry per service so old email-scan imports don't stack on top of manually
    // added or re-imported subscriptions.
    final bySlug = <String, Subscription>{};
    for (final sub in byId.values) {
      final existing = bySlug[sub.serviceSlug];
      if (existing == null || sub.updatedAt.isAfter(existing.updatedAt)) {
        bySlug[sub.serviceSlug] = sub;
      }
    }
    return bySlug.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> fetch() async {
    final result = await _repo.getAll();
    result.when(
      success: (list) {
        state = _dedupe([...state, ...list]);
        _persist();
      },
      failure: (_) {},
    );
  }

  Future<void> add(Subscription s) async {
    state = [s, ...state.where((x) => x.id != s.id)];
    _persist();

    final data = s.toMap()
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at')
      ..remove('updated_at');
    final result = await _repo.create(data);
    result.when(
      success: (created) {
        state = [
          created,
          ...state.where((x) => x.id != s.id && x.id != created.id),
        ];
        _persist();
      },
      failure: (_) => _persist(),
    );
  }

  Future<void> addLocal(Subscription s) async {
    state = _dedupe([s, ...state.where((x) => x.id != s.id)]);
    _persist();
  }

  Future<void> update(Subscription s) async {
    state = [
      for (final x in state)
        if (x.id == s.id) s else x,
    ];
    _persist();

    final data = s.toMap()
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at')
      ..remove('updated_at');
    final result = await _repo.update(s.id, data);
    result.when(
      success: (updated) {
        state = [
          for (final x in state)
            if (x.id == updated.id) updated else x
        ];
        _persist();
      },
      failure: (_) => _persist(),
    );
  }

  Future<void> delete(String id) async {
    state = state.where((x) => x.id != id).toList();
    _persist();

    final result = await _repo.delete(id);
    result.when(
      success: (_) => _persist(),
      failure: (_) => _persist(),
    );
  }

  Future<void> archive(String id) async {
    final sub = state.where((x) => x.id == id).firstOrNull;
    if (sub == null) return;
    final updated = sub.copyWith(status: SubscriptionStatus.archived);
    await update(updated);
  }

  Future<void> setStatus(String id, SubscriptionStatus status) async {
    final sub = state.where((x) => x.id == id).firstOrNull;
    if (sub == null) return;
    final updated = sub.copyWith(status: status);
    await update(updated);
  }
}

final subscriptionsProvider =
    StateNotifierProvider<SubscriptionsNotifier, List<Subscription>>(
  (ref) {
    final notifier = SubscriptionsNotifier(
      ref.watch(subscriptionRepoProvider),
      ref.watch(_cacheBoxProvider),
    );
    notifier.fetch();
    return notifier;
  },
);

final safeSubscriptionsProvider = Provider<List<Subscription>>((ref) {
  return _sanitizeSubscriptions(ref.watch(subscriptionsProvider));
});

/// Only subs that count toward "spend" — active or trial.
final liveSubscriptionsProvider = Provider<List<Subscription>>((ref) {
  final all = ref.watch(safeSubscriptionsProvider);
  return all
      .where((s) =>
          s.status == SubscriptionStatus.active ||
          s.status == SubscriptionStatus.trial)
      .toList();
});

// ═══════════════════════════════════════
// Payment History
// ═══════════════════════════════════════
final paymentHistoryProvider = Provider<List<PaymentHistoryEntry>>((ref) {
  // Full history — loaded on-demand per subscription via family provider
  return [];
});

final historyForSubscriptionProvider =
    FutureProvider.family<List<PaymentHistoryEntry>, String>(
        (ref, subId) async {
  final repo = ref.watch(paymentHistoryRepoProvider);
  final result = await repo.getBySubscription(subId);
  return result.data ?? [];
});

// ═══════════════════════════════════════
// Analytics / Dashboard
// ═══════════════════════════════════════
class DashboardSummary {
  final double monthlyTotalINR;
  final double yearlyTotalINR;
  final int activeCount;
  final int trialsEndingSoon;
  const DashboardSummary({
    required this.monthlyTotalINR,
    required this.yearlyTotalINR,
    required this.activeCount,
    required this.trialsEndingSoon,
  });
}

class DashboardHealth {
  final bool hasSubscriptions;
  final bool hasPaymentMethods;
  final bool hasAnyData;
  final bool isUsingDemoUser;
  final bool ratesReady;
  final bool hasPartialData;
  final List<String> notices;

  const DashboardHealth({
    required this.hasSubscriptions,
    required this.hasPaymentMethods,
    required this.hasAnyData,
    required this.isUsingDemoUser,
    required this.ratesReady,
    required this.hasPartialData,
    required this.notices,
  });
}

final dashboardHealthProvider = Provider<DashboardHealth>((ref) {
  final subs = ref.watch(safeSubscriptionsProvider);
  final paymentMethods = ref.watch(safePaymentMethodsProvider);
  final user = ref.watch(currentUserProvider);
  final notices = <String>[];

  final hasSubscriptions = subs.isNotEmpty;
  final hasPaymentMethods = paymentMethods.isNotEmpty;
  final hasAnyData = hasSubscriptions || hasPaymentMethods;
  final isUsingDemoUser = user.id.isEmpty || user.email.trim().isEmpty;
  final ratesReady = CurrencyUtil.ratesUpdatedAt != null;
  final hasPartialData = hasSubscriptions != hasPaymentMethods;

  if (!ratesReady) notices.add('Currency rates are syncing.');
  if (isUsingDemoUser)
    notices.add('Using local profile until cloud sync completes.');
  if (!hasSubscriptions) notices.add('No recurring subscriptions found yet.');
  if (!hasPaymentMethods && hasSubscriptions) {
    notices.add('Link a payment method to complete wallet tracking.');
  }

  return DashboardHealth(
    hasSubscriptions: hasSubscriptions,
    hasPaymentMethods: hasPaymentMethods,
    hasAnyData: hasAnyData,
    isUsingDemoUser: isUsingDemoUser,
    ratesReady: ratesReady,
    hasPartialData: hasPartialData,
    notices: notices,
  );
});

final dashboardSummaryProvider = Provider<DashboardSummary>((ref) {
  final subs = ref.watch(liveSubscriptionsProvider);
  double monthly = 0;
  double yearly = 0;
  int active = 0;
  int trialsSoon = 0;
  for (final s in subs) {
    // Convert the raw amount to INR first, then compute the cycle-normalised values.
    // toMonthly/toYearly must operate on the original per-cycle amount, NOT on each
    // other's output — doing toYearly(toMonthly(x)) produces wrong results for
    // non-monthly cycles (e.g. quarterly ₹899 → monthly 299.67 → yearly 3596,
    // correct; but if we first called toMonthly then toYearly on *that* we'd double-convert).
    final amtInINR = CurrencyUtil.convert(s.amount, s.currency, 'INR');
    monthly += s.billingCycle.toMonthly(amtInINR);
    yearly += s.billingCycle.toYearly(amtInINR);
    if (s.status == SubscriptionStatus.active) active++;
    if (s.isTrial && (s.daysUntilTrialEnd ?? 99) <= 7) trialsSoon++;
  }
  return DashboardSummary(
    monthlyTotalINR: monthly,
    yearlyTotalINR: yearly,
    activeCount: active,
    trialsEndingSoon: trialsSoon,
  );
});

class MonthlySpendPoint {
  final DateTime month;
  final double totalInUserCurrency;
  const MonthlySpendPoint(this.month, this.totalInUserCurrency);
}

final last6MonthsSpendProvider = Provider<List<MonthlySpendPoint>>((ref) {
  // Compute from live subscriptions since full history is per-sub
  final subs = ref.watch(liveSubscriptionsProvider);
  final ccy = ref.watch(preferredCurrencyProvider);
  final now = DateTime.now();
  final buckets = <DateTime, double>{};
  for (int i = 5; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i);
    buckets[m] = 0;
  }
  // Estimate: distribute monthly-equivalent across past months
  for (final s in subs) {
    final monthlyInCcy = CurrencyUtil.convert(
        s.billingCycle.toMonthly(s.amount), s.currency, ccy);
    for (final key in buckets.keys) {
      if (s.createdAt.isBefore(key.add(const Duration(days: 31)))) {
        buckets[key] = (buckets[key] ?? 0) + monthlyInCcy;
      }
    }
  }
  return buckets.entries.map((e) => MonthlySpendPoint(e.key, e.value)).toList();
});

class CategorySlice {
  final AppCategory category;
  final double totalInUserCurrency;
  final int subCount;
  const CategorySlice({
    required this.category,
    required this.totalInUserCurrency,
    required this.subCount,
  });
}

final categoryBreakdownProvider = Provider<List<CategorySlice>>((ref) {
  final subs = ref.watch(liveSubscriptionsProvider);
  final cats = ref.watch(categoriesProvider);
  final ccy = ref.watch(preferredCurrencyProvider);
  final totals = <String, double>{};
  final counts = <String, int>{};
  for (final s in subs) {
    final id = s.categoryId ?? 'cat_other';
    final monthlyInCcy = CurrencyUtil.convert(
        s.billingCycle.toMonthly(s.amount), s.currency, ccy);
    totals[id] = (totals[id] ?? 0) + monthlyInCcy;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  final slices = <CategorySlice>[];
  for (final c in cats) {
    final total = totals[c.id] ?? 0;
    final count = counts[c.id] ?? 0;
    if (count == 0) continue;
    slices.add(CategorySlice(
      category: c,
      totalInUserCurrency: total,
      subCount: count,
    ));
  }
  slices.sort((a, b) => b.totalInUserCurrency.compareTo(a.totalInUserCurrency));
  return slices;
});

/// Renewal queue (sorted ascending by nextRenewal).
/// Only includes future/today renewals — never shows overdue or past.
final upcomingRenewalsProvider = Provider<List<Subscription>>((ref) {
  final subs = ref.watch(liveSubscriptionsProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sorted = [...subs]..sort((a, b) {
      final ad = a.nextRenewalDate ?? now.add(const Duration(days: 9999));
      final bd = b.nextRenewalDate ?? now.add(const Duration(days: 9999));
      return ad.compareTo(bd);
    });
  return sorted
      .where((s) =>
          s.nextRenewalDate != null &&
          !s.isGhost &&
          !s.nextRenewalDate!.isBefore(today))
      .toList();
});

final ghostSubscriptionsProvider = Provider<List<Subscription>>((ref) {
  final subs = ref.watch(liveSubscriptionsProvider);
  return subs.where((s) => s.isGhost).toList();
});

/// Find by payment method.
final subsByPaymentMethodProvider =
    Provider.family<List<Subscription>, String>((ref, pmId) {
  return ref
      .watch(liveSubscriptionsProvider)
      .where((s) => s.paymentMethodId == pmId)
      .toList();
});

final subsByCategoryProvider =
    Provider.family<List<Subscription>, String>((ref, catId) {
  return ref
      .watch(liveSubscriptionsProvider)
      .where((s) => s.categoryId == catId)
      .toList();
});

/// Currency rates — fetched on app launch, updates CurrencyUtil.
final currencyRatesInitProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(currencyRepoProvider);
  // Try cached first
  final cached = repo.getCachedRates();
  final cachedUpdatedAt = repo.getCachedUpdatedAt();
  if (cached != null) {
    CurrencyUtil.setRates(cached, updatedAt: cachedUpdatedAt);
  }
  // Then refresh from API
  final result = await repo.getRates();
  result.when(
    success: (rates) =>
        CurrencyUtil.setRates(rates, updatedAt: repo.getCachedUpdatedAt()),
    failure: (_) {},
  );
});

String newId() => _uuid.v4();
