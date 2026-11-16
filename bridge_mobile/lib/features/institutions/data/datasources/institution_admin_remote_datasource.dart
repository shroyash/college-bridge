import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/institution_models.dart';

/// Remote data source for all institution admin operations.
class InstitutionAdminRemoteDataSource {
  final ApiClient _apiClient;

  const InstitutionAdminRemoteDataSource(this._apiClient);

  // ── Public: Institution Registration ──────────────────────────────────────

  /// POST /api/auth/register-institution (multipart)
  Future<InstitutionRegistrationResultModel> registerInstitution({
    required String institutionName,
    required String institutionCode,
    required String adminName,
    required String adminEmail,
    required String adminPassword,
    required List<MapEntry<String, MultipartFile>> documents, // filename → file
  }) async {
    final requestJson = jsonEncode({
      'name': institutionName,
      'code': institutionCode,
      'adminName': adminName,
      'adminEmail': adminEmail,
      'adminPassword': adminPassword,
    });

    final formData = FormData();
    formData.files.add(
      MapEntry(
        'request',
        MultipartFile.fromString(
          requestJson,
          contentType: MediaType('application', 'json'),
        ),
      ),
    );

    for (final doc in documents) {
      formData.files.add(MapEntry('documents', doc.value));
    }

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.institutionRegister,
        data: formData,
      );
      final data = response.data!['data'] as Map<String, dynamic>;
      return InstitutionRegistrationResultModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  // ── Super Admin: Pending Institutions ─────────────────────────────────────

  /// GET /api/admin/institutions/pending
  Future<List<PendingInstitutionModel>> getPendingInstitutions() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.superAdminInstitutionsPending,
      );
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((e) => PendingInstitutionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// POST /api/admin/institutions/{id}/approve
  Future<void> approveInstitution(int institutionId) async {
    try {
      await _apiClient.post<dynamic>(
        '${ApiConstants.superAdminInstitutions}/$institutionId/approve',
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// POST /api/admin/institutions/{id}/reject
  Future<void> rejectInstitution(int institutionId, String rejectionReason) async {
    try {
      await _apiClient.post<dynamic>(
        '${ApiConstants.superAdminInstitutions}/$institutionId/reject',
        data: {'rejectionReason': rejectionReason},
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  // ── Super Admin: Active Institutions ──────────────────────────────────────

  /// GET /api/admin/institutions  (active + suspended)
  Future<List<ManagedInstitutionModel>> getManagedInstitutions() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.superAdminInstitutions,
      );
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((e) => ManagedInstitutionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// POST /api/admin/institutions/{id}/suspend
  Future<void> suspendInstitution(int institutionId) async {
    try {
      await _apiClient.post<dynamic>(
        '${ApiConstants.superAdminInstitutions}/$institutionId/suspend',
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// POST /api/admin/institutions/{id}/reactivate
  Future<void> reactivateInstitution(int institutionId) async {
    try {
      await _apiClient.post<dynamic>(
        '${ApiConstants.superAdminInstitutions}/$institutionId/reactivate',
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Exception _mapException(DioException e) {
    final statusCode = e.response?.statusCode;
    String message = '';
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? '';
    }
    return switch (statusCode) {
      400 => Exception(message.isNotEmpty ? message : 'Invalid request.'),
      401 => Exception('Session expired. Please login again.'),
      403 => Exception('Access denied. Super admin role required.'),
      404 => Exception('Institution not found.'),
      409 => Exception(message.isNotEmpty ? message : 'Conflict: already exists.'),
      500 => Exception('Server error. Please try again later.'),
      _ => Exception(
          e.type == DioExceptionType.connectionTimeout
              ? 'Connection timeout.'
              : message.isNotEmpty
                  ? message
                  : 'Something went wrong.',
        ),
    };
  }
}
