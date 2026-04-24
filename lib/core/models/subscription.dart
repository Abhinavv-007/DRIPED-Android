import 'billing_cycle.dart';

enum SubscriptionStatus {
  active,
  trial,
  paused,
  cancelled,
  archived;

  String get wire => name;
  String get label {
    switch (this) {
      case SubscriptionStatus.active:    return 'Active';
      case SubscriptionStatus.trial:     return 'Trial';
      case SubscriptionStatus.paused:    return 'Paused';
      case SubscriptionStatus.cancelled: return 'Cancelled';
      case SubscriptionStatus.archived:  return 'Archived';
    }
  }

  static SubscriptionStatus fromWire(String? v) {
    switch (v) {
      case 'trial':     return SubscriptionStatus.trial;
      case 'paused':    return SubscriptionStatus.paused;
      case 'cancelled': return SubscriptionStatus.cancelled;
      case 'archived':  return SubscriptionStatus.archived;
      default:          return SubscriptionStatus.active;
    }
  }
}

enum SubscriptionSource {
  manual,
  emailScan,
  import;

  String get wire {
    switch (this) {
      case SubscriptionSource.manual:    return 'manual';
      case SubscriptionSource.emailScan: return 'email_scan';
      case SubscriptionSource.import:    return 'import';
    }
  }

  static SubscriptionSource fromWire(String? v) {
    switch (v) {
      case 'email_scan': return SubscriptionSource.emailScan;
      case 'import':     return SubscriptionSource.import;
      default:           return SubscriptionSource.manual;
    }
  }
}

class Subscription {
  final String id;
  final String userId;
  final String serviceName;
  final String serviceSlug;
  final String? categoryId;
  final double amount;
  final String currency;
  final BillingCycle billingCycle;
  final DateTime? startDate;
  final DateTime? nextRenewalDate;
  final DateTime? trialEndDate;
  final bool isTrial;
  final SubscriptionStatus status;
  final String? paymentMethodId;
  final String? notes;
  final SubscriptionSource source;
  final DateTime? lastEmailDetectedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // client-only reminder prefs (Phase A: in memory only)
  final bool remind7d;
  final bool remind3d;
  final bool remind1d;

  const Subscription({
    required this.id,
    required this.userId,
    required this.serviceName,
    required this.serviceSlug,
    this.categoryId,
    required this.amount,
    this.currency = 'INR',
    required this.billingCycle,
    this.startDate,
    this.nextRenewalDate,
    this.trialEndDate,
    this.isTrial = false,
    this.status = SubscriptionStatus.active,
    this.paymentMethodId,
    this.notes,
    this.source = SubscriptionSource.manual,
    this.lastEmailDetectedAt,
    required this.createdAt,
    required this.updatedAt,
    this.remind7d = true,
    this.remind3d = true,
    this.remind1d = true,
  });

  double get monthlyEquivalent => billingCycle.toMonthly(amount);
  double get yearlyEquivalent  => billingCycle.toYearly(amount);

  DateTime? get effectiveRenewalDate {
    if (nextRenewalDate == null) return null;
    if (billingCycle == BillingCycle.lifetime) return null;

    final base = DateTime(
      nextRenewalDate!.year,
      nextRenewalDate!.month,
      nextRenewalDate!.day,
    );

    if (status != SubscriptionStatus.active &&
        status != SubscriptionStatus.trial) {
      return base;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!base.isBefore(today)) return base;

    var cursor = base;
    var guard = 0;
    while (cursor.isBefore(today) && guard < 120) {
      cursor = _advanceCycle(cursor, billingCycle);
      guard++;
    }
    return cursor;
  }

  int? get daysUntilRenewal {
    final effective = effectiveRenewalDate;
    if (effective == null) return null;
    final now = DateTime.now();
    final dt = DateTime(effective.year, effective.month, effective.day);
    final today = DateTime(now.year, now.month, now.day);
    return dt.difference(today).inDays;
  }

  /// Whether the renewal date is in the past.
  bool get isOverdue => (daysUntilRenewal ?? 0) < 0;

  /// Whether the subscription is effectively expired/inactive with past renewal.
  bool get isExpiredOrCancelled =>
      status == SubscriptionStatus.cancelled ||
      status == SubscriptionStatus.archived ||
      (status == SubscriptionStatus.paused && isOverdue);

  /// Human-friendly label for renewal status. Never returns negative numbers.
  String get renewalDisplayLabel {
    if (billingCycle == BillingCycle.lifetime) return 'One-time';
    final days = daysUntilRenewal;
    if (days == null) return '—';
    if (status == SubscriptionStatus.cancelled) return 'Cancelled';
    if (status == SubscriptionStatus.archived) return 'Archived';
    if (days < -30) return 'Expired';
    if (days < 0) return 'Overdue';
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    if (days <= 7) return 'in $days days';
    return 'in $days days';
  }

  int? get daysUntilTrialEnd {
    if (trialEndDate == null) return null;
    final now = DateTime.now();
    final dt =
        DateTime(trialEndDate!.year, trialEndDate!.month, trialEndDate!.day);
    final today = DateTime(now.year, now.month, now.day);
    return dt.difference(today).inDays;
  }

  /// Ghost detection — billed but no email activity in 60+ days.
  bool get isGhost {
    if (status != SubscriptionStatus.active) return false;
    if (lastEmailDetectedAt == null) return false;
    return DateTime.now().difference(lastEmailDetectedAt!).inDays > 60;
  }

  Subscription copyWith({
    String? serviceName,
    String? serviceSlug,
    String? categoryId,
    double? amount,
    String? currency,
    BillingCycle? billingCycle,
    DateTime? startDate,
    DateTime? nextRenewalDate,
    DateTime? trialEndDate,
    bool? isTrial,
    SubscriptionStatus? status,
    String? paymentMethodId,
    String? notes,
    bool? remind7d,
    bool? remind3d,
    bool? remind1d,
    DateTime? lastEmailDetectedAt,
  }) =>
      Subscription(
        id: id,
        userId: userId,
        serviceName: serviceName ?? this.serviceName,
        serviceSlug: serviceSlug ?? this.serviceSlug,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        billingCycle: billingCycle ?? this.billingCycle,
        startDate: startDate ?? this.startDate,
        nextRenewalDate: nextRenewalDate ?? this.nextRenewalDate,
        trialEndDate: trialEndDate ?? this.trialEndDate,
        isTrial: isTrial ?? this.isTrial,
        status: status ?? this.status,
        paymentMethodId: paymentMethodId ?? this.paymentMethodId,
        notes: notes ?? this.notes,
        source: source,
        lastEmailDetectedAt: lastEmailDetectedAt ?? this.lastEmailDetectedAt,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
        remind7d: remind7d ?? this.remind7d,
        remind3d: remind3d ?? this.remind3d,
        remind1d: remind1d ?? this.remind1d,
      );

  factory Subscription.fromMap(Map<String, dynamic> m) => Subscription(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        serviceName: m['service_name'] as String,
        serviceSlug: m['service_slug'] as String,
        categoryId: m['category_id'] as String?,
        amount: (m['amount'] as num).toDouble(),
        currency: (m['currency'] as String?) ?? 'INR',
        billingCycle: BillingCycle.fromWire(m['billing_cycle'] as String),
        startDate: DateTime.tryParse(m['start_date'] as String? ?? ''),
        nextRenewalDate:
            DateTime.tryParse(m['next_renewal_date'] as String? ?? ''),
        trialEndDate:
            DateTime.tryParse(m['trial_end_date'] as String? ?? ''),
        isTrial: (m['is_trial'] as int? ?? 0) == 1,
        status: SubscriptionStatus.fromWire(m['status'] as String?),
        paymentMethodId: m['payment_method_id'] as String?,
        notes: m['notes'] as String?,
        source: SubscriptionSource.fromWire(m['source'] as String?),
        lastEmailDetectedAt:
            DateTime.tryParse(m['last_email_detected_at'] as String? ?? ''),
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(m['updated_at'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'service_name': serviceName,
        'service_slug': serviceSlug,
        'category_id': categoryId,
        'amount': amount,
        'currency': currency,
        'billing_cycle': billingCycle.name,
        'start_date': startDate?.toIso8601String(),
        'next_renewal_date': nextRenewalDate?.toIso8601String(),
        'trial_end_date': trialEndDate?.toIso8601String(),
        'is_trial': isTrial ? 1 : 0,
        'status': status.wire,
        'payment_method_id': paymentMethodId,
        'notes': notes,
        'source': source.wire,
        'last_email_detected_at': lastEmailDetectedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  static DateTime _advanceCycle(DateTime date, BillingCycle cycle) {
    switch (cycle) {
      case BillingCycle.weekly:
        return date.add(const Duration(days: 7));
      case BillingCycle.monthly:
        return _addMonths(date, 1);
      case BillingCycle.quarterly:
        return _addMonths(date, 3);
      case BillingCycle.yearly:
        return DateTime(date.year + 1, date.month, date.day);
      case BillingCycle.lifetime:
        return date;
    }
  }

  static DateTime _addMonths(DateTime date, int months) {
    final totalMonths = (date.year * 12) + date.month - 1 + months;
    final year = totalMonths ~/ 12;
    final month = (totalMonths % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }
}
