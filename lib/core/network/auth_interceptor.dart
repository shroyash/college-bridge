import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../constants/api_endpoints.dart';

/// Intercepts every outgoing request and attaches the Bearer token from
/// secure storage. Also handles 401 responses by attempting a refresh token flow,
/// or calling [onUnauthorized] to trigger a global logout if refresh fails.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final void Function()? onUnauthorized;
  final Dio? _refreshDio;

  AuthInterceptor({
    required SecureStorageService storageService,
    this.onUnauthorized,
    Dio? refreshDio,
  })  : _storageService = storageService,
        _refreshDio = refreshDio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Don't attach tokens to public endpoints
    final isPublic = _isPublicPath(options.path);
    if (!isPublic) {
      final token = await _storageService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isPublicPath(err.requestOptions.path)) {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final dio = _refreshDio ?? Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
          final response = await dio.post(
            ApiEndpoints.refreshToken,
            data: {'refreshToken': refreshToken},
          );

          if (response.statusCode == 200 && response.data != null) {
            final data = response.data['data'];
            if (data != null && data['accessToken'] != null) {
              final newAccessToken = data['accessToken'] as String;
              final newRefreshToken = (data['refreshToken'] as String?) ?? refreshToken;

              await _storageService.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken,
              );

              // Retry original request with new access token
              final opts = err.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';

              final cloneDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
              final retryResponse = await cloneDio.fetch(opts);
              return handler.resolve(retryResponse);
            }
          }
        } catch (_) {
          // Token refresh failed
        }
      }

      // If refresh fails or no refresh token exists, trigger logout
      onUnauthorized?.call();
    }
    handler.next(err);
  }

  bool _isPublicPath(String path) {
    const publicPaths = [
      '/api/auth/login',
      '/api/auth/register',
      '/api/auth/password/',
      '/api/auth/refresh',
      '/api/auth/register-institution',
      '/api/public/',
    ];
    return publicPaths.any((p) => path.contains(p));
  }
}
