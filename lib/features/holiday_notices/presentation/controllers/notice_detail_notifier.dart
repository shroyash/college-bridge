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
    required this.noticeId,
    PendingHolidayNotice? initialPending,
  })  : _repository = repository,
        super(initialPending != null
            ? NoticeDetailLoaded(pendingNotice: initialPending)
            : const NoticeDetailLoading()) {
    if (initialPending == null && noticeId > 0) {
      loadNotice();
    }
  }

  Future<void> loadNotice() async {
    state = const NoticeDetailLoading();
    try {
      final notice = await _repository.getNoticeById(noticeId);
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

    state = current.copyWith(isSubmitting: true, conflictMessage: null);

    try {
      final updatedNotice = await _repository.approveNotice(
        id: noticeId,
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
          noticeId: noticeId,
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

    state = current.copyWith(isSubmitting: true, conflictMessage: null);

    try {
      final updatedNotice = await _repository.rejectNotice(noticeId);
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
          noticeId: noticeId,
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
