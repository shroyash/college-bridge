import 'package:dio/dio.dart';

import '../error/failures.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = _mapDioExceptionToFailure(err);

    final customException = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: failure,
    );

    handler.next(customException);
  }

  static Failure _mapDioExceptionToFailure(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return const NetworkFailure(
        'No internet connection. Please check your network.',
      );
    }

    final response = err.response;

    if (response == null) {
      return const NetworkFailure(
        'Network error occurred. Please try again.',
      );
    }

    final statusCode = response.statusCode ?? 500;
    final data = response.data;

    String serverMsg = '';

    if (data is Map<String, dynamic>) {
      serverMsg =
          data['detail'] as String? ??
          data['message'] as String? ??
          data['error'] as String? ??
          data['title'] as String? ??
          '';
    } else if (data is String) {
      serverMsg = data;
    }

    switch (statusCode) {
      case 400:
        Map<String, String>? fieldErrors;

        if (data is Map<String, dynamic> && data['errors'] is Map) {
          fieldErrors = (data['errors'] as Map).map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          );
        }

        return ValidationFailure(
          serverMsg.isNotEmpty
              ? serverMsg
              : 'Invalid request payload. Please check your inputs.',
          statusCode: 400,
          fieldErrors: fieldErrors,
        );

      case 401:
        return UnauthorizedFailure(
          serverMsg.isNotEmpty
              ? serverMsg
              : 'Invalid credentials. Please try again.',
        );

      case 403:
        return ForbiddenFailure(
          serverMsg.isNotEmpty
              ? serverMsg
              : 'Account not verified.',
        );

      case 404:
        return NotFoundFailure(
          serverMsg.isNotEmpty
              ? serverMsg
              : 'User not found.',
        );

      case 409:
        return ConflictFailure(
          serverMsg.isNotEmpty
              ? serverMsg
              : 'Email already exists.',
        );

      case 429:
        return RateLimitFailure(
          serverMsg.isNotEmpty
              ? serverMsg
              : 'Too many attempts. Please try again later.',
        );

      case 500:
      default:
        return ServerFailure(
          serverMsg.isNotEmpty
              ? serverMsg
              : 'Unexpected server error. Please try again later.',
          statusCode: statusCode,
        );
    }
  }
}