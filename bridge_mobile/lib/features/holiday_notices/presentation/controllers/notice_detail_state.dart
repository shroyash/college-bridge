import 'package:equatable/equatable.dart';
import '../../domain/entities/institution_holiday_notice.dart';
import '../../domain/entities/pending_holiday_notice.dart';

sealed class NoticeDetailState extends Equatable {
  const NoticeDetailState();

  @override
  List<Object?> get props => [];
}

class NoticeDetailLoading extends NoticeDetailState {
  const NoticeDetailLoading();
}

class NoticeDetailLoaded extends NoticeDetailState {
  final InstitutionHolidayNotice? notice;
  final PendingHolidayNotice? pendingNotice;
  final bool isSubmitting;
  final String? actionMessage;
  final String? conflictMessage;

  const NoticeDetailLoaded({
    this.notice,
    this.pendingNotice,
    this.isSubmitting = false,
    this.actionMessage,
    this.conflictMessage,
  });

  NoticeDetailLoaded copyWith({
    InstitutionHolidayNotice? notice,
    PendingHolidayNotice? pendingNotice,
    bool? isSubmitting,
    String? actionMessage,
    String? conflictMessage,
  }) {
    return NoticeDetailLoaded(
      notice: notice ?? this.notice,
      pendingNotice: pendingNotice ?? this.pendingNotice,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      actionMessage: actionMessage ?? this.actionMessage,
      conflictMessage: conflictMessage ?? this.conflictMessage,
    );
  }

  @override
  List<Object?> get props => [
        notice,
        pendingNotice,
        isSubmitting,
        actionMessage,
        conflictMessage,
      ];
}

class NoticeDetailError extends NoticeDetailState {
  final String message;

  const NoticeDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

class NoticeDetailConflict extends NoticeDetailState {
  final String message;
  final int noticeId;

  const NoticeDetailConflict({
    required this.message,
    required this.noticeId,
  });

  @override
  List<Object?> get props => [message, noticeId];
}
