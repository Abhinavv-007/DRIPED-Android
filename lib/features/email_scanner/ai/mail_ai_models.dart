import '../../../core/models/billing_cycle.dart';

class MailAiInput {
  final String from;
  final String subject;
  final String snippet;
  final String body;
  final DateTime? emailDate;

  const MailAiInput({
    required this.from,
    required this.subject,
    required this.snippet,
    required this.body,
    this.emailDate,
  });

  Map<String, dynamic> toMap() => {
        'from': from,
        'subject': subject,
        'snippet': snippet,
        'body': body,
        'date': emailDate?.toIso8601String(),
      };
}

class AiMailExtraction {
  final bool isRecurringSubscription;
  final double confidence;
  final String? serviceName;
  final double? amount;
  final String? currency;
  final BillingCycle? billingCycle;
  final DateTime? renewalDate;
  final String? paymentMethodLabel;
  final String status;
  final Map<String, dynamic> evidence;

  const AiMailExtraction({
    required this.isRecurringSubscription,
    required this.confidence,
    this.serviceName,
    this.amount,
    this.currency,
    this.billingCycle,
    this.renewalDate,
    required this.status,
    this.paymentMethodLabel,
    this.evidence = const {},
  });

  factory AiMailExtraction.fromMap(Map<String, dynamic> map) {
    return AiMailExtraction(
      isRecurringSubscription: _asBool(map['is_recurring_subscription']),
      confidence: _asDouble(map['confidence'])?.clamp(0.0, 1.0) ?? 0,
      serviceName: _cleanString(map['service_name']),
      amount: _asDouble(map['amount']),
      currency: _cleanCurrency(map['currency']),
      billingCycle: _cycleFromWire(_cleanString(map['billing_cycle'])),
      renewalDate: _parseDate(_cleanString(map['renewal_date'])),
      paymentMethodLabel: _cleanString(map['payment_method_label']),
      status: _cleanString(map['status']) ?? 'unknown',
      evidence: map['evidence'] is Map
          ? Map<String, dynamic>.from(map['evidence'] as Map)
          : const {},
    );
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase().trim() == 'true';
    return false;
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '').trim();
      if (cleaned.isEmpty || cleaned.toLowerCase() == 'null') return null;
      return double.tryParse(cleaned);
    }
    return null;
  }

  static String? _cleanString(Object? value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return null;
    return raw.replaceAll(RegExp(r'\s+'), ' ');
  }

  static String? _cleanCurrency(Object? value) {
    final raw = _cleanString(value)?.toUpperCase();
    if (raw == null) return null;
    const supported = {'INR', 'USD', 'EUR', 'GBP'};
    return supported.contains(raw) ? raw : null;
  }

  static BillingCycle? _cycleFromWire(String? value) {
    switch (value) {
      case 'weekly':
        return BillingCycle.weekly;
      case 'monthly':
        return BillingCycle.monthly;
      case 'quarterly':
        return BillingCycle.quarterly;
      case 'yearly':
      case 'annual':
      case 'annually':
        return BillingCycle.yearly;
      case 'lifetime':
        return BillingCycle.lifetime;
      default:
        return null;
    }
  }

  static DateTime? _parseDate(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}
