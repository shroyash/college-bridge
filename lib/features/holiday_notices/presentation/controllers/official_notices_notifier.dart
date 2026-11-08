import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/official_holiday_notice.dart';
import '../../domain/repositories/holiday_notice_repository.dart';
import 'official_notices_state.dart';

class OfficialNoticesNotifier extends StateNotifier<OfficialNoticesState> {
  final HolidayNoticeRepository _repository;

  OfficialNoticesNotifier(this._repository) : super(const OfficialNoticesInitial());

  Future<void> fetchNotice({
    required int institutionId,
    required String date,
  }) async {
    state = const OfficialNoticesLoading();
    try {
      final notice = await _repository.getOfficialNotice(
        institutionId: institutionId,
        date: date,
      );

      if (notice != null) {
        state = OfficialNoticesLoaded(notices: [notice]);
      } else {
        state = const OfficialNoticesLoaded(notices: []);
      }
    } catch (e) {
      state = OfficialNoticesError(extractErrorMessage(e));
    }
  }

  void setSingleNotice(OfficialHolidayNotice notice) {
    state = OfficialNoticesLoaded(notices: [notice]);
  }
}
