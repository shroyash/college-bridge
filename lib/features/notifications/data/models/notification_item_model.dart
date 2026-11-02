import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notification_target_type.dart';

class NotificationItemModel extends NotificationItem {
  const NotificationItemModel({
    required super.notificationId,
    required super.title,
    required super.body,
    super.senderId,
    required super.senderName,
    required super.targetType,
    super.targetId,
    required super.createdAt,
    required super.isRead,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      if (json['createdAt'] != null) {
        parsedDate = DateTime.parse(json['createdAt'].toString());
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationItemModel(
      notificationId: (json['notificationId'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      senderId: (json['senderId'] as num?)?.toInt(),
      senderName: json['senderName'] as String? ?? 'System',
      targetType: NotificationTargetType.fromString(json['targetType'] as String?),
      targetId: (json['targetId'] as num?)?.toInt(),
      createdAt: parsedDate,
      isRead: json['read'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationId': notificationId,
      'title': title,
      'body': body,
      'senderId': senderId,
      'senderName': senderName,
      'targetType': targetType.name,
      'targetId': targetId,
      'createdAt': createdAt.toIso8601String(),
      'read': isRead,
    };
  }
}
