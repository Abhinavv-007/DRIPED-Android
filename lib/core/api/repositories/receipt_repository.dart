import 'package:hive/hive.dart';

import '../api_client.dart';
import '../result.dart';

class ReceiptRef {
  final String id;
  final String? subscriptionId;
  final String? subject;
  final String? sender;
  final String? snippet;
  final double? amount;
  final String? currency;
  final DateTime? chargedAt;
  final DateTime createdAt;

  const ReceiptRef({
    required this.id,
    required this.subscriptionId,
    required this.subject,
    required this.sender,
    required this.snippet,
    required this.amount,
    required this.currency,
    required this.chargedAt,
    required this.createdAt,
  });

  factory ReceiptRef.fromMap(Map<String, dynamic> m) => ReceiptRef(
        id: m['id'] as String,
        subscriptionId: m['subscription_id'] as String?,
        subject: m['subject'] as String?,
        sender: m['sender'] as String?,
        snippet: m['snippet'] as String?,
        amount: (m['amount'] as num?)?.toDouble(),
        currency: m['currency'] as String?,
        chargedAt: DateTime.tryParse(m['charged_at'] as String? ?? ''),
        createdAt: DateTime.tryParse(m['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class ReceiptRepository {
  final ApiClient _api;
  final Box _cache;

  ReceiptRepository(this._api, this._cache);

  Future<Result<List<ReceiptRef>>> forSubscription(String subscriptionId) async {
    try {
      final res = await _api.dio.get('/receipts/$subscriptionId');
      final list = (res.data['data'] as List)
          .map((m) => ReceiptRef.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList();
      _cache.put('receipts_$subscriptionId',
          (res.data['data'] as List).cast<Map>());
      return Success(list);
    } catch (e) {
      final cached = _cache.get('receipts_$subscriptionId');
      if (cached is List) {
        return Success(
          cached
              .map((m) => ReceiptRef.fromMap(Map<String, dynamic>.from(m as Map)))
              .toList(),
        );
      }
      return Failure(_errorMsg(e));
    }
  }

  Future<Result<String>> upload({
    required String emailHash,
    String? subscriptionId,
    String? gmailMessageId,
    String? subject,
    String? sender,
    String? snippet,
    double? amount,
    String? currency,
    DateTime? chargedAt,
  }) async {
    try {
      final res = await _api.dio.post('/receipts', data: {
        'email_hash': emailHash,
        if (subscriptionId != null) 'subscription_id': subscriptionId,
        if (gmailMessageId != null) 'gmail_message_id': gmailMessageId,
        if (subject != null) 'subject': subject,
        if (sender != null) 'sender': sender,
        if (snippet != null) 'snippet': snippet,
        if (amount != null) 'amount': amount,
        if (currency != null) 'currency': currency,
        if (chargedAt != null) 'charged_at': chargedAt.toIso8601String(),
      });
      return Success(res.data['data']['id'] as String);
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  String _errorMsg(Object e) {
    if (e is AppError) return e.message;
    return e.toString();
  }
}
