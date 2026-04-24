import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../core/models/billing_cycle.dart';
import 'ai/ai_extraction_validator.dart';
import 'ai/local_mail_ai_extractor.dart';
import 'ai/mail_ai_models.dart';
import 'subscription_parser.dart';

/// Rich progress data emitted during scanning.
class ScanProgress {
  final int scanned;
  final int total;
  final String phaseName;
  final String? currentEmailSubject;
  final String? currentEmailFrom;
  final List<String> foundServiceSlugs;
  final List<String> foundServiceNames;

  const ScanProgress({
    required this.scanned,
    required this.total,
    this.phaseName = 'Scanning',
    this.currentEmailSubject,
    this.currentEmailFrom,
    this.foundServiceSlugs = const [],
    this.foundServiceNames = const [],
  });
}

class ScanResult {
  final List<DetectedSubscription> subscriptions;
  final int emailsScanned;
  final int totalMessages;

  const ScanResult({
    required this.subscriptions,
    required this.emailsScanned,
    required this.totalMessages,
  });
}

class GmailScanner {
  final GoogleSignIn _googleSignIn;

  GmailScanner(this._googleSignIn);

  List<DetectedSubscription> _finalize(
      Map<String, DetectedSubscription> detected) {
    return detected.values
        .where(
          (d) => !d.isOneTimePurchase && !d.isRefund && !d.isFailedPayment,
        )
        .toList();
  }

  /// Full scan — rebuilt to be extremely fast and robust, fetching in highly optimized concurrent batches.
  Future<ScanResult> fullScan({
    void Function(int scanned, int total)? onProgress,
    void Function(ScanProgress progress)? onDetailedProgress,
  }) async {
    final gmailApi = await _getGmailApi();
    if (gmailApi == null) {
      throw Exception(
          'Gmail Authentication failed or was revoked. Please sign in again.');
    }

    final queries = SubscriptionParser.buildSmartQueries();
    final detected = <String, DetectedSubscription>{};
    final seenMessageIds = <String>{};
    final localAi = LocalMailAiExtractor.instance;
    final localAiAvailable = await localAi.isAvailable();

    // Phase 1: Aggregate all Message IDs matching the powerful new queries
    List<gmail.Message> allMessagesToScan = [];

    onDetailedProgress?.call(const ScanProgress(
      scanned: 0,
      total: 100,
      phaseName: 'Building index...',
    ));

    Object? firstQueryError;
    var failedQueries = 0;

    for (int i = 0; i < queries.length; i++) {
      try {
        final res = await gmailApi.users.messages.list(
          'me',
          q: queries[i],
          maxResults: 250,
        );
        if (res.messages != null) {
          for (final msg in res.messages!) {
            if (msg.id != null && !seenMessageIds.contains(msg.id)) {
              seenMessageIds.add(msg.id!);
              allMessagesToScan.add(msg);
            }
          }
        }
      } catch (error) {
        failedQueries++;
        firstQueryError ??= error;
        if (_isPermissionError(error)) rethrow;
      }
    }

    final totalMessages = allMessagesToScan.length;
    if (totalMessages == 0 &&
        failedQueries == queries.length &&
        firstQueryError != null) {
      throw Exception('Gmail query failed: $firstQueryError');
    }
    if (totalMessages == 0) {
      return const ScanResult(
          subscriptions: [], emailsScanned: 0, totalMessages: 0);
    }

    int scanned = 0;
    final batchSize = localAiAvailable
        ? 4
        : 10; // Native local LLM inference is serialized by the platform bridge.

    for (int i = 0; i < allMessagesToScan.length; i += batchSize) {
      final end = (i + batchSize < allMessagesToScan.length)
          ? i + batchSize
          : allMessagesToScan.length;
      final batch = allMessagesToScan.sublist(i, end);

      final futures = batch.map((msg) async {
        try {
          // Format full ensures we get headers and payload without attachments slowing us down.
          final detail =
              await gmailApi.users.messages.get('me', msg.id!, format: 'full');

          final headers = detail.payload?.headers ?? [];
          String from = '', subject = '', snippet = detail.snippet ?? '';
          for (final h in headers) {
            if (h.name == 'From') from = h.value ?? '';
            if (h.name == 'Subject') subject = h.value ?? '';
          }
          if (subject.isEmpty && detail.snippet != null) {
            subject = detail.snippet!;
          }

          // Progress
          onDetailedProgress?.call(ScanProgress(
            scanned: scanned,
            total: totalMessages,
            phaseName: 'Analyzing receipts...',
            currentEmailSubject: subject.length > 50
                ? '${subject.substring(0, 47)}...'
                : subject,
            currentEmailFrom: _extractSenderName(from),
            foundServiceSlugs: detected.keys.toList(),
            foundServiceNames:
                detected.values.map((d) => d.serviceName).toList(),
          ));

          final fullText = _extractText(detail.payload);
          final textContent = '$subject $snippet $fullText';
          final emailHeaderDate = _parseEmailDateHeader(
              headers.where((h) => h.name == 'Date').firstOrNull?.value);
          final extractedDate = SubscriptionParser.extractDate(textContent);
          final chargeDate = emailHeaderDate ?? extractedDate;

          final candidateSignals =
              SubscriptionParser.candidateSignals(from, textContent);
          final resolution =
              SubscriptionParser.resolveMerchant(from, textContent);
          if (!candidateSignals.shouldAnalyzeWithAi && resolution == null) {
            return;
          }

          DetectedSubscription? accepted = resolution == null
              ? null
              : _buildParserDetected(
                  resolution: resolution,
                  from: from,
                  textContent: textContent,
                  subject: subject,
                  chargeDate: chargeDate,
                );

          if (localAiAvailable && candidateSignals.shouldAnalyzeWithAi) {
            final aiExtraction = await localAi.extract(MailAiInput(
              from: from,
              subject: subject,
              snippet: snippet,
              body: _prepareAiBody(textContent),
              emailDate: chargeDate,
            ));
            if (aiExtraction != null) {
              final aiDetected = AiExtractionValidator.toDetectedSubscription(
                aiExtraction,
                from: from,
                subject: subject,
                textContent: textContent,
                emailDate: chargeDate,
                fallbackResolution: resolution,
              );
              if (aiDetected != null) {
                accepted = accepted == null
                    ? aiDetected
                    : _mergeDetected(accepted, aiDetected);
              }
            }
          }

          if (accepted == null) return;

          final existing = detected[accepted.serviceSlug];
          detected[accepted.serviceSlug] =
              existing == null ? accepted : _mergeDetected(existing, accepted);
        } catch (e) {
          // Completely silent absorption of bad decoding or rate limiting
        }
      });

      await Future.wait(futures);
      scanned += batch.length;
      onProgress?.call(scanned, totalMessages);
    }

    return ScanResult(
      subscriptions: _finalize(detected),
      emailsScanned: scanned,
      totalMessages: totalMessages,
    );
  }

  Future<ScanResult> incrementalScan({
    void Function(int scanned, int total)? onProgress,
    void Function(ScanProgress progress)? onDetailedProgress,
  }) async {
    // Reusing the same logic but restricted query timeframe
    return fullScan(
        onProgress: onProgress, onDetailedProgress: onDetailedProgress);
  }

  Future<gmail.GmailApi?> _getGmailApi() async {
    // NOTE: canAccessScopes() and requestScopes() are NOT implemented on Android.
    // The gmail.readonly scope is declared in the GoogleSignIn constructor,
    // so it's granted during sign-in. We just need the access token here.
    var account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();
    if (account == null) return null;

    try {
      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception(
          'Google did not return an access token. Please sign out and sign in again.',
        );
      }
      return gmail.GmailApi(_GoogleAuthClient(accessToken));
    } catch (e) {
      throw Exception('Failed to get Gmail access: $e');
    }
  }

  DetectedSubscription _buildParserDetected({
    required MerchantResolution resolution,
    required String from,
    required String textContent,
    required String subject,
    required DateTime? chargeDate,
  }) {
    final isCancellation = SubscriptionParser.isCancellationEmail(textContent);
    final isRefund = SubscriptionParser.isRefundEmail(textContent);
    final isFailedPayment =
        SubscriptionParser.isFailedPaymentEmail(textContent);
    final isOneTime = SubscriptionParser.isOneTimePurchase(textContent);

    final paymentMethodLabel =
        SubscriptionParser.extractPaymentMethodLabel(textContent);
    final cycle = isOneTime
        ? BillingCycle.lifetime
        : SubscriptionParser.detectCycle(textContent);

    final renewalDate =
        isOneTime || isCancellation || isRefund || isFailedPayment
            ? null
            : SubscriptionParser.extractRenewalDate(textContent) ??
                _inferNextRenewal(cycle, chargeDate);

    final currency = SubscriptionParser.detectCurrency(textContent);
    final amount = SubscriptionParser.extractAmount(textContent, currency);
    final trial = resolution.pattern?.isTrial(textContent) ?? false;

    return DetectedSubscription(
      serviceName: resolution.serviceName,
      serviceSlug: resolution.serviceSlug,
      categorySlug: resolution.categorySlug,
      storeName: resolution.storeName,
      amount: amount ?? 0,
      currency: currency,
      billingCycle: cycle,
      nextRenewalDate: renewalDate,
      isTrial: trial,
      emailSubject: subject,
      emailDate: chargeDate,
      paymentMethodLabel: paymentMethodLabel,
      isCancellation: isCancellation,
      isRefund: isRefund,
      isFailedPayment: isFailedPayment,
      isOneTimePurchase: isOneTime,
      confidence: resolution.pattern == null
          ? 0.82
          : SubscriptionParser.confidenceScore(
              resolution.pattern!,
              from,
              textContent,
            ),
      requiresReview: resolution.pattern == null,
      detectionSource: 'parser',
    );
  }

  bool _isPermissionError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('403') ||
        msg.contains('401') ||
        msg.contains('insufficient') ||
        msg.contains('permission') ||
        msg.contains('scope') ||
        msg.contains('auth');
  }

  static String _extractSenderName(String from) {
    final match = RegExp(r'^"?([^"<]+)"?\s*<').firstMatch(from);
    if (match != null) return match.group(1)!.trim();
    return from.length > 30 ? '${from.substring(0, 27)}...' : from;
  }

  DateTime _estimateNextRenewal(BillingCycle cycle) {
    final now = DateTime.now();
    switch (cycle) {
      case BillingCycle.weekly:
        return now.add(const Duration(days: 7));
      case BillingCycle.monthly:
        return DateTime(now.year, now.month + 1, now.day);
      case BillingCycle.quarterly:
        return DateTime(now.year, now.month + 3, now.day);
      case BillingCycle.yearly:
        return DateTime(now.year + 1, now.month, now.day);
      case BillingCycle.lifetime:
        return now;
    }
  }

  DateTime? _inferNextRenewal(BillingCycle cycle, DateTime? chargeDate) {
    if (cycle == BillingCycle.lifetime) return null;
    if (chargeDate == null) return _estimateNextRenewal(cycle);
    final today = DateTime.now();
    var cursor = DateTime(chargeDate.year, chargeDate.month, chargeDate.day);
    var guard = 0;
    while (cursor.isBefore(DateTime(today.year, today.month, today.day)) &&
        guard < 120) {
      switch (cycle) {
        case BillingCycle.weekly:
          cursor = cursor.add(const Duration(days: 7));
          break;
        case BillingCycle.monthly:
          cursor = _addMonths(cursor, 1);
          break;
        case BillingCycle.quarterly:
          cursor = _addMonths(cursor, 3);
          break;
        case BillingCycle.yearly:
          cursor = DateTime(cursor.year + 1, cursor.month, cursor.day);
          break;
        case BillingCycle.lifetime:
          return null;
      }
      guard++;
    }
    return cursor;
  }

  DateTime _addMonths(DateTime date, int months) {
    final totalMonths = (date.year * 12) + date.month - 1 + months;
    final year = totalMonths ~/ 12;
    final month = (totalMonths % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = date.day > lastDay ? lastDay : date.day;
    return DateTime(year, month, day);
  }

  DetectedSubscription _mergeDetected(
      DetectedSubscription existing, DetectedSubscription incoming) {
    if (existing.requiresReview && !incoming.requiresReview) {
      return _mergeDetected(incoming, existing);
    }
    if (existing.amount <= 0 && incoming.amount > 0) {
      existing.amount = incoming.amount;
      existing.currency = incoming.currency;
    }
    if (existing.billingCycle == BillingCycle.monthly &&
        incoming.billingCycle != BillingCycle.monthly) {
      existing.billingCycle = incoming.billingCycle;
    }
    existing.nextRenewalDate ??= incoming.nextRenewalDate;
    existing.paymentMethodLabel ??= incoming.paymentMethodLabel;
    existing.isTrial = existing.isTrial || incoming.isTrial;
    existing.isCancellation =
        existing.isCancellation || incoming.isCancellation;
    existing.isRefund = existing.isRefund || incoming.isRefund;
    existing.isFailedPayment =
        existing.isFailedPayment || incoming.isFailedPayment;
    existing.isOneTimePurchase =
        existing.isOneTimePurchase || incoming.isOneTimePurchase;
    return existing;
  }

  DateTime? _parseEmailDateHeader(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return HttpDate.parse(raw).toLocal();
    } catch (_) {
      return DateTime.tryParse(raw)?.toLocal();
    }
  }

  String _extractText(gmail.MessagePart? part) {
    if (part == null) return '';
    final chunks = <String>[];
    final data = part.body?.data;
    if (data != null && data.isNotEmpty) {
      try {
        final normalized = base64Url.normalize(data);
        var text =
            utf8.decode(base64Url.decode(normalized), allowMalformed: true);
        // Replace block tags with newlines
        text = text.replaceAll(
            RegExp(r'<(br|p|div|tr|li|h[1-6])[\s/>][^>]*>',
                caseSensitive: false),
            ' \n ');
        // Strip remaining HTML tags
        text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
        // Strip invisible zero-width chars that break regex
        text = text.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');
        // Collapse spaces
        text = text.replaceAll(RegExp(r'[ \t\f]+'), ' ');
        chunks.add(text);
      } catch (_) {}
    }
    for (final child in part.parts ?? const <gmail.MessagePart>[]) {
      final text = _extractText(child);
      if (text.isNotEmpty) chunks.add(text);
    }
    return chunks.join('\n');
  }

  String _prepareAiBody(String text) {
    var cleaned = text
        .replaceAll(RegExp(r'[ \t\f]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    const maxChars = 8000;
    if (cleaned.length <= maxChars) return cleaned;

    final lower = cleaned.toLowerCase();
    const anchors = [
      'next billing',
      'renewal',
      'renews',
      'subscription',
      'invoice',
      'receipt',
      'charged',
      'payment method',
      'card ending',
      'paid with',
      'trial ends',
    ];
    var firstAnchor = -1;
    for (final anchor in anchors) {
      final idx = lower.indexOf(anchor);
      if (idx >= 0 && (firstAnchor < 0 || idx < firstAnchor)) {
        firstAnchor = idx;
      }
    }
    if (firstAnchor < 0) {
      return cleaned.substring(0, maxChars);
    }

    final start = (firstAnchor - 2500).clamp(0, cleaned.length).toInt();
    final end = (firstAnchor + 5500).clamp(start, cleaned.length).toInt();
    return cleaned.substring(start, end);
  }
}

class _GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    request.headers.putIfAbsent('Accept', () => 'application/json');
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
