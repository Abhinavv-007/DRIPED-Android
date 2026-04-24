enum BillingCycle {
  weekly,
  monthly,
  quarterly,
  yearly,
  lifetime;

  String get label {
    switch (this) {
      case BillingCycle.weekly:    return 'Weekly';
      case BillingCycle.monthly:   return 'Monthly';
      case BillingCycle.quarterly: return 'Quarterly';
      case BillingCycle.yearly:    return 'Yearly';
      case BillingCycle.lifetime:  return 'Lifetime';
    }
  }

  String get shortSuffix {
    switch (this) {
      case BillingCycle.weekly:    return '/wk';
      case BillingCycle.monthly:   return '/mo';
      case BillingCycle.quarterly: return '/qtr';
      case BillingCycle.yearly:    return '/yr';
      case BillingCycle.lifetime:  return '';
    }
  }

  /// Convert any cycle amount → monthly amount for comparison / totals.
  double toMonthly(double amount) {
    switch (this) {
      case BillingCycle.weekly:    return amount * 4.345;
      case BillingCycle.monthly:   return amount;
      case BillingCycle.quarterly: return amount / 3;
      case BillingCycle.yearly:    return amount / 12;
      case BillingCycle.lifetime:  return 0; // no recurring
    }
  }

  /// Convert any cycle amount → yearly amount.
  double toYearly(double amount) {
    switch (this) {
      case BillingCycle.weekly:    return amount * 52;
      case BillingCycle.monthly:   return amount * 12;
      case BillingCycle.quarterly: return amount * 4;
      case BillingCycle.yearly:    return amount;
      case BillingCycle.lifetime:  return 0;
    }
  }

  /// Days between charges (approx).
  int get periodDays {
    switch (this) {
      case BillingCycle.weekly:    return 7;
      case BillingCycle.monthly:   return 30;
      case BillingCycle.quarterly: return 91;
      case BillingCycle.yearly:    return 365;
      case BillingCycle.lifetime:  return 1 << 30;
    }
  }

  static BillingCycle fromWire(String v) =>
      BillingCycle.values.firstWhere((e) => e.name == v,
          orElse: () => BillingCycle.monthly);
}
