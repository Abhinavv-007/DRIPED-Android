import 'package:hive/hive.dart';

import '../../models/payment_history_entry.dart';
import '../api_client.dart';
import '../result.dart';

class PaymentHistoryRepository {
  final ApiClient _api;
  final Box _cache;

  PaymentHistoryRepository(this._api, this._cache);

  Future<Result<List<PaymentHistoryEntry>>> getBySubscription(
      String subscriptionId) async {
    try {
      final res = await _api.dio.get('/payment-history',
          queryParameters: {'subscription_id': subscriptionId});
      final list = (res.data['data'] as List)
          .map((e) =>
              PaymentHistoryEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _cache.put('history_$subscriptionId', res.data['data']);
      return Success(list);
    } catch (e) {
      final cached = _cache.get('history_$subscriptionId');
      if (cached != null) {
        final list = (cached as List)
            .map((e) =>
                PaymentHistoryEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        return Success(list);
      }
      return Failure(_errorMsg(e));
    }
  }

  Future<Result<int>> bulkInsert(
      List<Map<String, dynamic>> entries) async {
    try {
      final res = await _api.dio.post('/payment-history/bulk', data: {
        'entries': entries,
      });
      return Success(res.data['inserted'] as int? ?? 0);
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  String _errorMsg(Object e) {
    if (e is AppError) return e.message;
    return e.toString();
  }
}
