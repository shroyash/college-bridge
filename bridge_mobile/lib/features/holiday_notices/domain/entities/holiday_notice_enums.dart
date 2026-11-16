// ignore_for_file: constant_identifier_names

/// Variant of a holiday announcement: closed or open.
enum NoticeVariant {
  CLOSED,
  OPEN;

  String get label {
    switch (this) {
      case NoticeVariant.CLOSED:
        return 'College Closed';
      case NoticeVariant.OPEN:
        return 'College Open';
    }
  }

  String get badgeText {
    switch (this) {
      case NoticeVariant.CLOSED:
        return 'CLOSED';
      case NoticeVariant.OPEN:
        return 'OPEN';
    }
  }
}

/// Lifecycle status of an institution holiday notice.
enum NoticeStatus {
  AWAITING_DECISION,
  APPROVED,
  PUBLISHING,
  PUBLISHED,
  FAILED,
  REJECTED,
  EXPIRED;

  bool get isDecided => this != NoticeStatus.AWAITING_DECISION;

  bool get isPublished => this == NoticeStatus.PUBLISHED;

  bool get isFailed => this == NoticeStatus.FAILED;

  bool get isRejected => this == NoticeStatus.REJECTED;

  bool get isExpired => this == NoticeStatus.EXPIRED;
}

/// Generation origin of a notice draft.
enum NoticeOrigin {
  AI,
  TEMPLATE;

  String get label {
    switch (this) {
      case NoticeOrigin.AI:
        return 'AI Draft';
      case NoticeOrigin.TEMPLATE:
        return 'Standard Wording';
    }
  }
}

/// Recipient audience for push notification.
enum AudienceTarget {
  STUDENTS,
  TEACHERS;

  String get label {
    switch (this) {
      case AudienceTarget.STUDENTS:
        return 'Students';
      case AudienceTarget.TEACHERS:
        return 'Teachers';
    }
  }
}
