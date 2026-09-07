import 'package:equatable/equatable.dart';

/// Standardized API response wrapper matching Spring Boot [ApiResponse<T>]:
/// {
///   "success": true,
///   "message": "...",
///   "data": { ... }
/// }
class ApiResponse<T> extends Equatable {
  final bool success;
  final String message;
  final T? data;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    dynamic rawData = json['data'];

    // Handle Map<dynamic, dynamic> safety from Dio/json decoding
    if (rawData is Map && rawData is! Map<String, dynamic>) {
      rawData = Map<String, dynamic>.from(rawData);
    }

    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: (rawData != null && fromJsonT != null)
          ? fromJsonT(rawData)
          : rawData as T?,
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}
