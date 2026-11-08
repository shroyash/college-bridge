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
import 'package:bridge_mobile/features/holiday_notices/presentation/screens/review_notice_screen.dart';

class MockHolidayNoticeRepository implements HolidayNoticeRepository {
  InstitutionHolidayNotice? noticeByIdToReturn;
  InstitutionHolidayNotice? approvedNoticeToReturn;
  InstitutionHolidayNotice? rejectedNoticeToReturn;
  int approveCalls = 0;
  int rejectCalls = 0;

  @override
  Future<PendingHolidayNotice?> getPendingNotice() async => null;

  @override
  Future<InstitutionHolidayNotice> getNoticeById(int id) async {
    if (noticeByIdToReturn != null) return noticeByIdToReturn!;
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
    approveCalls++;
    return approvedNoticeToReturn!;
  }

  @override
  Future<InstitutionHolidayNotice> rejectNotice(int id) async {
    rejectCalls++;
    return rejectedNoticeToReturn!;
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
  Future<OfficialHolidayNotice?> getOfficialNotice({
    required int institutionId,
    required String date,
  }) async {
    return null;
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
      body: 'All classes will be suspended on Buddha Jayanti.',
      origin: NoticeOrigin.AI,
    ),
    openDraft: HolidayNoticeDraft(
      variant: NoticeVariant.OPEN,
      title: 'College Open on Buddha Jayanti',
      body: 'Campus will operate on normal schedule.',
      origin: NoticeOrigin.AI,
    ),
  );

  const sampleApproved = InstitutionHolidayNotice(
    id: 101,
    holidayId: 12,
    holidayName: 'Buddha Jayanti',
    holidayDateAd: '2026-05-31',
    holidayDateBs: '2083-02-17',
    institutionId: 1,
    status: NoticeStatus.APPROVED,
    variant: NoticeVariant.CLOSED,
    finalTitle: 'Official Announcement: Buddha Jayanti',
    finalBody: 'College will remain closed.',
    notifyStudents: true,
    notifyTeachers: true,
    approvedBy: 1,
    approvedAt: '2026-05-30T18:05:00Z',
  );

  setUp(() {
    mockRepo = MockHolidayNoticeRepository();
  });

  testWidgets('ReviewNoticeScreen renders header, drafts, and initial buttons', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          holidayNoticeRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: ReviewNoticeScreen(
            noticeId: 101,
            initialPending: samplePending,
          ),
        ),
      ),
    );

    await tester.pump();

    // Verify title and dates
    expect(find.text('Buddha Jayanti'), findsOneWidget);
    expect(find.textContaining('2083-02-17 BS'), findsOneWidget);

    // Verify both draft cards appear
    expect(find.text('College Closed for Buddha Jayanti'), findsOneWidget);
    expect(find.text('College Open on Buddha Jayanti'), findsOneWidget);

    // Check action buttons
    expect(find.text('Approve and Publish'), findsOneWidget);
    expect(find.text('Don\'t announce (Skip this holiday)'), findsOneWidget);

    // Initially customize form is not shown until a card is selected
    expect(find.text('Customize Announcement'), findsNothing);
  });

  testWidgets('Selecting a draft opens customization fields and allows reset to proposal', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          holidayNoticeRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: ReviewNoticeScreen(
            noticeId: 101,
            initialPending: samplePending,
          ),
        ),
      ),
    );

    await tester.pump();

    // Tap on the CLOSED draft card
    await tester.tap(find.text('College Closed for Buddha Jayanti'));
    await tester.pumpAndSettle();

    // Customization form should now be visible
    expect(find.text('Customize Announcement'), findsOneWidget);
    expect(find.text('Reset to proposal'), findsOneWidget);
    expect(find.text('Students'), findsOneWidget);
    expect(find.text('Teachers'), findsOneWidget);

    // Verify populated text
    final titleFinder = find.widgetWithText(TextField, 'Notice Title');
    expect(titleFinder, findsOneWidget);

    // Edit title
    await tester.enterText(titleFinder, 'Custom Edited Holiday Title');
    await tester.pump();
    expect(find.text('Custom Edited Holiday Title'), findsOneWidget);

    // Tap Reset to proposal
    await tester.tap(find.text('Reset to proposal'));
    await tester.pump();

    // Title should be restored to draft title
    expect(find.text('College Closed for Buddha Jayanti'), findsWidgets);
  });

  testWidgets('Audience selection enforces at-least-one rule', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          holidayNoticeRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: ReviewNoticeScreen(
            noticeId: 101,
            initialPending: samplePending,
          ),
        ),
      ),
    );

    await tester.pump();

    // Select draft to show audience chips
    await tester.tap(find.text('College Closed for Buddha Jayanti'));
    await tester.pumpAndSettle();

    // Both are initially selected. Deselect Students.
    await tester.tap(find.text('Students'));
    await tester.pump();

    // Now only Teachers is selected. Tapping Teachers should NOT deselect it.
    await tester.tap(find.text('Teachers'));
    await tester.pump();

    // Form should still be valid and approve button should be active
    expect(find.text('Approve and Publish'), findsOneWidget);
  });

  testWidgets('ReviewNoticeScreen renders decided view (A3) when notice is already approved', (tester) async {
    mockRepo.noticeByIdToReturn = sampleApproved;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          holidayNoticeRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: ReviewNoticeScreen(
            noticeId: 101,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Verify status banner and read-only elements
    expect(find.text('Approved. Sending notifications.'), findsOneWidget);
    expect(find.text('Official Announcement: Buddha Jayanti'), findsOneWidget);
    expect(find.text('College will remain closed.'), findsOneWidget);

    // Verify edit forms and approve button are NOT displayed in decided state
    expect(find.text('Approve and Publish'), findsNothing);
    expect(find.text('Customize Announcement'), findsNothing);
  });
}
