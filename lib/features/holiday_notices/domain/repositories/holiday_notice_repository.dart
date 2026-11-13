import '../../../../core/network/page_response.dart';
import '../entities/holiday_notice_enums.dart';
import '../entities/institution_holiday_notice.dart';
import '../entities/official_holiday_notice.dart';
import '../entities/pending_holiday_notice.dart';

abstract class HolidayNoticeRepository {
  /// Fetches pending holiday notice awaiting decision for the administrator's college.
  Future<PendingHolidayNotice?> getPendingNotice();

  /// Fetches a specific holiday notice by its ID.
  Future<InstitutionHolidayNotice> getNoticeById(int id);

  /// Approves the notice with chosen variant, optional custom wording, and audience selection.
  Future<InstitutionHolidayNotice> approveNotice({
    required int id,
    required NoticeVariant variant,
    String? customTitle,
    String? customBody,
    required bool notifyStudents,
    required bool notifyTeachers,
  });

  /// Rejects the notice so no announcement is broadcasted.
  Future<InstitutionHolidayNotice> rejectNotice(int id);

  /// Retrieves past holiday notice history for the institution.
  Future<PageResponse<InstitutionHolidayNotice>> getHistory({
    int page = 0,
    int size = 10,
  });

  /// Fetches official (approved) holiday notices for the user's institution.
  Future<List<OfficialHolidayNotice>> getOfficialNotices({
    int page = 0,
    int size = 20,
  });
}
