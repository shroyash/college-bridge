import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/page_response.dart';
import '../../../academics/data/models/academic_level_model.dart';
import '../../../subjects/data/models/subject_model.dart';
import '../models/create_notification_request_model.dart';
import '../models/notification_item_model.dart';

class NotificationRemoteDataSource {
  final ApiClient _apiClient;

  const NotificationRemoteDataSource(this._apiClient);

  /// Fetch user's paginated notification inbox
  /// GET /api/notifications/inbox?page={page}&size={size}
  Future<PageResponse<NotificationItemModel>> getInbox({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsInbox,
        queryParameters: {
          'page': page,
          'size': size,
          'sort': 'createdAt,desc',
        },
      );

      final apiResponse = ApiResponse<PageResponse<NotificationItemModel>>.fromJson(
        response.data ?? {},
        (data) {
          if (data is Map<String, dynamic>) {
            return PageResponse<NotificationItemModel>.fromJson(
              data,
              (item) => NotificationItemModel.fromJson(item as Map<String, dynamic>),
            );
          }
          return PageResponse<NotificationItemModel>(
            content: const [],
            pageNumber: page,
            pageSize: size,
            totalElements: 0,
            totalPages: 0,
            last: true,
            first: true,
          );
        },
      );

      return apiResponse.data ??
          PageResponse<NotificationItemModel>(
            content: const [],
            pageNumber: page,
            pageSize: size,
            totalElements: 0,
            totalPages: 0,
            last: true,
            first: true,
          );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Get current user's unread notification count
  /// GET /api/notifications/unread-count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.notificationsUnreadCount,
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? {},
        (data) => data as Map<String, dynamic>,
      );

      final countNum = apiResponse.data?['count'] as num?;
      return countNum?.toInt() ?? 0;
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Mark a notification as read (idempotent)
  /// PUT /api/notifications/{id}/read
  Future<void> markAsRead(int notificationId) async {
    try {
      await _apiClient.put<Map<String, dynamic>>(
        ApiEndpoints.notificationMarkRead(notificationId),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Dispatch a new notification (SUPER_ADMIN, ADMIN, TEACHER)
  /// POST /api/notifications
  Future<void> createNotification(CreateNotificationRequestModel request) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.notifications,
        data: request.toJson(),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Register or refresh an FCM device token with the backend
  /// POST /api/devices/fcm-token
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        ApiEndpoints.devicesFcmToken,
        data: {
          'token': token,
          'platform': platform,
        },
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Deactivate device token on logout
  /// DELETE /api/devices/fcm-token?token={token}
  Future<void> deactivateDeviceToken(String token) async {
    try {
      await _apiClient.delete<Map<String, dynamic>>(
        ApiEndpoints.deviceDeactivateFcmToken(token),
      );
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Fetch subjects available for notification targeting based on user role.
  /// - ADMIN / SUPER_ADMIN: all institution subjects (GET /api/academic/subjects/all)
  /// - TEACHER: assigned subjects only (GET /api/academic/subjects/my-subjects)
  Future<List<SubjectModel>> fetchSubjectsForRole(String? role) async {
    try {
      final endpoint = (role == 'TEACHER')
          ? ApiEndpoints.mySubjects
          : ApiEndpoints.academicSubjectsAll;

      final response = await _apiClient.get<Map<String, dynamic>>(endpoint);
      final rawData = response.data?['data'];

      if (rawData is List) {
        return rawData
            .map((e) => SubjectModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  /// Fetch academic class levels available for notification targeting based on user role.
  /// - ADMIN / SUPER_ADMIN: all institution levels (GET /api/admin/academic/levels)
  /// - TEACHER: assigned levels only (GET /api/academic/levels/my-levels, falling back to unique levels from my-subjects)
  Future<List<AcademicLevelModel>> fetchLevelsForRole(String? role) async {
    try {
      if (role == 'TEACHER') {
        try {
          final response = await _apiClient.get<Map<String, dynamic>>(
            ApiEndpoints.myAcademicLevels,
          );
          final rawData = response.data?['data'];
          if (rawData is List && rawData.isNotEmpty) {
            return rawData
                .map((e) => AcademicLevelModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        } catch (_) {
          // If my-levels is not implemented on backend, derive unique levels from my-subjects
        }

        // Fallback: derive assigned levels from teacher's assigned subjects
        final subjects = await fetchSubjectsForRole('TEACHER');
        final Map<int, AcademicLevelModel> uniqueLevels = {};

        for (final subject in subjects) {
          if (subject.levelId > 0 && !uniqueLevels.containsKey(subject.levelId)) {
            uniqueLevels[subject.levelId] = AcademicLevelModel(
              levelId: subject.levelId,
              levelNumber: 1,
              name: subject.levelName.isNotEmpty ? subject.levelName : 'Level ${subject.levelId}',
              type: 'SEMESTER',
              programId: 0,
              programName: subject.programName,
              programCode: subject.programName,
            );
          }
        }
        return uniqueLevels.values.toList();
      }

      // ADMIN / SUPER_ADMIN
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.adminAcademicLevels,
      );
      final rawData = response.data?['data'];
      if (rawData is List) {
        return rawData
            .map((e) => AcademicLevelModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    String message = '';
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ?? '';
      }
    } catch (_) {}

    return switch (statusCode) {
      401 => Exception('Session expired. Please log in again.'),
      403 => Exception(message.isNotEmpty ? message : 'You are not authorized for this notification action.'),
      404 => Exception(message.isNotEmpty ? message : 'Notification not found.'),
      400 => Exception(message.isNotEmpty ? message : 'Invalid notification request.'),
      409 => Exception(message.isNotEmpty ? message : 'Duplicate request.'),
      500 => Exception('Server error. Please try again later.'),
      _ => Exception(
          e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout
              ? 'Connection timeout. Check your network.'
              : message.isNotEmpty
                  ? message
                  : 'Failed to process notification request.',
        ),
    };
  }
}
