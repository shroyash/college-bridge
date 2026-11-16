import 'package:equatable/equatable.dart';
import 'notification_target_type.dart';

class NotificationItem extends Equatable {
  final int notificationId;
  final String title;
  final String body;
  final int? senderId;
  final String senderName;
  final NotificationTargetType targetType;
  final int? targetId;
  final DateTime createdAt;
  final bool isRead;

  const NotificationItem({
    required this.notificationId,
    required this.title,
    required this.body,
    this.senderId,
    required this.senderName,
    required this.targetType,
    this.targetId,
    required this.createdAt,
    required this.isRead,
  });

  NotificationItem copyWith({
    int? notificationId,
    String? title,
    String? body,
    int? senderId,
    String? senderName,
    NotificationTargetType? targetType,
    int? targetId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationItem(
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      body: body ?? this.body,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [
        notificationId,
        title,
        body,
        senderId,
        senderName,
        targetType,
        targetId,
        createdAt,
        isRead,
      ];
}
