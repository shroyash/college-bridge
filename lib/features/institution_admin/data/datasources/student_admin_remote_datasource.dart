import 'package:dio/dio.dart';

import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

// ── Models ─────────────────────────────────────────────────────────────────

class StudentFilterOptions {
  final List<String> faculties;
  final List<int> semesters;

  const StudentFilterOptions({required this.faculties, required this.semesters});

  factory StudentFilterOptions.fromJson(Map<String, dynamic> json) {
    return StudentFilterOptions(
      faculties: (json['faculties'] as List?)?.map((e) => e.toString()).toList() ?? [],
      semesters: (json['semesters'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
    );
  }
}

class StudentSummary {
  final int userId;
  final int? studentId;
  final String name;
  final String email;
  final String status;
  final String? faculty;
  final int? semester;
  final int? academicClassId;
  final String? displayName;

  const StudentSummary({
    required this.userId,
    this.studentId,
    required this.name,
    required this.email,
    required this.status,
    this.faculty,
    this.semester,
    this.academicClassId,
    this.displayName,
  });

  int get effectiveStudentId => studentId ?? userId;

  factory StudentSummary.fromJson(Map<String, dynamic> json) {
    final details = json['studentDetails'] as Map<String, dynamic>?;
    return StudentSummary(
      userId: (json['userId'] as num).toInt(),
      studentId: (details?['studentId'] as num?)?.toInt(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      faculty: details?['faculty'] as String?,
      semester: (details?['semester'] as num?)?.toInt(),
      academicClassId: (details?['academicClassId'] as num?)?.toInt(),
      displayName: details?['displayName'] as String?,
    );
  }
}

class BulkTransferResult {
  final bool success;
  final int updatedStudents;
  final int targetLevelId;
  final int targetClassId;
  final String targetFaculty;
  final int targetSemester;
  final String targetDisplayName;

  const BulkTransferResult({
    required this.success,
    required this.updatedStudents,
    required this.targetLevelId,
    required this.targetClassId,
    required this.targetFaculty,
    required this.targetSemester,
    required this.targetDisplayName,
  });

  factory BulkTransferResult.fromJson(Map<String, dynamic> json) {
    final tl = json['targetLevel'] as Map<String, dynamic>? ?? {};
    final progName = tl['programName'] as String? ?? '';
    final name = tl['name'] as String? ?? '';
    final displayName = progName.isNotEmpty && name.isNotEmpty
        ? '$progName $name'
        : (name.isNotEmpty ? name : progName);
    final levelId = (tl['levelId'] as num?)?.toInt() ?? 0;

    return BulkTransferResult(
      success: json['success'] as bool? ?? false,
      updatedStudents: (json['updatedStudents'] as num?)?.toInt() ?? 0,
      targetLevelId: levelId,
      targetClassId: levelId,
      targetFaculty: progName,
      targetSemester: (tl['levelNumber'] as num?)?.toInt() ?? 0,
      targetDisplayName: displayName,
    );
  }
}

class PagedStudents {
  final List<StudentSummary> students;
  final int totalElements;
  final int totalPages;
  final int currentPage;

  const PagedStudents({
    required this.students,
    required this.totalElements,
    required this.totalPages,
    required this.currentPage,
  });
}

// ── Datasource ─────────────────────────────────────────────────────────────

class StudentAdminRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  const StudentAdminRemoteDataSource(this._apiClient, this._storage);

  Future<Options> _authOptions() async {
    final token = await _storage.getAccessToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Exception _mapException(DioException e) {
    final statusCode = e.response?.statusCode;
    String msg = '';
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) msg = data['message'] as String? ?? '';
    } catch (_) {}
    return switch (statusCode) {
      400 => Exception(msg.isNotEmpty ? msg : 'Invalid request.'),
      401 => Exception('Session expired. Please log in again.'),
      403 => Exception('Access denied.'),
      404 => Exception(msg.isNotEmpty ? msg : 'Resource not found.'),
      409 => Exception(msg.isNotEmpty ? msg : 'Conflict.'),
      500 => Exception('Server error. Please try again later.'),
      _ => Exception(
          e.type == DioExceptionType.connectionTimeout
              ? 'Connection timeout.'
              : msg.isNotEmpty
                  ? msg
                  : 'Something went wrong.',
        ),
    };
  }

  /// GET /api/admin/students/filter-options
  Future<StudentFilterOptions> getFilterOptions() async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.adminStudentsFilterOptions,
        options: options,
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return StudentFilterOptions.fromJson(data);
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// GET /api/admin/students?faculty=BCA&semester=4&page=0&size=20
  Future<PagedStudents> getStudents({
    String? faculty,
    int? semester,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    try {
      final options = await _authOptions();
      final queryParams = <String, dynamic>{
        'page': page,
        'size': size,
      };
      if (faculty != null && faculty.isNotEmpty) queryParams['faculty'] = faculty;
      if (semester != null) queryParams['semester'] = semester;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.adminStudents,
        queryParameters: queryParams,
        options: options,
      );

      final body = response.data?['data'] as Map<String, dynamic>? ?? {};
      final content = body['content'] as List? ?? [];
      return PagedStudents(
        students: content
            .map((e) => StudentSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: body['totalElements'] as int? ?? 0,
        totalPages: body['totalPages'] as int? ?? 0,
        currentPage: body['number'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }

  /// POST /api/admin/students/bulk-transfer
  Future<BulkTransferResult> bulkTransfer({
    required List<int> studentIds,
    required int targetLevelId,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.adminStudentsBulkTransfer,
        data: {
          'studentIds': studentIds,
          'targetLevelId': targetLevelId,
        },
        options: options,
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return BulkTransferResult.fromJson(data);
    } on DioException catch (e) {
      throw _mapException(e);
    }
  }
}
