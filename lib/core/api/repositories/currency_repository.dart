import 'package:hive/hive.dart';

import '../api_client.dart';
import '../result.dart';

class CurrencyRepository {
  static const _directFallbackUrl =
      'https://v6.exchangerate-api.com/v6/65938f4994589a13920b4985/latest/INR';
  final ApiClient _api;
  final Box _cache;

  CurrencyRepository(this._api, this._cache);

  Future<Result<Map<String, double>>> getRates() async {
    try {
      final res = await _api.dio.get('/currency/rates');
      final data = res.data['data'] as Map<String, dynamic>;
      final rates = (data['rates'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
      _cache.put('currency_rates', rates);
      _cache.put('currency_rates_updated_at', data['updated_at']);
      _cache.put('currency_rates_updated', data['updated_at']);
      return Success(rates);
    } catch (e) {
      try {
        final fallbackRes = await _api.dio.get(_directFallbackUrl);
        final data = fallbackRes.data as Map<String, dynamic>;
        final rates = (data['conversion_rates'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
        final updatedAt = DateTime.now().toUtc().toIso8601String();
        _cache.put('currency_rates', rates);
        _cache.put('currency_rates_updated_at', updatedAt);
        _cache.put('currency_rates_updated', updatedAt);
        return Success(rates);
      } catch (_) {}

      final cached = _cache.get('currency_rates');
      if (cached != null) {
        return Success(Map<String, double>.from(cached));
      }
      return Failure(_errorMsg(e));
    }
  }

  Map<String, double>? getCachedRates() {
    final cached = _cache.get('currency_rates');
    if (cached == null) return null;
    return Map<String, double>.from(cached);
  }

  DateTime? getCachedUpdatedAt() {
    final raw =
        _cache.get('currency_rates_updated_at') ?? _cache.get('currency_rates_updated');
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  String _errorMsg(Object e) {
    if (e is AppError) return e.message;
    return e.toString();
  }
}
