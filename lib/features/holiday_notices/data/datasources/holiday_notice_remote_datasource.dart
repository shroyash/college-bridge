import '../../../../core/network/api_client.dart';
import '../../../../core/network/page_response.dart';
import '../models/holiday_notice_models.dart';

class HolidayNoticeRemoteDataSource {
  final ApiClient _client;

  HolidayNoticeRemoteDataSource(this._client);

  Future<PendingNoticeModel?> getPendingNotice() async {
    final response = await _client.get('/api/admin/holiday-notices/pending');
    final json = response.data;

    if (json is Map<String, dynamic>) {
      final rawData = json.containsKey('data') ? json['data'] : json;
      if (rawData is List) {
        if (rawData.isEmpty) return null;
        return PendingNoticeModel.fromJson(Map<String, dynamic>.from(rawData.first as Map));
      }
      if (rawData is Map) {
        return PendingNoticeModel.fromJson(Map<String, dynamic>.from(rawData));
      }
      return null;
    } else if (json is List) {
      if (json.isEmpty) return null;
      return PendingNoticeModel.fromJson(Map<String, dynamic>.from(json.first as Map));
    }
    return null;
  }

  Future<InstitutionNoticeModel> getNoticeById(int id) async {
    final response = await _client.get('/api/admin/holiday-notices/$id');
    final json = response.data;

    if (json is Map<String, dynamic>) {
      final dataMap = json.containsKey('data') && json['data'] is Map
          ? json['data'] as Map
          : json;
      return InstitutionNoticeModel.fromJson(Map<String, dynamic>.from(dataMap));
    }
    throw const FormatException('Invalid notice response');
  }

  Future<InstitutionNoticeModel> approveNotice({
    required int id,
    required String variant,
    String? customTitle,
    String? customBody,
    required bool notifyStudents,
    required bool notifyTeachers,
  }) async {
    final audience = <String>[];
    if (notifyStudents) audience.add('STUDENTS');
    if (notifyTeachers) audience.add('TEACHERS');

    final payload = <String, dynamic>{
      'variant': variant,
      if (customTitle != null && customTitle.trim().isNotEmpty)
        'customTitle': customTitle.trim(),
      if (customBody != null && customBody.trim().isNotEmpty)
        'customBody': customBody.trim(),
      'audience': audience,
      'notifyStudents': notifyStudents,
      'notifyTeachers': notifyTeachers,
    };

    final response = await _client.post(
      '/api/admin/holiday-notices/$id/approve',
      data: payload,
    );
    final json = response.data;

    if (json is Map<String, dynamic>) {
      final dataMap = json.containsKey('data') && json['data'] is Map
          ? json['data'] as Map
          : json;
      return InstitutionNoticeModel.fromJson(Map<String, dynamic>.from(dataMap));
    }
    throw const FormatException('Invalid approve response');
  }

  Future<InstitutionNoticeModel> rejectNotice(int id) async {
    final response = await _client.post('/api/admin/holiday-notices/$id/reject');
    final json = response.data;

    if (json is Map<String, dynamic>) {
      final dataMap = json.containsKey('data') && json['data'] is Map
          ? json['data'] as Map
          : json;
      return InstitutionNoticeModel.fromJson(Map<String, dynamic>.from(dataMap));
    }
    throw const FormatException('Invalid reject response');
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

  Future<List<OfficialNoticeModel>> getOfficialNotices({
    int page = 0,
    int size = 20,
  }) async {
    final response = await _client.get(
      '/api/holiday-notices/official',
      queryParameters: {'page': page, 'size': size},
    );
    final json = response.data;
    if (json is Map<String, dynamic>) {
      // ApiResponse<PagedResult<OfficialNoticeView>>
      final rawData = json['data'];
      final rawContent = rawData is Map<String, dynamic>
          ? rawData['content'] as List<dynamic>?
          : null;
      if (rawContent != null) {
        return rawContent
            .whereType<Map>()
            .map((e) => OfficialNoticeModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }
    return const [];
  }
}
