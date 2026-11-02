enum NotificationTargetType {
  INSTITUTION,
  CLASS,
  SUBJECT,
  USERS;

  static NotificationTargetType fromString(String? value) {
    if (value == null) return NotificationTargetType.INSTITUTION;
    switch (value.toUpperCase()) {
      case 'CLASS':
        return NotificationTargetType.CLASS;
      case 'SUBJECT':
        return NotificationTargetType.SUBJECT;
      case 'USERS':
        return NotificationTargetType.USERS;
      case 'INSTITUTION':
      default:
        return NotificationTargetType.INSTITUTION;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationTargetType.INSTITUTION:
        return 'Whole College';
      case NotificationTargetType.CLASS:
        return 'Class / Academic Level';
      case NotificationTargetType.SUBJECT:
        return 'Subject';
      case NotificationTargetType.USERS:
        return 'Specific Users';
    }
  }
}
