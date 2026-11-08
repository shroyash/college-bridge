import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/page_response.dart';
import '../models/holiday_notice_models.dart';

class HolidayNoticeRemoteDataSource {
  final ApiClient _client;

  HolidayNoticeRemoteDataSource(this._client);

  Future<PendingNoticeModel?> getPendingNotice() async {
    final response = await _client.get('/api/admin/holiday-notices/pending');
    final json = response.data;

    if (json is Map<String, dynamic>) {
      final apiResponse = ApiResponse<PendingNoticeModel?>.fromJson(
        json,
        (data) => data != null
            ? PendingNoticeModel.fromJson(Map<String, dynamic>.from(data as Map))
            : null,
      );
      return apiResponse.data;
    }
    return null;
  }

  Future<InstitutionNoticeModel> getNoticeById(int id) async {
    final response = await _client.get('/api/admin/holiday-notices/$id');
    final json = response.data as Map<String, dynamic>;

    final apiResponse = ApiResponse<InstitutionNoticeModel>.fromJson(
      json,
      (data) => InstitutionNoticeModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
    return apiResponse.data!;
  }

  Future<InstitutionNoticeModel> approveNotice({
    required int id,
    required String variant,
    String? customTitle,
    String? customBody,
    required bool notifyStudents,
    required bool notifyTeachers,
  }) async {
    final payload = <String, dynamic>{
      'variant': variant,
      if (customTitle != null && customTitle.trim().isNotEmpty)
        'customTitle': customTitle.trim(),
      if (customBody != null && customBody.trim().isNotEmpty)
        'customBody': customBody.trim(),
      'notifyStudents': notifyStudents,
      'notifyTeachers': notifyTeachers,
    };

    final response = await _client.post(
      '/api/admin/holiday-notices/$id/approve',
      data: payload,
    );
    final json = response.data as Map<String, dynamic>;

    final apiResponse = ApiResponse<InstitutionNoticeModel>.fromJson(
      json,
      (data) => InstitutionNoticeModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
    return apiResponse.data!;
  }

  Future<InstitutionNoticeModel> rejectNotice(int id) async {
    final response = await _client.post('/api/admin/holiday-notices/$id/reject');
    final json = response.data as Map<String, dynamic>;

    final apiResponse = ApiResponse<InstitutionNoticeModel>.fromJson(
      json,
      (data) => InstitutionNoticeModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );
    return apiResponse.data!;
  }

  Future<PageResponse<InstitutionNoticeModel>> getHistory({
    int page = 0,
    int size = 10,
  }) async {
    final response = await _client.get(
      '/api/admin/holiday-notices/history',
      queryParameters: {
        'page': page,
        'size': size,
      },
    );
    final json = response.data as Map<String, dynamic>;

    // Response wraps Spring Page in ApiResponse.data
    final dataMap = json['data'] as Map<String, dynamic>? ?? json;
    return PageResponse<InstitutionNoticeModel>.fromJson(
      dataMap,
      (item) => InstitutionNoticeModel.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<OfficialNoticeModel?> getOfficialNotice({
    required int institutionId,
    required String date,
  }) async {
    final response = await _client.get(
      '/api/holiday-notices/official',
      queryParameters: {
        'institutionId': institutionId,
        'date': date,
      },
    );
    final json = response.data;
    if (json is Map<String, dynamic>) {
      final apiResponse = ApiResponse<OfficialNoticeModel?>.fromJson(
        json,
        (data) => data != null
            ? OfficialNoticeModel.fromJson(Map<String, dynamic>.from(data as Map))
            : null,
      );
      return apiResponse.data;
    }
    return null;
  }
}
