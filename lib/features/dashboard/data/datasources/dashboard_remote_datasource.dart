import 'package:dio/dio.dart';

import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/dashboard_metric_model.dart';
import '../models/subject_model.dart';

/// Handles all remote HTTP calls for the dashboard feature.
/// Injects the stored Bearer token before every request.
class DashboardRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  const DashboardRemoteDataSource(this._apiClient, this._storage);

  // ── Private helpers ──────────────────────────────────────────────────────

  Future<Options> _authOptions() async {
    final token = await _storage.getAccessToken();
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Exception _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final msg = _extractMessage(e);
    return switch (statusCode) {
      401 => Exception('Session expired. Please log in again.'),
      403 => Exception('You do not have permission to access this resource.'),
      500 => Exception('Server error. Please try again later.'),
      _ => Exception(
          e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.receiveTimeout
              ? 'Connection timeout. Check your network.'
              : msg.isNotEmpty
                  ? msg
                  : 'Something went wrong.',
        ),
    };
  }

  String _extractMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? '';
      }
    } catch (_) {}
    return '';
  }

  // ── Public API ───────────────────────────────────────────────────────────

  /// GET /api/admin/dashboard
  /// Returns a list of [DashboardMetricModel].
  Future<List<DashboardMetricModel>> fetchAdminDashboard() async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.adminDashboard,
        options: options,
      );
      // Backend: ApiResponse<DashboardResponse> → data.metrics
      final data = response.data!['data'] as Map<String, dynamic>;
      final metrics = data['metrics'] as List<dynamic>;
      return metrics
          .map((e) => DashboardMetricModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// GET /api/academic/subjects/my-subjects
  /// Returns a list of [SubjectModel] for the authenticated student.
  Future<List<SubjectModel>> fetchMySubjects() async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.mySubjects,
        options: options,
      );
      // Q3: SubjectController now always wraps in ApiResponse<> — read 'data' field
      final data = response.data?['data'];
      if (data is List) {
        return data
            .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }
}
