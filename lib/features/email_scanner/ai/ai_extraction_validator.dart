import '../../../core/models/billing_cycle.dart';
import '../subscription_parser.dart';
import 'mail_ai_models.dart';

class AiExtractionValidator {
  AiExtractionValidator._();

  static DetectedSubscription? toDetectedSubscription(
    AiMailExtraction extraction, {
    required String from,
    required String subject,
    required String textContent,
    required DateTime? emailDate,
    MerchantResolution? fallbackResolution,
  }) {
    final hasTrustedMerchant = fallbackResolution != null;
    if (!extraction.isRecurringSubscription) return null;
    if (extraction.confidence < (hasTrustedMerchant ? 0.62 : 0.88)) {
      return null;
    }

    final status = extraction.status.toLowerCase().trim();
    if (const {
      'refund',
      'failed_payment',
      'one_time',
      'unknown',
    }.contains(status)) {
      return null;
    }
    if (SubscriptionParser.isRefundEmail(textContent) ||
        SubscriptionParser.isFailedPaymentEmail(textContent) ||
        SubscriptionParser.isOneTimePurchase(textContent)) {
      return null;
    }

    // Known parser matches are the source of truth for service identity. The
    // local model may still fill missing amount/date/payment details, but it
    // must not rename a trusted deterministic match.
    final rawServiceName =
        fallbackResolution?.serviceName ?? extraction.serviceName;
    final serviceName = _cleanServiceName(rawServiceName);
    if (serviceName == null) return null;
    if (!hasTrustedMerchant &&
        !_isAiOnlyServiceGrounded(
          serviceName: serviceName,
          from: from,
          subject: subject,
          textContent: textContent,
        )) {
      return null;
    }

    final serviceSlug = fallbackResolution?.serviceSlug ??
        SubscriptionParser.slugifyServiceName(serviceName);
    final categorySlug = fallbackResolution?.categorySlug ??
        SubscriptionParser.guessCategoryForService(serviceName, textContent);
    final currency = _validatedCurrency(extraction.currency, textContent) ??
        SubscriptionParser.detectCurrency(textContent);
    final amount = _validatedAmount(extraction.amount, currency, textContent) ??
        SubscriptionParser.extractAmount(textContent, currency) ??
        0.0;
    final textCycle = _strictCycleFromText(textContent);
    final cycle = extraction.billingCycle ??
        textCycle ??
        SubscriptionParser.detectCycle(textContent);
    final renewalDate = _validatedDate(extraction.renewalDate) ??
        SubscriptionParser.extractRenewalDate(textContent);
    final evidenceScore = _evidenceScore(
      serviceName: serviceName,
      from: from,
      subject: subject,
      textContent: textContent,
      amount: amount,
      cycle: textCycle ?? extraction.billingCycle,
      renewalDate: renewalDate,
      paymentMethodLabel: extraction.paymentMethodLabel,
    );
    if (!hasTrustedMerchant) {
      if (!_hasRecurringEvidence(textContent)) return null;
      if (amount <= 0 && status != 'trial') return null;
      if (textCycle == null &&
          extraction.billingCycle == null &&
          renewalDate == null) {
        return null;
      }
      if (evidenceScore < 7) return null;
    } else if (evidenceScore < 4) {
      return null;
    }

    return DetectedSubscription(
      serviceName: serviceName,
      serviceSlug: serviceSlug,
      categorySlug: categorySlug,
      storeName: fallbackResolution?.storeName,
      amount: amount,
      currency: currency,
      billingCycle: cycle,
      nextRenewalDate: renewalDate,
      isTrial: status == 'trial' || _isTrialText(textContent),
      emailSubject: subject,
      emailDate: emailDate,
      paymentMethodLabel: _cleanPaymentLabel(extraction.paymentMethodLabel) ??
          SubscriptionParser.extractPaymentMethodLabel(textContent),
      isCancellation: status == 'cancelled' ||
          SubscriptionParser.isCancellationEmail(textContent),
      isRefund: false,
      isFailedPayment: false,
      isOneTimePurchase: false,
      confidence: extraction.confidence,
      requiresReview: !hasTrustedMerchant,
      detectionSource: hasTrustedMerchant ? 'parser_ai' : 'ai',
    );
  }

  static String? _cleanServiceName(String? raw) {
    if (raw == null) return null;
    final cleaned = raw
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[\W_]+|[\W_]+$'), '')
        .trim();
    if (cleaned.length < 2 || cleaned.length > 80) return null;
    final normalized = cleaned.toLowerCase();
    const generic = {
      'subscription',
      'your subscription',
      'plan',
      'premium plan',
      'membership',
      'receipt',
      'invoice',
      'payment',
      'billing',
      'unknown',
      'unknown merchant',
      'merchant',
      'service',
      'app',
      'order',
      'your order',
      'google',
      'google play',
      'apple',
      'app store',
      'itunes',
      'paypal',
      'visa',
      'mastercard',
      'american express',
      'upi',
      'credit card',
      'debit card',
      'thank you',
    };
    if (generic.contains(normalized)) return null;
    return SubscriptionParser.titleCaseServiceName(cleaned);
  }

  static bool _isAiOnlyServiceGrounded({
    required String serviceName,
    required String from,
    required String subject,
    required String textContent,
  }) {
    final needle = _normalizeForGrounding(serviceName);
    if (needle.length < 3) return false;

    final message = _normalizeForGrounding('$subject $textContent');
    if (message.contains(needle)) return true;

    final tokens = needle
        .split(' ')
        .where((part) => part.length >= 3)
        .toList(growable: false);
    if (tokens.length >= 2 && tokens.every(message.contains)) return true;

    final sender = _normalizeForGrounding(from);
    if (sender.contains(needle)) return true;

    final domain = _senderDomain(from);
    return tokens.any((token) => token.length >= 4 && domain.contains(token));
  }

  static bool _hasRecurringEvidence(String text) {
    final lower = text.toLowerCase();
    return RegExp(
      r'\b(subscription|subscribed|membership|renewal|renews|renewed|auto[- ]?renew|automatic renewal|recurring|next billing|next payment|next charge|billing cycle|monthly|per month|annual|annually|yearly|per year|trial ends|trial expires)\b',
      caseSensitive: false,
    ).hasMatch(lower);
  }

  static int _evidenceScore({
    required String serviceName,
    required String from,
    required String subject,
    required String textContent,
    required double amount,
    required BillingCycle? cycle,
    required DateTime? renewalDate,
    required String? paymentMethodLabel,
  }) {
    var score = 0;
    final normalizedService = _normalizeForGrounding(serviceName);
    final normalizedMessage = _normalizeForGrounding('$subject $textContent');
    final sender = _normalizeForGrounding(from);
    final domain = _senderDomain(from);

    if (normalizedMessage.contains(normalizedService)) score += 3;
    if (sender.contains(normalizedService) ||
        domain.contains(normalizedService)) {
      score += 2;
    }
    final serviceTokens = normalizedService
        .split(' ')
        .where((part) => part.length >= 3)
        .toList(growable: false);
    if (serviceTokens.isNotEmpty &&
        serviceTokens.every((token) => normalizedMessage.contains(token))) {
      score += 1;
    }
    if (amount > 0) score += 2;
    if (_hasRecurringEvidence(textContent)) score += 2;
    if (cycle != null) score += 1;
    if (renewalDate != null) score += 1;
    if (_cleanPaymentLabel(paymentMethodLabel) != null ||
        SubscriptionParser.extractPaymentMethodLabel(textContent) != null) {
      score += 1;
    }
    return score;
  }

  static String _normalizeForGrounding(String value) {
    return value
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll('+', ' plus ')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _senderDomain(String from) {
    final lower = from.toLowerCase();
    final match = RegExp(r'@([^>\s]+)').firstMatch(lower);
    return match?.group(1)?.replaceAll(RegExp(r'[^a-z0-9]+'), ' ') ?? lower;
  }

  static double? _validatedAmount(
    double? amount,
    String currency,
    String text,
  ) {
    if (amount == null || !amount.isFinite || amount < 0) return null;
    if (amount == 0) return 0;
    final normalizedText = text.replaceAll(',', '').toLowerCase();
    final asInt =
        amount == amount.roundToDouble() ? amount.toInt().toString() : null;
    final asDecimal = amount.toStringAsFixed(2);
    final asLoose = amount.toString();
    final candidates = [
      if (asInt != null) asInt,
      asDecimal,
      asLoose,
    ];
    final hasNumber = candidates.any(normalizedText.contains);
    if (!hasNumber) return null;

    final hasCurrency = _validatedCurrency(currency, text) != null;
    return hasCurrency ? amount : null;
  }

  static String? _validatedCurrency(String? currency, String text) {
    if (currency == null) return null;
    final upper = currency.toUpperCase();
    final lowerText = text.toLowerCase();
    switch (upper) {
      case 'INR':
        return text.contains('₹') ||
                lowerText.contains('inr') ||
                lowerText.contains('rs.') ||
                lowerText.contains('rupees')
            ? upper
            : null;
      case 'USD':
        return text.contains(r'$') || lowerText.contains('usd') ? upper : null;
      case 'EUR':
        return text.contains('€') || lowerText.contains('eur') ? upper : null;
      case 'GBP':
        return text.contains('£') || lowerText.contains('gbp') ? upper : null;
      default:
        return null;
    }
  }

  static DateTime? _validatedDate(DateTime? date) {
    if (date == null) return null;
    final now = DateTime.now();
    if (date.year < 2000 || date.year > now.year + 20) return null;
    return DateTime(date.year, date.month, date.day);
  }

  static BillingCycle? _strictCycleFromText(String text) {
    final lower = text.toLowerCase();
    if (RegExp(r'\b(weekly|per week|every week|/wk)\b').hasMatch(lower)) {
      return BillingCycle.weekly;
    }
    if (RegExp(r'\b(monthly|per month|every month|/mo)\b').hasMatch(lower)) {
      return BillingCycle.monthly;
    }
    if (RegExp(r'\b(quarterly|every 3 months|per quarter|/qtr)\b')
        .hasMatch(lower)) {
      return BillingCycle.quarterly;
    }
    if (RegExp(r'\b(yearly|annual|annually|per year|every year|/yr)\b')
        .hasMatch(lower)) {
      return BillingCycle.yearly;
    }
    return null;
  }

  static String? _cleanPaymentLabel(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length < 2 || cleaned.length > 60) return null;
    return SubscriptionParser.titleCaseServiceName(cleaned);
  }

  static bool _isTrialText(String text) {
    final lower = text.toLowerCase();
    return lower.contains('free trial') ||
        lower.contains('trial ends') ||
        lower.contains('trial period') ||
        lower.contains('trial subscription');
  }
}
