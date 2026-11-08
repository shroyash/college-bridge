import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/holiday_notice_remote_datasource.dart';
import '../../data/repositories/holiday_notice_repository_impl.dart';
import '../../domain/entities/pending_holiday_notice.dart';
import '../../domain/repositories/holiday_notice_repository.dart';
import 'notice_detail_notifier.dart';
import 'notice_detail_state.dart';
import 'official_notices_notifier.dart';
import 'official_notices_state.dart';
import 'pending_notice_notifier.dart';
import 'pending_notice_state.dart';

final holidayNoticeRemoteDataSourceProvider = Provider<HolidayNoticeRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return HolidayNoticeRemoteDataSource(apiClient);
});

final holidayNoticeRepositoryProvider = Provider<HolidayNoticeRepository>((ref) {
  final remoteDataSource = ref.watch(holidayNoticeRemoteDataSourceProvider);
  return HolidayNoticeRepositoryImpl(remoteDataSource);
});

final pendingNoticeNotifierProvider =
    StateNotifierProvider<PendingNoticeNotifier, PendingNoticeState>((ref) {
  final repository = ref.watch(holidayNoticeRepositoryProvider);
  return PendingNoticeNotifier(repository);
});

final noticeDetailNotifierProvider = StateNotifierProvider.autoDispose
    .family<NoticeDetailNotifier, NoticeDetailState, ({int noticeId, PendingHolidayNotice? initialPending})>(
  (ref, params) {
    final repository = ref.watch(holidayNoticeRepositoryProvider);
    return NoticeDetailNotifier(
      repository: repository,
      noticeId: params.noticeId,
      initialPending: params.initialPending,
    );
  },
);

final officialNoticesNotifierProvider =
    StateNotifierProvider<OfficialNoticesNotifier, OfficialNoticesState>((ref) {
  final repository = ref.watch(holidayNoticeRepositoryProvider);
  return OfficialNoticesNotifier(repository);
});
