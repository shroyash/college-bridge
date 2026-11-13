import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/holiday_notice_enums.dart';
import '../../domain/entities/pending_holiday_notice.dart';
import '../../domain/repositories/holiday_notice_repository.dart';
import 'notice_detail_state.dart';

class NoticeDetailNotifier extends StateNotifier<NoticeDetailState> {
  final HolidayNoticeRepository _repository;
  final int noticeId;

  NoticeDetailNotifier({
    required HolidayNoticeRepository repository,
    required int noticeId,
    PendingHolidayNotice? initialPending,
  })  : _repository = repository,
        noticeId = noticeId > 0
            ? noticeId
            : ((initialPending != null && initialPending.holidayId > 0)
                ? initialPending.holidayId
                : (initialPending?.id ?? 0)),
        super(initialPending != null
            ? NoticeDetailLoaded(pendingNotice: initialPending)
            : const NoticeDetailLoading()) {
    if (initialPending == null && this.noticeId > 0) {
      loadNotice();
    }
  }

  int _resolveTargetId(NoticeDetailLoaded loaded) {
    if (noticeId > 0) return noticeId;
    if (loaded.pendingNotice != null) {
      if (loaded.pendingNotice!.holidayId > 0) return loaded.pendingNotice!.holidayId;
      if (loaded.pendingNotice!.id > 0) return loaded.pendingNotice!.id;
    }
    if (loaded.notice != null) {
      if (loaded.notice!.holidayId > 0) return loaded.notice!.holidayId;
      if (loaded.notice!.id > 0) return loaded.notice!.id;
    }
    return 0;
  }

  Future<void> loadNotice() async {
    final current = state;
    final targetId = noticeId > 0
        ? noticeId
        : (current is NoticeDetailLoaded ? _resolveTargetId(current) : 0);
    if (targetId <= 0) return;

    state = const NoticeDetailLoading();
    try {
      final notice = await _repository.getNoticeById(targetId);
      state = NoticeDetailLoaded(notice: notice);
    } catch (e) {
      state = NoticeDetailError(extractErrorMessage(e));
    }
  }

  void setPendingNotice(PendingHolidayNotice pending) {
    state = NoticeDetailLoaded(pendingNotice: pending);
  }

  Future<bool> approve({
    required NoticeVariant variant,
    String? customTitle,
    String? customBody,
    required bool notifyStudents,
    required bool notifyTeachers,
  }) async {
    final current = state;
    if (current is! NoticeDetailLoaded) return false;

    final targetId = _resolveTargetId(current);
    if (targetId <= 0) return false;

    state = current.copyWith(isSubmitting: true, conflictMessage: null);

    try {
      final updatedNotice = await _repository.approveNotice(
        id: targetId,
        variant: variant,
        customTitle: customTitle,
        customBody: customBody,
        notifyStudents: notifyStudents,
        notifyTeachers: notifyTeachers,
      );

      state = NoticeDetailLoaded(
        notice: updatedNotice,
        isSubmitting: false,
        actionMessage: 'Notice approved. Notifications are on their way.',
      );
      return true;
    } catch (e) {
      if (_isConflictError(e)) {
        final conflictMsg = extractErrorMessage(e);
        state = NoticeDetailConflict(
          message: conflictMsg.isNotEmpty
              ? conflictMsg
              : 'Another administrator already decided this notice.',
          noticeId: targetId,
        );
        // Reload server state
        await loadNotice();
        return false;
      }

      state = current.copyWith(
        isSubmitting: false,
        actionMessage: null,
      );
      return false;
    }
  }

  Future<bool> reject() async {
    final current = state;
    if (current is! NoticeDetailLoaded) return false;

    final targetId = _resolveTargetId(current);
    if (targetId <= 0) return false;

    state = current.copyWith(isSubmitting: true, conflictMessage: null);

    try {
      final updatedNotice = await _repository.rejectNotice(targetId);
      state = NoticeDetailLoaded(
        notice: updatedNotice,
        isSubmitting: false,
        actionMessage: 'You chose not to announce this holiday.',
      );
      return true;
    } catch (e) {
      if (_isConflictError(e)) {
        final conflictMsg = extractErrorMessage(e);
        state = NoticeDetailConflict(
          message: conflictMsg.isNotEmpty
              ? conflictMsg
              : 'Another administrator already decided this notice.',
          noticeId: targetId,
        );
        await loadNotice();
        return false;
      }

      state = current.copyWith(isSubmitting: false);
      return false;
    }
  }

  bool _isConflictError(Object error) {
    if (error is ConflictFailure) return true;
    if (error is DioException) {
      if (error.response?.statusCode == 409) return true;
      if (error.error is ConflictFailure) return true;
    }
    return false;
  }
}
