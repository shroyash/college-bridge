import 'package:dio/dio.dart';

import '../../../../app/constants/api_constants.dart';
import '../../../../core/error/auth_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../institution_admin/data/models/academic_level_model.dart';
import '../../../institution_admin/data/models/academic_program_model.dart';
import '../models/auth_user_model.dart';

/// Handles all remote HTTP calls for the auth feature.
/// Wraps ApiClient (Dio) and maps raw JSON to AuthUserModel.
class AuthRemoteDataSource {
  final ApiClient _apiClient;

  const AuthRemoteDataSource(this._apiClient);

  /// POST /api/auth/login
  /// Accepts [institutionCode] in addition to email/password.
  /// Maps backend 403 reason codes to [LoginFailureException].
  Future<AuthUserModel> login({
    required String institutionCode,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {
          'institutionCode': institutionCode,
          'email': email,
          'password': password,
        },
      );
      final rawData = response.data;
      if (rawData == null) {
        throw Exception('Server returned an empty response.');
      }
      return AuthUserModel.fromJson(rawData);
    } on DioException catch (e) {
      throw _mapLoginDioException(e);
    }
  }

  /// POST /api/auth/register  (student self-registration using levelId)
  Future<AuthUserModel> register({
    required String institutionCode,
    required String name,
    required String email,
    required String password,
    required int levelId,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: {
          'institutionCode': institutionCode,
          'name': name,
          'email': email,
          'password': password,
          'levelId': levelId,
        },
      );
      final rawData = response.data;
      if (rawData == null) {
        throw Exception('Server returned an empty response.');
      }
      return AuthUserModel.fromJson(rawData);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// GET /api/public/academic/institutions/{institutionCode}/programs
  Future<List<AcademicProgramModel>> getPublicPrograms(String institutionCode) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.publicInstitutionPrograms(institutionCode),
      );
      final data = response.data?['data'];
      if (data is List) {
        return data
            .map((e) => AcademicProgramModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// GET /api/public/academic/programs/{programId}/levels
  Future<List<AcademicLevelModel>> getPublicLevels(int programId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.publicProgramLevels(programId),
      );
      final data = response.data?['data'];
      if (data is List) {
        return data
            .map((e) => AcademicLevelModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// POST /api/auth/logout
  Future<void> logout({required String refreshToken}) async {
    try {
      await _apiClient.post<dynamic>(
        ApiConstants.logout,
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// POST /api/auth/password/forgot
  Future<void> forgotPassword({required String email}) async {
    try {
      await _apiClient.post<dynamic>(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// POST /api/auth/password/resend-otp
  Future<void> resendOtp({required String email}) async {
    try {
      await _apiClient.post<dynamic>(
        ApiConstants.resendOtp,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// POST /api/otp/send (REGISTRATION)
  Future<void> sendRegistrationOtp({required String email}) async {
    try {
      await _apiClient.post<dynamic>(
        '/api/otp/send',
        data: {
          'email': email,
          'type': 'REGISTRATION',
        },
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// POST /api/otp/verify (REGISTRATION)
  Future<String> verifyRegistrationOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/otp/verify',
        data: {
          'email': email,
          'code': code,
          'type': 'REGISTRATION',
        },
      );
      final rawData = response.data?['data'];
      if (rawData is String) return rawData;
      if (rawData is Map<String, dynamic>) {
        return (rawData['verificationToken'] ?? rawData['token'] ?? '') as String;
      }
      return 'VERIFIED';
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// POST /api/auth/verify-otp
  Future<String> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.verifyOtp,
        data: {
          'email': email,
          'code': code,
          'type': 'PASSWORD_RESET',
        },
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return data['verificationToken'] as String;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// POST /api/auth/reset-password
  Future<void> resetPassword({
    required String email,
    required String verificationToken,
    required String newPassword,
  }) async {
    try {
      await _apiClient.post<dynamic>(
        ApiConstants.resetPassword,
        data: {
          'email': email,
          'verificationToken': verificationToken,
          'newPassword': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Exception Mappers ────────────────────────────────────────────────────

  /// Special mapper for login that decodes backend reason codes.
  Exception _mapLoginDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (statusCode == 403 && data is Map<String, dynamic>) {
      final errorCode = data['errorCode'] as String? ?? '';
      final message = data['message'] as String? ?? 'Access denied.';
      final rejectionReason = data['rejectionReason'] as String?;

      return switch (errorCode) {
        'INSTITUTION_PENDING' => LoginFailureException(
            reason: LoginFailureReason.institutionPending,
            message: message,
          ),
        'INSTITUTION_REJECTED' => LoginFailureException(
            reason: LoginFailureReason.institutionRejected,
            message: message,
            rejectionReason: rejectionReason,
          ),
        'INSTITUTION_SUSPENDED' => LoginFailureException(
            reason: LoginFailureReason.institutionSuspended,
            message: message,
          ),
        'USER_SUSPENDED' => LoginFailureException(
            reason: LoginFailureReason.userSuspended,
            message: message,
          ),
        'USER_INACTIVE' => LoginFailureException(
            reason: LoginFailureReason.userInactive,
            message: message,
          ),
        _ => LoginFailureException(
            reason: LoginFailureReason.unknown,
            message: message,
          ),
      };
    }

    if (statusCode == 401) {
      return LoginFailureException(
        reason: LoginFailureReason.invalidCredentials,
        message: _extractMessage(e).isNotEmpty
            ? _extractMessage(e)
            : 'Invalid email or password.',
      );
    }

    return _mapDioException(e);
  }

  Exception _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e);
    return switch (statusCode) {
      400 => Exception(message.isNotEmpty ? message : 'Invalid request.'),
      401 => Exception('Invalid credentials. Please try again.'),
      409 => Exception('An account with this email already exists.'),
      500 => Exception('Server error. Please try again later.'),
      _ => Exception(
          e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.receiveTimeout
              ? 'Connection timeout. Check your network.'
              : message.isNotEmpty
                  ? message
                  : 'Something went wrong.',
        ),
    };
  }

  String _extractMessage(DioException e) {
    try {
      final responseData = e.response?.data;
      if (responseData is Map<String, dynamic>) {
        return responseData['message'] as String? ?? '';
      }
    } catch (_) {}
    return '';
  }
}
