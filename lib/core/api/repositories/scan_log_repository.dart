import '../api_client.dart';
import '../result.dart';

class ScanLogRepository {
  final ApiClient _api;

  ScanLogRepository(this._api);

  Future<Result<Map<String, dynamic>>> logScan({
    required String scanType,
    required int emailsScanned,
    required int subscriptionsFound,
  }) async {
    try {
      final res = await _api.dio.post('/scan/log', data: {
        'scan_type': scanType,
        'emails_scanned': emailsScanned,
        'subscriptions_found': subscriptionsFound,
      });
      return Success(Map<String, dynamic>.from(res.data['data']));
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  String _errorMsg(Object e) {
    if (e is AppError) return e.message;
    return e.toString();
  }
}
