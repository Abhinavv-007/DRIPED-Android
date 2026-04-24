import 'package:hive/hive.dart';

import '../../models/app_user.dart';
import '../api_client.dart';
import '../result.dart';

class UserRepository {
  final ApiClient _api;
  final Box _cache;

  UserRepository(this._api, this._cache);

  Future<Result<AppUser>> syncUser({
    required String email,
    String? fullName,
    String? avatarUrl,
    String? currency,
  }) async {
    try {
      final res = await _api.dio.post('/users/sync', data: {
        'email': email,
        'full_name': fullName,
        'avatar_url': avatarUrl,
        if (currency != null) 'currency': currency,
      });
      final data = res.data['data'] as Map<String, dynamic>;
      final user = AppUser.fromMap(data);
      _cache.put('current_user', data);
      return Success(user);
    } catch (e) {
      return Failure(_errorMsg(e));
    }
  }

  Result<AppUser> getCachedUser() {
    try {
      final raw = _cache.get('current_user');
      if (raw == null) return const Failure('No cached user');
      return Success(AppUser.fromMap(Map<String, dynamic>.from(raw)));
    } catch (_) {
      return const Failure('Corrupted cached user');
    }
  }

  String _errorMsg(Object e) {
    if (e is AppError) return e.message;
    return e.toString();
  }
}
