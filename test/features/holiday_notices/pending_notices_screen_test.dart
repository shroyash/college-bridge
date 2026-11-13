import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_mobile/core/network/page_response.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/holiday_notice_draft.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/holiday_notice_enums.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/institution_holiday_notice.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/official_holiday_notice.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/pending_holiday_notice.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/repositories/holiday_notice_repository.dart';
import 'package:bridge_mobile/features/holiday_notices/presentation/controllers/holiday_notice_providers.dart';
import 'package:bridge_mobile/features/holiday_notices/presentation/screens/pending_notices_screen.dart';

class MockHolidayNoticeRepository implements HolidayNoticeRepository {
  PendingHolidayNotice? pendingToReturn;
  bool returnNull = false;
  Object? errorToThrow;

  @override
  Future<PendingHolidayNotice?> getPendingNotice() async {
    if (errorToThrow != null) throw errorToThrow!;
    if (returnNull) return null;
    return pendingToReturn;
  }

  @override
  Future<InstitutionHolidayNotice> getNoticeById(int id) async {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }

  @override
  Future<InstitutionHolidayNotice> rejectNotice(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<PageResponse<InstitutionHolidayNotice>> getHistory({
    int page = 0,
    int size = 10,
  }) async {
    return const PageResponse<InstitutionHolidayNotice>(
      content: [],
      totalPages: 0,
      totalElements: 0,
      pageSize: 10,
      pageNumber: 0,
      first: true,
      last: true,
    );
  }

  @override
  Future<List<OfficialHolidayNotice>> getOfficialNotices({
    int page = 0,
    int size = 20,
  }) async {
    return const [];
  }
}

void main() {
  late MockHolidayNoticeRepository mockRepo;

  const samplePending = PendingHolidayNotice(
    id: 101,
    institutionId: 1,
    holidayId: 12,
    holidayName: 'Ghatasthapana',
    holidayDateAd: '2026-10-11',
    holidayDateBs: '2083-06-25',
    holidayScope: 'NATIONWIDE',
    status: NoticeStatus.AWAITING_DECISION,
    closedDraft: HolidayNoticeDraft(
      variant: NoticeVariant.CLOSED,
      title: 'College Closed for Ghatasthapana',
      body: 'All academic activities are suspended.',
      origin: NoticeOrigin.AI,
    ),
    openDraft: HolidayNoticeDraft(
      variant: NoticeVariant.OPEN,
      title: 'College Open on Ghatasthapana',
      body: 'Regular lectures proceed as scheduled.',
      origin: NoticeOrigin.AI,
    ),
  );

  setUp(() {
    mockRepo = MockHolidayNoticeRepository();
  });

  testWidgets('PendingNoticesScreen shows empty state when no notices are pending', (tester) async {
    mockRepo.returnNull = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          holidayNoticeRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: PendingNoticesScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('All Caught Up'), findsOneWidget);
    expect(
      find.text('No holiday notices need your decision.'),
      findsOneWidget,
    );
  });

  testWidgets('PendingNoticesScreen renders pending notice card with holiday info and drafts preview', (tester) async {
    mockRepo.pendingToReturn = samplePending;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          holidayNoticeRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: PendingNoticesScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ghatasthapana'), findsOneWidget);
    expect(find.textContaining('2083-06-25 BS'), findsOneWidget);
    expect(find.text('Needs Decision'), findsOneWidget);
    expect(find.text('Review drafts & publish'), findsOneWidget);
    expect(find.text('Scope: NATIONWIDE'), findsOneWidget);
  });
}
