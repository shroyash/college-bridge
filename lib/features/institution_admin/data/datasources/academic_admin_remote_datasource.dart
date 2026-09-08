import 'package:dio/dio.dart';

import '../../../../app/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../dashboard/data/models/subject_model.dart';
import '../models/academic_class_model.dart';
import '../models/academic_level_model.dart';
import '../models/academic_program_model.dart';
import '../models/class_detail_model.dart';

class AcademicAdminRemoteDataSource {
  final ApiClient _apiClient;
  final SecureStorageService _storage;

  const AcademicAdminRemoteDataSource(this._apiClient, this._storage);

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
      403 => Exception('You do not have permission to perform this action.'),
      404 => Exception(msg.isNotEmpty ? msg : 'Resource not found.'),
      400 => Exception(msg.isNotEmpty ? msg : 'Invalid input request.'),
      409 => Exception(msg.isNotEmpty ? msg : 'Resource already exists.'),
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

  // ── Programs (formerly faculties) ─────────────────────────────────────────

  /// GET /api/admin/academic/programs
  Future<List<AcademicProgramModel>> getPrograms() async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.adminAcademicPrograms,
        options: options,
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

  /// POST /api/admin/academic/programs
  Future<AcademicProgramModel> createProgram({
    required String name,
    required String code,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.adminAcademicPrograms,
        data: {'name': name, 'code': code},
        options: options,
      );

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return AcademicProgramModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// DELETE /api/admin/academic/programs/{programId}
  Future<void> deleteProgram(int programId) async {
    try {
      final options = await _authOptions();
      await _apiClient.dio.delete<dynamic>(
        '${ApiConstants.adminAcademicPrograms}/$programId',
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// PUT /api/admin/academic/programs/{programId}
  Future<AcademicProgramModel> updateProgram({
    required int programId,
    required String name,
    required String code,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConstants.adminAcademicPrograms}/$programId',
        data: {'name': name, 'code': code},
        options: options,
      );

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return AcademicProgramModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Levels (formerly semesters/classes) ───────────────────────────────────

  /// GET /api/admin/academic/programs/{programId}/levels
  Future<List<AcademicLevelModel>> getLevels({required int programId}) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.get<Map<String, dynamic>>(
        '${ApiConstants.adminAcademicPrograms}/$programId/levels',
        options: options,
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

  /// POST /api/admin/academic/programs/{programId}/levels
  Future<AcademicLevelModel> createLevel({
    required int programId,
    required int levelNumber,
    required String name,
    required String type,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.post<Map<String, dynamic>>(
        '${ApiConstants.adminAcademicPrograms}/$programId/levels',
        data: {
          'levelNumber': levelNumber,
          'name': name,
          'type': type,
        },
        options: options,
      );

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return AcademicLevelModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// DELETE /api/admin/academic/levels/{levelId}
  Future<void> deleteLevel(int levelId) async {
    try {
      final options = await _authOptions();
      await _apiClient.dio.delete<dynamic>(
        '${ApiConstants.adminAcademicLevels}/$levelId',
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// PUT /api/admin/academic/levels/{levelId}
  Future<AcademicLevelModel> updateLevel({
    required int levelId,
    required int levelNumber,
    required String name,
    required String type,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.put<Map<String, dynamic>>(
        '${ApiConstants.adminAcademicLevels}/$levelId',
        data: {
          'levelNumber': levelNumber,
          'name': name,
          'type': type,
        },
        options: options,
      );

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return AcademicLevelModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  // ── Subjects ──────────────────────────────────────────────────────────────

  /// GET /api/admin/academic/subjects?levelId={id}
  Future<List<SubjectModel>> getSubjects({int? levelId}) async {
    try {
      final options = await _authOptions();
      final queryParams = <String, dynamic>{};
      if (levelId != null) queryParams['levelId'] = levelId;

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.adminAcademicSubjects,
        queryParameters: queryParams,
        options: options,
      );

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

  /// POST /api/admin/academic/subjects
  Future<SubjectModel> createSubject({
    required String name,
    required int levelId,
    String? code,
    int creditHours = 3,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.adminAcademicSubjects,
        data: {
          'name': name,
          'levelId': levelId,
          if (code != null && code.isNotEmpty) 'code': code,
          'creditHours': creditHours,
        },
        options: options,
      );

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return SubjectModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// PUT /api/admin/academic/subjects/{subjectId}
  Future<SubjectModel> updateSubject({
    required int subjectId,
    required String name,
    String? code,
    int creditHours = 3,
    int? levelId,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.dio.put<Map<String, dynamic>>(
        '${ApiConstants.adminAcademicSubjects}/$subjectId',
        data: {
          'name': name,
          if (code != null && code.isNotEmpty) 'code': code,
          'creditHours': creditHours,
          if (levelId != null) 'levelId': levelId,
        },
        options: options,
      );

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return SubjectModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// DELETE /api/admin/academic/subjects/{subjectId}
  Future<void> deleteSubject(int subjectId) async {
    try {
      final options = await _authOptions();
      await _apiClient.dio.delete<dynamic>(
        '${ApiConstants.adminAcademicSubjects}/$subjectId',
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// POST /api/admin/academic/subjects/batch
  Future<List<SubjectModel>> batchCreateSubjects({
    required int levelId,
    required List<Map<String, dynamic>> subjects,
  }) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.adminAcademicSubjectsBatch,
        data: {
          'levelId': levelId,
          'subjects': subjects,
        },
        options: options,
      );

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

  // ── Backward Compatibility Helpers for Legacy Screens ──────────────────────

  Future<List<String>> getSupportedFaculties() async {
    try {
      final programs = await getPrograms();
      return programs.map((p) => p.code).toList();
    } catch (_) {
      return ['BCA', 'BBA', 'BIM', 'BSC_CSIT', 'BE_CIVIL'];
    }
  }

  Future<List<AcademicClassModel>> getAcademicClasses() async {
    try {
      final programs = await getPrograms();
      final List<AcademicClassModel> result = [];
      for (final p in programs) {
        final levels = await getLevels(programId: p.programId);
        for (final l in levels) {
          result.add(AcademicClassModel(
            classId: l.levelId,
            displayName: '${p.code} - ${l.name}',
            faculty: p.code,
            semester: l.levelNumber,
            totalStudents: 0,
          ));
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<List<AcademicClassModel>> getAcademicClassesFiltered({
    String? faculty,
    int? semester,
    String? search,
  }) =>
      getAcademicClasses();

  Future<AcademicClassModel> createAcademicClass({
    required String faculty,
    required int semester,
    String? displayName,
  }) async {
    final programs = await getPrograms();
    AcademicProgramModel prog = programs.firstWhere(
      (p) => p.code == faculty,
      orElse: () => programs.isNotEmpty
          ? programs.first
          : AcademicProgramModel(programId: 1, name: faculty, code: faculty),
    );
    final level = await createLevel(
      programId: prog.programId,
      levelNumber: semester,
      name: displayName ?? 'Semester $semester',
      type: 'SEMESTER',
    );
    return AcademicClassModel(
      classId: level.levelId,
      displayName: level.name,
      faculty: prog.code,
      semester: level.levelNumber,
      totalStudents: 0,
    );
  }

  Future<void> assignClassTeacher(int classId, int teacherId) async {
    // No-op or log for backward compatibility
  }

  Future<ClassDetailModel> getClassDetails(int classId) async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/admin/academic/classes/$classId/details',
        options: options,
      );
      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      return ClassDetailModel.fromJson(data);
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> removeStudentFromClass(int classId, int studentId) async {
    try {
      final options = await _authOptions();
      await _apiClient.dio.delete<dynamic>(
        '/api/admin/academic/classes/$classId/students/$studentId',
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<List<ClassStudentModel>> getUnassignedStudents() async {
    try {
      final options = await _authOptions();
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/admin/academic/classes/unassigned-students',
        options: options,
      );
      final data = response.data?['data'];
      if (data is List) {
        return data
            .map((e) => ClassStudentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Future<void> addStudentToClass(int classId, int studentId) async {
    try {
      final options = await _authOptions();
      await _apiClient.post<dynamic>(
        '/api/admin/academic/classes/$classId/students/$studentId',
        options: options,
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }
}
