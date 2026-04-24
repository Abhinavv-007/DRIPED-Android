import 'package:hive/hive.dart';

import '../../models/subscription.dart';
import '../api_client.dart';
import '../result.dart';

class SubscriptionRepository {
  final ApiClient _api;
  final Box _cache;

  SubscriptionRepository(this._api, this._cache);

  Future<Result<List<Subscription>>> getAll({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;

      final res = await _api.dio.get('/subscriptions',
          queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final list = (res.data['data'] as List)
          .map((e) => Subscription.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _cache.put('subscriptions', res.data['data']);
      return Success(list);
    } catch (e) {
      // Fallback to cache
      final cached = _cache.get('subscriptions');
      if (cached != null) {
        final list = (cached as List)
            .map((e) => Subscription.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        return Success(list);
      }
      return Failure(_errorMsg(e));
    }
  }

  Future<Result<Subscription>> create(Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.post('/subscriptions', data: data);
      final sub =
          Subscription.fromMap(Map<String, dynamic>.from(res.data['data']));
      return Success(sub);
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  Future<Result<Subscription>> update(
      String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.dio.put('/subscriptions/$id', data: data);
      final sub =
          Subscription.fromMap(Map<String, dynamic>.from(res.data['data']));
      return Success(sub);
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await _api.dio.delete('/subscriptions/$id');
      return const Success(null);
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  Future<Result<Subscription>> getById(String id) async {
    try {
      // Server doesn't have GET by id; use list + filter
      final all = await getAll();
      return all.when(
        success: (list) {
          final sub = list.where((s) => s.id == id).firstOrNull;
          if (sub == null) return const Failure('Subscription not found');
          return Success(sub);
        },
        failure: (msg) => Failure(msg),
      );
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  String _errorMsg(Object e) {
    if (e is AppError) return e.message;
    return e.toString();
  }
}
