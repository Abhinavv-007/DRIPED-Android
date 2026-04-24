import 'package:hive/hive.dart';

import '../../models/payment_method.dart';
import '../api_client.dart';
import '../result.dart';

class PaymentMethodRepository {
  final ApiClient _api;
  final Box _cache;

  PaymentMethodRepository(this._api, this._cache);

  Future<Result<List<PaymentMethod>>> getAll() async {
    try {
      final res = await _api.dio.get('/payment-methods');
      final list = (res.data['data'] as List)
          .map((e) => PaymentMethod.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _cache.put('payment_methods', res.data['data']);
      return Success(list);
    } catch (e) {
      final cached = _cache.get('payment_methods');
      if (cached != null) {
        final list = (cached as List)
            .map((e) => PaymentMethod.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        return Success(list);
      }
      return Failure(_errorMsg(e));
    }
  }

  Future<Result<PaymentMethod>> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.post('/payment-methods', data: data);
      final pm =
          PaymentMethod.fromMap(Map<String, dynamic>.from(res.data['data']));
      return Success(pm);
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  Future<Result<PaymentMethod>> update(
      String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.put('/payment-methods/$id', data: data);
      final pm =
          PaymentMethod.fromMap(Map<String, dynamic>.from(res.data['data']));
      return Success(pm);
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await _api.dio.delete('/payment-methods/$id');
      return const Success(null);
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  String _errorMsg(Object e) {
    if (e is AppError) return e.message;
    return e.toString();
  }
}
