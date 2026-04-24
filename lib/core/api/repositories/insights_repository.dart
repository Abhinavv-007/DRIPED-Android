import 'package:hive/hive.dart';

import '../api_client.dart';
import '../result.dart';

/// Maps the Worker's `/insights/*` endpoints. Returns plain maps to keep
/// the repo dependency-light; screens parse into their own view-models.
class InsightsRepository {
  final ApiClient _api;
  final Box _cache;

  InsightsRepository(this._api, this._cache);

  /// `/insights/savings` \u2014 cancel candidates, ghosts, duplicates, annual hints.
  Future<Result<Map<String, dynamic>>> savings() async {
    try {
      final res = await _api.dio.get('/insights/savings');
      final data = Map<String, dynamic>.from(res.data['data'] ?? {});
      _cache.put('insights_savings', data);
      return Success(data);
    } catch (e) {
      final cached = _cache.get('insights_savings');
      if (cached is Map) {
        return Success(Map<String, dynamic>.from(cached));
      }
      return Failure(_errorMsg(e));
    }
  }

  /// `/insights/forecast?months=N` \u2014 month-by-month spend projection.
  Future<Result<List<Map<String, dynamic>>>> forecast({int months = 12}) async {
    try {
      final res = await _api.dio.get(
        '/insights/forecast',
        queryParameters: {'months': months},
      );
      final list = (res.data['data']['months'] as List)
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();
      _cache.put('insights_forecast_$months', list);
      return Success(list);
    } catch (e) {
      final cached = _cache.get('insights_forecast_$months');
      if (cached is List) {
        return Success(
          cached.map((m) => Map<String, dynamic>.from(m as Map)).toList(),
        );
      }
      return Failure(_errorMsg(e));
    }
  }

  /// `/insights/calendar?days=N` \u2014 flat list of upcoming charges.
  Future<Result<List<Map<String, dynamic>>>> calendar({int days = 90}) async {
    try {
      final res = await _api.dio.get(
        '/insights/calendar',
        queryParameters: {'days': days},
      );
      final list = (res.data['data']['charges'] as List)
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();
      _cache.put('insights_calendar_$days', list);
      return Success(list);
    } catch (e) {
      final cached = _cache.get('insights_calendar_$days');
      if (cached is List) {
        return Success(
          cached.map((m) => Map<String, dynamic>.from(m as Map)).toList(),
        );
      }
      return Failure(_errorMsg(e));
    }
  }

  /// `/insights/what-if` \u2014 simulate cancelling a set of subscriptions.
  Future<Result<Map<String, dynamic>>> whatIf(List<String> cancelIds) async {
    try {
      final res = await _api.dio.post(
        '/insights/what-if',
        data: {'cancel_subscription_ids': cancelIds},
      );
      return Success(Map<String, dynamic>.from(res.data['data'] ?? {}));
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  String _errorMsg(Object e) {
    if (e is AppError) return e.message;
    return e.toString();
  }
}
