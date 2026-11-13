import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_mobile/core/error/failures.dart';
import 'package:bridge_mobile/core/network/page_response.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/holiday_notice_draft.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/holiday_notice_enums.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/institution_holiday_notice.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/official_holiday_notice.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/pending_holiday_notice.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/repositories/holiday_notice_repository.dart';
import 'package:bridge_mobile/features/holiday_notices/presentation/controllers/notice_detail_notifier.dart';
import 'package:bridge_mobile/features/holiday_notices/presentation/controllers/notice_detail_state.dart';
import 'package:bridge_mobile/features/holiday_notices/presentation/controllers/official_notices_notifier.dart';
import 'package:bridge_mobile/features/holiday_notices/presentation/controllers/official_notices_state.dart';
import 'package:bridge_mobile/features/holiday_notices/presentation/controllers/pending_notice_notifier.dart';
import 'package:bridge_mobile/features/holiday_notices/presentation/controllers/pending_notice_state.dart';

class MockHolidayNoticeRepository implements HolidayNoticeRepository {
  PendingHolidayNotice? pendingResult;
  InstitutionHolidayNotice? noticeByIdResult;
  InstitutionHolidayNotice? approveResult;
  InstitutionHolidayNotice? rejectResult;
  List<OfficialHolidayNotice> officialResult = [];

  Object? errorToThrow;
  bool isConflictOnApprove = false;
  bool isConflictOnReject = false;

  int approveCalls = 0;
  int rejectCalls = 0;
  int loadNoticeCalls = 0;

  @override
  Future<PendingHolidayNotice?> getPendingNotice() async {
    if (errorToThrow != null) throw errorToThrow!;
    return pendingResult;
  }

  @override
  Future<InstitutionHolidayNotice> getNoticeById(int id) async {
    loadNoticeCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    if (noticeByIdResult != null) return noticeByIdResult!;
    throw const ServerFailure('Notice not found');
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
    approveCalls++;
    if (isConflictOnApprove) {
      throw DioException(
        requestOptions: RequestOptions(path: '/approve'),
        response: Response(
          requestOptions: RequestOptions(path: '/approve'),
          statusCode: 409,
          data: {
            'type': 'https://api.collegebridge.edu.np/errors/conflict',
            'title': 'Conflict',
            'status': 409,
            'detail': 'Another administrator decided this notice at 18:05:12.',
          },
        ),
      );
    }
    if (errorToThrow != null) throw errorToThrow!;
    return approveResult!;
  }

  @override
  Future<InstitutionHolidayNotice> rejectNotice(int id) async {
    rejectCalls++;
    if (isConflictOnReject) {
      throw DioException(
        requestOptions: RequestOptions(path: '/reject'),
        response: Response(
          requestOptions: RequestOptions(path: '/reject'),
          statusCode: 409,
          data: {
            'title': 'Conflict',
            'detail': 'Another administrator decided this notice.',
          },
        ),
      );
    }
    if (errorToThrow != null) throw errorToThrow!;
    return rejectResult!;
  }

  @override
  Future<PageResponse<InstitutionHolidayNotice>> getHistory({
    int page = 0,
    int size = 10,
  }) async {
    return PageResponse<InstitutionHolidayNotice>(
      content: const [],
      totalPages: 0,
      totalElements: 0,
      pageSize: size,
      pageNumber: page,
      first: true,
      last: true,
    );
  }

  @override
  Future<List<OfficialHolidayNotice>> getOfficialNotices({
    int page = 0,
    int size = 20,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return officialResult;
  }
}

void main() {
  late MockHolidayNoticeRepository mockRepo;

  const samplePending = PendingHolidayNotice(
    id: 101,
    institutionId: 1,
    holidayId: 12,
    holidayName: 'Buddha Jayanti',
    holidayDateAd: '2026-05-31',
    holidayDateBs: '2083-02-17',
    holidayScope: 'NATIONWIDE',
    status: NoticeStatus.AWAITING_DECISION,
    closedDraft: HolidayNoticeDraft(
      variant: NoticeVariant.CLOSED,
      title: 'College Closed for Buddha Jayanti',
      body: 'Campus will remain closed.',
      origin: NoticeOrigin.AI,
    ),
    openDraft: HolidayNoticeDraft(
      variant: NoticeVariant.OPEN,
      title: 'College Open - Regular Classes',
      body: 'Campus will remain open.',
      origin: NoticeOrigin.AI,
    ),
  );

  const sampleApprovedNotice = InstitutionHolidayNotice(
    id: 101,
    holidayId: 12,
    holidayName: 'Buddha Jayanti',
    holidayDateAd: '2026-05-31',
    holidayDateBs: '2083-02-17',
    institutionId: 1,
    status: NoticeStatus.APPROVED,
    variant: NoticeVariant.CLOSED,
    finalTitle: 'Official Holiday: Buddha Jayanti',
    finalBody: 'College will remain closed.',
    notifyStudents: true,
    notifyTeachers: true,
    approvedBy: 5,
    approvedAt: '2026-05-30T18:05:00Z',
  );

  const sampleRejectedNotice = InstitutionHolidayNotice(
    id: 101,
    holidayId: 12,
    holidayName: 'Buddha Jayanti',
    holidayDateAd: '2026-05-31',
    holidayDateBs: '2083-02-17',
    institutionId: 1,
    status: NoticeStatus.REJECTED,
    approvedBy: 5,
    approvedAt: '2026-05-30T18:06:00Z',
  );

  setUp(() {
    mockRepo = MockHolidayNoticeRepository();
  });

  group('PendingNoticeNotifier', () {
    test('initial state is PendingNoticeInitial', () {
      final notifier = PendingNoticeNotifier(mockRepo);
      expect(notifier.state, isA<PendingNoticeInitial>());
    });

    test('fetchPendingNotice sets PendingNoticeLoaded with notice', () async {
      mockRepo.pendingResult = samplePending;
      final notifier = PendingNoticeNotifier(mockRepo);

      await notifier.fetchPendingNotice();

      expect(notifier.state, isA<PendingNoticeLoaded>());
      final loaded = notifier.state as PendingNoticeLoaded;
      expect(loaded.notice?.id, 101);
      expect(loaded.hasPending, isTrue);
    });

    test('fetchPendingNotice sets PendingNoticeLoaded(null) when none pending', () async {
      mockRepo.pendingResult = null;
      final notifier = PendingNoticeNotifier(mockRepo);

      await notifier.fetchPendingNotice();

      expect(notifier.state, isA<PendingNoticeLoaded>());
      final loaded = notifier.state as PendingNoticeLoaded;
      expect(loaded.notice, isNull);
      expect(loaded.hasPending, isFalse);
    });

    test('fetchPendingNotice sets PendingNoticeError on exception', () async {
      mockRepo.errorToThrow = const ServerFailure('Connection failed');
      final notifier = PendingNoticeNotifier(mockRepo);

      await notifier.fetchPendingNotice();

      expect(notifier.state, isA<PendingNoticeError>());
      final err = notifier.state as PendingNoticeError;
      expect(err.message, contains('Connection failed'));
    });

    test('clearPending resets to null loaded state', () async {
      mockRepo.pendingResult = samplePending;
      final notifier = PendingNoticeNotifier(mockRepo);
      await notifier.fetchPendingNotice();

      notifier.clearPending();
      final loaded = notifier.state as PendingNoticeLoaded;
      expect(loaded.notice, isNull);
    });
  });

  group('NoticeDetailNotifier', () {
    test('initializes with initialPending immediately in loaded state', () {
      final notifier = NoticeDetailNotifier(
        repository: mockRepo,
        noticeId: 101,
        initialPending: samplePending,
      );

      expect(notifier.state, isA<NoticeDetailLoaded>());
      final loaded = notifier.state as NoticeDetailLoaded;
      expect(loaded.pendingNotice?.id, 101);
      expect(mockRepo.loadNoticeCalls, 0);
    });

    test('approves notice successfully', () async {
      mockRepo.approveResult = sampleApprovedNotice;
      final notifier = NoticeDetailNotifier(
        repository: mockRepo,
        noticeId: 101,
        initialPending: samplePending,
      );

      final result = await notifier.approve(
        variant: NoticeVariant.CLOSED,
        customTitle: 'Custom Holiday',
        customBody: 'Custom Body',
        notifyStudents: true,
        notifyTeachers: false,
      );

      expect(result, isTrue);
      expect(mockRepo.approveCalls, 1);
      expect(notifier.state, isA<NoticeDetailLoaded>());
      final loaded = notifier.state as NoticeDetailLoaded;
      expect(loaded.notice?.status, NoticeStatus.APPROVED);
      expect(loaded.actionMessage, contains('Notice approved'));
    });

    test('handles 409 conflict during approve and reloads server state', () async {
      mockRepo.isConflictOnApprove = true;
      mockRepo.noticeByIdResult = sampleApprovedNotice;

      final notifier = NoticeDetailNotifier(
        repository: mockRepo,
        noticeId: 101,
        initialPending: samplePending,
      );

      final result = await notifier.approve(
        variant: NoticeVariant.CLOSED,
        notifyStudents: true,
        notifyTeachers: true,
      );

      expect(result, isFalse);
      expect(mockRepo.approveCalls, 1);
      // It should have caught conflict, transitioned through NoticeDetailConflict,
      // and reloaded current server state
      expect(mockRepo.loadNoticeCalls, 1);
      expect(notifier.state, isA<NoticeDetailLoaded>());
      final loaded = notifier.state as NoticeDetailLoaded;
      expect(loaded.notice?.status, NoticeStatus.APPROVED);
    });

    test('rejects notice successfully', () async {
      mockRepo.rejectResult = sampleRejectedNotice;
      final notifier = NoticeDetailNotifier(
        repository: mockRepo,
        noticeId: 101,
        initialPending: samplePending,
      );

      final result = await notifier.reject();

      expect(result, isTrue);
      expect(mockRepo.rejectCalls, 1);
      expect(notifier.state, isA<NoticeDetailLoaded>());
      final loaded = notifier.state as NoticeDetailLoaded;
      expect(loaded.notice?.status, NoticeStatus.REJECTED);
      expect(loaded.actionMessage, contains('not to announce'));
    });

    test('handles 409 conflict during reject and reloads server state', () async {
      mockRepo.isConflictOnReject = true;
      mockRepo.noticeByIdResult = sampleRejectedNotice;

      final notifier = NoticeDetailNotifier(
        repository: mockRepo,
        noticeId: 101,
        initialPending: samplePending,
      );

      final result = await notifier.reject();

      expect(result, isFalse);
      expect(mockRepo.rejectCalls, 1);
      expect(mockRepo.loadNoticeCalls, 1);
      expect(notifier.state, isA<NoticeDetailLoaded>());
      final loaded = notifier.state as NoticeDetailLoaded;
      expect(loaded.notice?.status, NoticeStatus.REJECTED);
    });
  });

  group('OfficialNoticesNotifier', () {
    const sampleOfficial = OfficialHolidayNotice(
      noticeId: 101,
      institutionId: 1,
      dateAd: '2026-05-31',
      dateBs: '2083-02-17',
      holidayName: 'Buddha Jayanti',
      variant: NoticeVariant.CLOSED,
      title: 'College Closed for Buddha Jayanti',
      body: 'Classes will be suspended.',
      publishedAt: '2026-05-30T18:10:00Z',
    );

    test('initial state is OfficialNoticesInitial', () {
      final notifier = OfficialNoticesNotifier(mockRepo);
      expect(notifier.state, isA<OfficialNoticesInitial>());
    });

    test('fetchNotices populates notice list when found', () async {
      mockRepo.officialResult = [sampleOfficial];
      final notifier = OfficialNoticesNotifier(mockRepo);

      await notifier.fetchNotices();

      expect(notifier.state, isA<OfficialNoticesLoaded>());
      final loaded = notifier.state as OfficialNoticesLoaded;
      expect(loaded.notices.length, 1);
      expect(loaded.notices.first.title, 'College Closed for Buddha Jayanti');
      expect(loaded.notices.first.variant, NoticeVariant.CLOSED);
    });

    test('fetchNotices populates empty list when empty', () async {
      mockRepo.officialResult = [];
      final notifier = OfficialNoticesNotifier(mockRepo);

      await notifier.fetchNotices();

      expect(notifier.state, isA<OfficialNoticesLoaded>());
      final loaded = notifier.state as OfficialNoticesLoaded;
      expect(loaded.notices, isEmpty);
    });

    test('fetchNotices sets error state on failure', () async {
      mockRepo.errorToThrow = const ServerFailure('Not found');
      final notifier = OfficialNoticesNotifier(mockRepo);

      await notifier.fetchNotices();

      expect(notifier.state, isA<OfficialNoticesError>());
      final err = notifier.state as OfficialNoticesError;
      expect(err.message, contains('Not found'));
    });

    test('setSingleNotice stores single notice directly', () {
      final notifier = OfficialNoticesNotifier(mockRepo);
      notifier.setSingleNotice(sampleOfficial);

      expect(notifier.state, isA<OfficialNoticesLoaded>());
      final loaded = notifier.state as OfficialNoticesLoaded;
      expect(loaded.notices.single.holidayName, 'Buddha Jayanti');
    });
  });
}
