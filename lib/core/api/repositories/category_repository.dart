import 'package:hive/hive.dart';

import '../../models/app_category.dart';
import '../api_client.dart';
import '../result.dart';

class CategoryRepository {
  final ApiClient _api;
  final Box _cache;

  CategoryRepository(this._api, this._cache);

  Future<Result<List<AppCategory>>> getAll() async {
    try {
      final res = await _api.dio.get('/categories');
      final list = (res.data['data'] as List)
          .map((e) => AppCategory.fromMap(Map<String, dynamic>.from(e)))
          .toList();
      _cache.put('categories', res.data['data']);
      return Success(list);
    } catch (e) {
      final cached = _cache.get('categories');
      if (cached != null) {
        final list = (cached as List)
            .map((e) => AppCategory.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        return Success(list);
      }
      return Failure(_errorMsg(e));
    }
  }

  Future<Result<AppCategory>> updateBudget(
      String id, double? budgetLimit) async {
    try {
      final res = await _api.dio.put('/categories/$id', data: {
        'budget_limit': budgetLimit,
      });
      final cat =
          AppCategory.fromMap(Map<String, dynamic>.from(res.data['data']));
      return Success(cat);
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  String _errorMsg(Object e) {
    if (e is AppError) return e.message;
    return e.toString();
  }
}
