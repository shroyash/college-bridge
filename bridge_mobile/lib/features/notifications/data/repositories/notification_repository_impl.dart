import '../../../../core/network/page_response.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';
import '../models/create_notification_request_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource _remoteDataSource;

  NotificationRepositoryImpl(this._remoteDataSource);

  @override
  Future<PageResponse<NotificationItem>> getNotifications({int page = 0, int size = 20}) async {
    final response = await _remoteDataSource.getInbox(page: page, size: size);
    return PageResponse<NotificationItem>(
      content: response.content,
      pageNumber: response.pageNumber,
      pageSize: response.pageSize,
      totalElements: response.totalElements,
      totalPages: response.totalPages,
      last: response.last,
      first: response.first,
    );
  }

  @override
  Future<int> getUnreadCount() => _remoteDataSource.getUnreadCount();

  @override
  Future<void> markAsRead(int notificationId) => _remoteDataSource.markAsRead(notificationId);

  @override
  Future<void> createNotification(CreateNotificationRequestModel request) =>
      _remoteDataSource.createNotification(request);

  @override
  Future<void> registerDeviceToken({required String token, required String platform}) =>
      _remoteDataSource.registerDeviceToken(token: token, platform: platform);

  @override
  Future<void> deregisterDeviceToken(String token) =>
      _remoteDataSource.deactivateDeviceToken(token);
}
