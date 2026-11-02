import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../constants/api_endpoints.dart';
import '../storage/secure_storage_service.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final storageService = ref.watch(secureStorageProvider);
  return ApiClient(storageService: storageService);
});

/// Singleton-safe Dio wrapper with:
/// - JWT auth interceptor (attaches Bearer token from SecureStorageService)
/// - Auto refresh token on 401 Unauthorized
/// - Error interceptor (maps Dio errors → typed Failures)
class ApiClient {
  final Dio dio;
  final Logger logger;
  final SecureStorageService storageService;

  ApiClient({
    Dio? dioClient,
    Logger? customLogger,
    SecureStorageService? storageService,
    void Function()? onUnauthorized,
  })  : storageService = storageService ?? SecureStorageService(),
        dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: ApiEndpoints.connectTimeout,
                receiveTimeout: ApiEndpoints.receiveTimeout,
                headers: {
                  'Accept': 'application/json',
                },
              ),
            ),
        logger = customLogger ?? Logger() {
    dio.interceptors.add(
      AuthInterceptor(
        storageService: this.storageService,
        onUnauthorized: onUnauthorized,
      ),
    );
    dio.interceptors.add(ErrorInterceptor());
    dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (obj) => logger.d(obj.toString()),
      ),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    return dio.put<T>(path, data: data, options: options);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    return dio.delete<T>(path, data: data, options: options);
  }

  Future<Response<T>> postMultipart<T>(
    String path, {
    required FormData formData,
    Options? options,
  }) async {
    return dio.post<T>(
      path,
      data: formData,
      options: options ??
          Options(contentType: 'multipart/form-data'),
    );
  }

  // Deprecated legacy helpers — preserved for smooth transition during feature refactoring
  @Deprecated('Use AuthInterceptor and SecureStorageService instead')
  void setAuthHeader(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  @Deprecated('Use AuthInterceptor and SecureStorageService instead')
  void clearAuthHeader() {
    dio.options.headers.remove('Authorization');
  }
}
