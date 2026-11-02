import '../../../../core/network/page_response.dart';
import '../entities/notification_item.dart';
import '../../data/models/create_notification_request_model.dart';

abstract class NotificationRepository {
  Future<PageResponse<NotificationItem>> getNotifications({int page = 0, int size = 20});
  Future<int> getUnreadCount();
  Future<void> markAsRead(int notificationId);
  Future<void> createNotification(CreateNotificationRequestModel request);
  Future<void> registerDeviceToken({required String token, required String platform});
  Future<void> deregisterDeviceToken(String token);
}
