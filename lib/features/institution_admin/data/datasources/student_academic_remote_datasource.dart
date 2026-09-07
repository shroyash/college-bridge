import 'package:dio/dio.dart';

import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../institution_admin/data/models/class_detail_model.dart';

class StudentAcademicRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  const StudentAcademicRemoteDataSource(this._apiClient, this._storage);

  Future<Options> _authOptions() async {
    final token = await _storage.getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Exception _mapDioError(DioException e) {
    final code = e.response?.statusCode;
    if (code == 401) return Exception('Session expired. Please log in again.');
    if (code == 404) return Exception('You are not currently enrolled in any class.');
    return Exception('Something went wrong. Please try again.');
  }

  /// GET /api/student/academic/class-details
  Future<ClassDetailModel?> fetchMyClassDetails() async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.studentClassDetails,
        options: options,
      );
      final rawData = response.data;
      if (rawData == null || rawData['data'] == null) {
        return null;
      }
      final dataRaw = rawData['data'];
      if (dataRaw is! Map) return null;
      return ClassDetailModel.fromJson(Map<String, dynamic>.from(dataRaw));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _mapDioError(e);
    }
  }
}
