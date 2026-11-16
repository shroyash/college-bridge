import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/official_holiday_notice.dart';
import '../../domain/repositories/holiday_notice_repository.dart';
import 'official_notices_state.dart';

class OfficialNoticesNotifier extends StateNotifier<OfficialNoticesState> {
  final HolidayNoticeRepository _repository;

  OfficialNoticesNotifier(this._repository) : super(const OfficialNoticesInitial());

  Future<void> fetchNotices({int page = 0, int size = 20}) async {
    state = const OfficialNoticesLoading();
    try {
      final notices = await _repository.getOfficialNotices(page: page, size: size);
      state = OfficialNoticesLoaded(notices: notices);
    } catch (e) {
      state = OfficialNoticesError(extractErrorMessage(e));
    }
  }

  void setSingleNotice(OfficialHolidayNotice notice) {
    state = OfficialNoticesLoaded(notices: [notice]);
  }
}
