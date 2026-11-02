import '../../domain/entities/notification_target_type.dart';

class CreateNotificationRequestModel {
  final String title;
  final String body;
  final NotificationTargetType targetType;
  final int? targetId;
  final List<int>? userIds;
  final String? idempotencyKey;

  const CreateNotificationRequestModel({
    required this.title,
    required this.body,
    required this.targetType,
    this.targetId,
    this.userIds,
    this.idempotencyKey,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'title': title.trim(),
      'body': body.trim(),
      'targetType': targetType.name,
    };
    if (targetId != null) {
      map['targetId'] = targetId;
    }
    if (userIds != null && userIds!.isNotEmpty) {
      map['userIds'] = userIds;
    }
    if (idempotencyKey != null && idempotencyKey!.isNotEmpty) {
      map['idempotencyKey'] = idempotencyKey;
    }
    return map;
  }
}
