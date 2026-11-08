import '../../../../core/network/page_response.dart';
import '../../domain/entities/holiday_notice_enums.dart';
import '../../domain/entities/institution_holiday_notice.dart';
import '../../domain/entities/official_holiday_notice.dart';
import '../../domain/entities/pending_holiday_notice.dart';
import '../../domain/repositories/holiday_notice_repository.dart';
import '../datasources/holiday_notice_remote_datasource.dart';

class HolidayNoticeRepositoryImpl implements HolidayNoticeRepository {
  final HolidayNoticeRemoteDataSource _remoteDataSource;

  HolidayNoticeRepositoryImpl(this._remoteDataSource);

  @override
  Future<PendingHolidayNotice?> getPendingNotice() async {
    final model = await _remoteDataSource.getPendingNotice();
    return model?.toEntity();
  }

  @override
  Future<InstitutionHolidayNotice> getNoticeById(int id) async {
    final model = await _remoteDataSource.getNoticeById(id);
    return model.toEntity();
  }

  @override
  Future<InstitutionHolidayNotice> approveNotice({
    required int id,
    required NoticeVariant variant,
    String? customTitle,
    String? customBody,
    required bool notifyStudents,
    required bool notifyTeachers,
  }) async {
    final model = await _remoteDataSource.approveNotice(
      id: id,
      variant: variant.name,
      customTitle: customTitle,
      customBody: customBody,
      notifyStudents: notifyStudents,
      notifyTeachers: notifyTeachers,
    );
    return model.toEntity();
  }

  @override
  Future<InstitutionHolidayNotice> rejectNotice(int id) async {
    final model = await _remoteDataSource.rejectNotice(id);
    return model.toEntity();
  }

  @override
  Future<PageResponse<InstitutionHolidayNotice>> getHistory({
    int page = 0,
    int size = 10,
  }) async {
    final pagedModels = await _remoteDataSource.getHistory(page: page, size: size);
    return PageResponse<InstitutionHolidayNotice>(
      content: pagedModels.content.map((m) => m.toEntity()).toList(),
      pageNumber: pagedModels.pageNumber,
      pageSize: pagedModels.pageSize,
      totalElements: pagedModels.totalElements,
      totalPages: pagedModels.totalPages,
      last: pagedModels.last,
      first: pagedModels.first,
    );
  }

  @override
  Future<OfficialHolidayNotice?> getOfficialNotice({
    required int institutionId,
    required String date,
  }) async {
    final model = await _remoteDataSource.getOfficialNotice(
      institutionId: institutionId,
      date: date,
    );
    return model?.toEntity();
  }
}
