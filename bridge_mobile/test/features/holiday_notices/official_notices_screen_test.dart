import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_mobile/core/network/page_response.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/holiday_notice_enums.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/institution_holiday_notice.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/official_holiday_notice.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/pending_holiday_notice.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/repositories/holiday_notice_repository.dart';
import 'package:bridge_mobile/features/holiday_notices/presentation/controllers/holiday_notice_providers.dart';
import 'package:bridge_mobile/features/holiday_notices/presentation/screens/official_notice_detail_screen.dart';
import 'package:bridge_mobile/features/holiday_notices/presentation/screens/official_notices_screen.dart';

class MockHolidayNoticeRepository implements HolidayNoticeRepository {
  List<OfficialHolidayNotice> officialResult = [];
  bool returnEmpty = false;

  @override
  Future<PendingHolidayNotice?> getPendingNotice() async => null;

  @override
  Future<InstitutionHolidayNotice> getNoticeById(int id) async => throw UnimplementedError();

  @override
  Future<InstitutionHolidayNotice> approveNotice({
    required int id,
    required NoticeVariant variant,
    String? customTitle,
    String? customBody,
    required bool notifyStudents,
    required bool notifyTeachers,
  }) async =>
      throw UnimplementedError();

  @override
  Future<InstitutionHolidayNotice> rejectNotice(int id) async => throw UnimplementedError();

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
    if (returnEmpty) return [];
    return officialResult;
  }
}

void main() {
  late MockHolidayNoticeRepository mockRepo;

  const sampleOfficial = OfficialHolidayNotice(
    noticeId: 101,
    institutionId: 1,
    dateAd: '2026-05-31',
    dateBs: '2083-02-17',
    holidayName: 'Buddha Jayanti',
    variant: NoticeVariant.CLOSED,
    title: 'Holiday Notice: Buddha Jayanti Closure',
    body: 'The college administration hereby announces that all classes are suspended on Buddha Jayanti.',
    publishedAt: '2026-05-30T18:05:00Z',
  );

  setUp(() {
    mockRepo = MockHolidayNoticeRepository();
  });

  testWidgets('OfficialNoticesScreen shows empty state when no notices published', (tester) async {
    mockRepo.returnEmpty = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          holidayNoticeRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: OfficialNoticesScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No Notices'), findsOneWidget);
    expect(find.text('No holiday notices have been published yet.'), findsOneWidget);
  });

  testWidgets('OfficialNoticesScreen displays published notice card', (tester) async {
    mockRepo.officialResult = [sampleOfficial];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          holidayNoticeRepositoryProvider.overrideWithValue(mockRepo),
        ],
        child: const MaterialApp(
          home: OfficialNoticesScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Holiday Notice: Buddha Jayanti Closure'), findsOneWidget);
    expect(find.text('CLOSED'), findsOneWidget);
    expect(find.text('Buddha Jayanti'), findsOneWidget);
  });

  testWidgets('OfficialNoticeDetailScreen renders full official notice document', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OfficialNoticeDetailScreen(
          notice: sampleOfficial,
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Notice Details'), findsOneWidget);
    expect(find.text('Holiday Notice: Buddha Jayanti Closure'), findsOneWidget);
    expect(find.text('COLLEGE CLOSED'), findsOneWidget);
    expect(find.textContaining('2083-02-17 BS'), findsOneWidget);
    expect(find.text(sampleOfficial.body), findsOneWidget);
    expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
  });
}
