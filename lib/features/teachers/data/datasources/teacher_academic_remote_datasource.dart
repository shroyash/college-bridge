import 'package:dio/dio.dart';

import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import 'package:bridge_mobile/features/academics/data/models/academic_class_model.dart';
import 'package:bridge_mobile/features/academics/data/models/class_detail_model.dart';

class TeacherAcademicRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  const TeacherAcademicRemoteDataSource(this._apiClient, this._storage);

  Future<Options> _authOptions() async {
    final token = await _storage.getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Exception _mapDioError(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401) return Exception('Session expired. Please log in again.');
    if (code == 403) return Exception('You are not authorised to access this class.');
    if (code == 404) return Exception('Class not found.');
    return Exception('Something went wrong. Please try again.');
  }

  /// GET /api/academic/subjects/my-subjects
  ///
  /// Q3: SubjectController now wraps all responses in ApiResponse<> — read 'data' field.
  Future<List<AcademicClassModel>> fetchMyClasses() async {
    try {
      final options = await _authOptions();
      try {
        final response = await _apiClient.get<Map<String, dynamic>>(
          ApiConstants.teacherMySubjects,
          options: options,
        );
        // Q3 fix: always read from response['data']
        final data = response.data?['data'];
        if (data is List && data.isNotEmpty) {
          return data
              .map((e) => AcademicClassModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        // Empty list from my-subjects — fall through to my-classes
      } catch (_) {
        // Fallback to my-classes if my-subjects fails
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.teacherMyClasses,
        options: options,
      );
      final data = response.data!['data'] as List<dynamic>;
      return data
          .map((e) => AcademicClassModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// GET /api/academic/subjects/{subjectId}/details
  ///
  /// Q3: SubjectController now wraps all responses in ApiResponse<> — read 'data' field.
  Future<ClassDetailModel> fetchClassDetails(int classId) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/academic/subjects/$classId/details',
        options: options,
      );
      // Q3 fix: always read from response['data']
      final data = response.data?['data'] as Map<String, dynamic>?;
      return ClassDetailModel.fromJson(data ?? {});
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }
}
