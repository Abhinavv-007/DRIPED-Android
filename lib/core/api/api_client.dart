import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Human-readable error wrapper.
class AppError implements Exception {
  final String message;
  final int? statusCode;
  const AppError(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  late final Dio _dio;

  ApiClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? _defaultWorkerUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  Dio get dio => _dio;
}

/// Attaches Firebase ID token to every request.
class _AuthInterceptor extends Interceptor {
  String? _cachedToken;
  DateTime? _tokenExpiry;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (_isPublicRequest(options.path)) {
          handler.next(options);
          return;
        }
        return handler.reject(
          DioException(
            requestOptions: options,
            error: const AppError('Not authenticated'),
          ),
        );
      }

      // Refresh if within 5 min of expiry or no cached token
      final now = DateTime.now();
      final needsRefresh = _cachedToken == null ||
          _tokenExpiry == null ||
          _tokenExpiry!.difference(now).inMinutes < 5;

      if (needsRefresh) {
        final idTokenResult = await user.getIdTokenResult(true);
        _cachedToken = idTokenResult.token;
        _tokenExpiry = idTokenResult.expirationTime;
      }

      options.headers['Authorization'] = 'Bearer $_cachedToken';
      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: AppError('Auth token error: $e'),
        ),
      );
    }
  }

  bool _isPublicRequest(String path) {
    return path == '/currency/rates' || path.startsWith('/currency/');
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Sign out on 401 — router redirect handles navigation
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    }
    handler.next(err);
  }
}

/// Wraps DioException into AppError with human-readable message.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message;
    final statusCode = err.response?.statusCode;

    if (err.response?.data is Map) {
      final data = err.response!.data as Map;
      message = (data['error'] as String?) ?? _fallbackMessage(err);
    } else {
      message = _fallbackMessage(err);
    }

    if (kDebugMode) {
      debugPrint('[API Error] $statusCode: $message');
    }

    handler.next(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      error: AppError(message, statusCode: statusCode),
    ));
  }

  String _fallbackMessage(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check your internet.';
      case DioExceptionType.connectionError:
        return 'No internet connection.';
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        if (code == 401) return 'Session expired. Please sign in again.';
        if (code == 404) return 'Resource not found.';
        if (code == 409) return 'Conflict — resource is in use.';
        if (code >= 500) return 'Server error. Try again later.';
        return 'Request failed ($code).';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

/// API base URL resolution:
///   1. `--dart-define=WORKER_URL=…`  \u2192 explicit override (CI / local dev).
///   2. Debug builds  \u2192 platform-appropriate localhost so `wrangler dev` works.
///   3. Release builds  \u2192 https://api.driped.in (production).
///
/// Emulator note: Android emulator reaches the host machine at 10.0.2.2.
String get _defaultWorkerUrl {
  const envUrl = String.fromEnvironment('WORKER_URL');
  if (envUrl.isNotEmpty) return envUrl;

  // Release builds always go to production.
  if (kReleaseMode) return 'https://api.driped.in';

  // Debug / profile: try local first so the dev loop works offline.
  if (kIsWeb) return 'http://localhost:8787';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8787';
  }
  return 'http://localhost:8787';
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: _defaultWorkerUrl);
});
