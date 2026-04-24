import 'package:intl/intl.dart';

import '../models/billing_cycle.dart';

/// Currency formatting + conversion helpers.
/// Phase A uses a static rates table. Phase B+ replaces getRate()
/// with the cached Worker KV table.
class CurrencyUtil {
  CurrencyUtil._();

  static const supported = <String>['INR', 'USD', 'EUR', 'GBP', 'AED', 'SGD', 'JPY', 'AUD'];

  /// Fallback rates (base INR). Over-written at runtime once KV cache lands.
  static Map<String, double> _ratesFromINR = const {
    'INR': 1.0,
    'USD': 0.012,
    'EUR': 0.011,
    'GBP': 0.0094,
    'AED': 0.044,
    'SGD': 0.016,
    'JPY': 1.78,
    'AUD': 0.018,
  };

  static DateTime? _ratesUpdatedAt;
  static DateTime? get ratesUpdatedAt => _ratesUpdatedAt;

  static void setRates(
    Map<String, double> ratesFromINR, {
    DateTime? updatedAt,
  }) {
    _ratesFromINR = {..._ratesFromINR, ...ratesFromINR};
    _ratesUpdatedAt = updatedAt ?? DateTime.now();
  }

  /// Human-readable time-ago string.
  static String ratesTimeAgo() {
    if (_ratesUpdatedAt == null) return 'never';
    final diff = DateTime.now().difference(_ratesUpdatedAt!);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return 'yesterday';
  }

  static String ratesUpdatedLabel() {
    if (_ratesUpdatedAt == null) return 'syncing...';
    return DateFormat('dd MMM • hh:mm a').format(_ratesUpdatedAt!.toLocal());
  }

  static double getRate(String from, String to) {
    if (from == to) return 1;
    final toINR = 1 / (_ratesFromINR[from] ?? 1);
    final fromINRtoTarget = _ratesFromINR[to] ?? 1;
    return toINR * fromINRtoTarget;
  }

  static double convert(double amount, String from, String to) =>
      amount * getRate(from, to);

  static String symbol(String code) {
    switch (code) {
      case 'INR': return '₹';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'AED': return 'د.إ';
      case 'SGD': return 'S\$';
      case 'JPY': return '¥';
      case 'AUD': return 'A\$';
      default:    return code;
    }
  }

  /// Compact formatting — "₹299", "₹3,588", "₹12.4K".
  static String formatAmount(
    double amount, {
    required String code,
    bool compact = false,
    int decimals = 0,
  }) {
    final s = symbol(code);
    if (compact && amount.abs() >= 10000) {
      final k = NumberFormat.compactCurrency(symbol: s, decimalDigits: 1);
      return k.format(amount);
    }
    final f = NumberFormat.currency(
      symbol: s,
      decimalDigits: decimals,
      locale: code == 'INR' ? 'en_IN' : 'en_US',
    );
    return f.format(amount);
  }

  /// "₹299/mo", "₹3,588/yr", "\$9.99/mo".
  static String formatContextual(
    double amount, {
    required String code,
    required BillingCycle cycle,
    bool showDecimalsOnSmall = true,
  }) {
    final decimals = (code != 'INR' && showDecimalsOnSmall) ? 2 : 0;
    final main = formatAmount(amount, code: code, decimals: decimals);
    return '$main${cycle.shortSuffix}';
  }
}
