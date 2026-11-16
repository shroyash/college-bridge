import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/holiday_notice_repository.dart';
import 'pending_notice_state.dart';

class PendingNoticeNotifier extends StateNotifier<PendingNoticeState> {
  final HolidayNoticeRepository _repository;

  PendingNoticeNotifier(this._repository) : super(const PendingNoticeInitial());

  Future<void> fetchPendingNotice() async {
    state = const PendingNoticeLoading();
    try {
      final notice = await _repository.getPendingNotice();
      state = PendingNoticeLoaded(notice);
    } catch (e) {
      state = PendingNoticeError(extractErrorMessage(e));
    }
  }

  void clearPending() {
    state = const PendingNoticeLoaded(null);
  }
}
