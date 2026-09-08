import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure(this.message, {this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    super.statusCode,
  });
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(
    super.message, {
    super.statusCode,
    this.fieldErrors,
  });

  @override
  List<Object?> get props => [
        message,
        statusCode,
        fieldErrors,
      ];
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Invalid credentials. Please try again.',
  ]) : super(
          statusCode: 401,
        );
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
    super.message = 'Your account is not verified yet.',
  ]) : super(
          statusCode: 403,
        );
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'User account not found.',
  ]) : super(
          statusCode: 404,
        );
}

class ConflictFailure extends Failure {
  const ConflictFailure([
    super.message = 'An account with this email already exists.',
  ]) : super(
          statusCode: 409,
        );
}

class RateLimitFailure extends Failure {
  const RateLimitFailure([
    super.message = 'Too many attempts. Please try again later.',
  ]) : super(
          statusCode: 429,
        );
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([
    super.message = 'An unexpected error occurred.',
  ]);
}

String extractErrorMessage(Object error) {
  if (error is DioException) {
    final inner = error.error;
    if (inner is Failure) {
      return inner.message;
    }
    if (error.response?.data is Map<String, dynamic>) {
      final msg = error.response!.data['message'] as String? ??
          error.response!.data['error'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    }
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }
  if (error is Failure) {
    return error.message;
  }
  return error.toString().replaceAll('Exception: ', '');
}