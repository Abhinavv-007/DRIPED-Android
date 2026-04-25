import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/billing_cycle.dart';
import 'mail_ai_models.dart';

/// Cloud-backed AI extractor.
///
/// Replaces the previous on-device LiteRT-LM model. Calls the Worker's
/// `/scan/extract` endpoint, which runs Llama 3.1 8B Instruct via Workers AI
/// and caches per-email results in KV for 24 h. The Worker is auth-gated by
/// the user's Firebase ID token (added by `_AuthInterceptor`).
class MailAiExtractor {
  MailAiExtractor._();

  static final MailAiExtractor instance = MailAiExtractor._();

  final ApiClient _api = ApiClient();
  bool _availabilityProbed = false;
  bool _availability = true;

  /// Worker AI is always reachable in release builds (custom domain
  /// `api.driped.in`). In debug we still return `true` so the scanner runs
  /// the cloud fallback against `wrangler dev` if it's up; if the request
  /// fails the scanner just keeps the parser's own result.
  Future<bool> isAvailable({bool refresh = false}) async {
    if (!refresh && _availabilityProbed) return _availability;
    _availabilityProbed = true;
    return _availability;
  }

  Future<AiMailExtraction?> extract(
    MailAiInput input, {
    String? hintMerchant,
  }) async {
    try {
      final response = await _api.dio.post<dynamic>(
        '/scan/extract',
        data: <String, dynamic>{
          'email_body': input.body,
          if (input.subject.isNotEmpty) 'email_subject': input.subject,
          if (input.from.isNotEmpty) 'email_from': input.from,
          if (hintMerchant != null && hintMerchant.isNotEmpty)
            'hint_merchant': hintMerchant,
        },
      );

      final body = response.data;
      if (body is! Map) return null;
      if (body['success'] != true) return null;
      final payload = body['data'];
      if (payload is! Map) return null;

      return _toAiExtraction(Map<String, dynamic>.from(payload));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[MailAi] Worker extraction failed: $error');
      }
      return null;
    }
  }

  Future<void> release() async {
    // Stateless cloud client — nothing to free.
  }

  AiMailExtraction _toAiExtraction(Map<String, dynamic> w) {
    final receipt = (w['receipt_type'] as String?)?.toLowerCase() ?? 'unknown';
    final isSub = const {
      'paid',
      'upcoming',
      'trial_started',
      'trial_ending',
    }.contains(receipt);

    final status = switch (receipt) {
      'paid' || 'upcoming' => 'active',
      'trial_started' || 'trial_ending' => 'trial',
      'canceled' => 'cancelled',
      'refund' => 'refund',
      'failed' => 'failed_payment',
      _ => 'unknown',
    };

    final cycle = switch (w['billing_cycle']) {
      'weekly' => BillingCycle.weekly,
      'monthly' => BillingCycle.monthly,
      'quarterly' => BillingCycle.quarterly,
      'yearly' => BillingCycle.yearly,
      'lifetime' => BillingCycle.lifetime,
      _ => null,
    };

    final renewalRaw = w['next_renewal_date'];
    final renewalDate =
        renewalRaw is String ? DateTime.tryParse(renewalRaw) : null;

    final rawConfidence = (w['confidence'] as num?)?.toDouble() ?? 0;
    // Worker returns 0-100, AiMailExtraction expects 0-1
    final confidence = (rawConfidence / 100).clamp(0.0, 1.0);

    final amountRaw = w['amount'];
    final amount = amountRaw is num ? amountRaw.toDouble() : null;

    final reasons = <String, dynamic>{};
    final reasonsList = w['reasons'];
    if (reasonsList is List && reasonsList.isNotEmpty) {
      reasons['reasons'] = reasonsList.cast<String>();
    }

    return AiMailExtraction(
      isRecurringSubscription: isSub,
      confidence: confidence,
      serviceName: w['merchant_name'] as String?,
      amount: amount,
      currency: (w['currency'] as String?)?.toUpperCase(),
      billingCycle: cycle,
      renewalDate: renewalDate,
      paymentMethodLabel: null,
      status: status,
      evidence: reasons,
    );
  }
}

/// Backwards-compatibility alias \u2014 callers in `gmail_scanner.dart` still
/// reference `LocalMailAiExtractor` from the on-device era.
typedef LocalMailAiExtractor = MailAiExtractor;
