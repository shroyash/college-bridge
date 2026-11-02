import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_mobile/core/network/api_client.dart';
import 'package:bridge_mobile/core/network/page_response.dart';
import 'package:bridge_mobile/core/storage/secure_storage_service.dart';
import 'package:bridge_mobile/core/widgets/clickable.dart';
import 'package:bridge_mobile/features/notifications/data/models/create_notification_request_model.dart';
import 'package:bridge_mobile/features/notifications/data/models/notification_item_model.dart';
import 'package:bridge_mobile/features/notifications/domain/entities/notification_item.dart';
import 'package:bridge_mobile/features/notifications/domain/entities/notification_target_type.dart';
import 'package:bridge_mobile/features/notifications/domain/repositories/notification_repository.dart';
import 'package:bridge_mobile/features/notifications/presentation/controllers/notification_notifier.dart';
import 'package:bridge_mobile/features/notifications/presentation/widgets/searchable_selection_field.dart';
import 'package:bridge_mobile/features/notifications/presentation/widgets/student_multi_selection_field.dart';
import 'package:bridge_mobile/features/students/data/datasources/student_admin_remote_datasource.dart';
import 'package:bridge_mobile/features/students/presentation/controllers/student_management_providers.dart';

class MockNotificationRepository implements NotificationRepository {
  bool markAsReadCalled = false;
  int? markedId;

  @override
  Future<PageResponse<NotificationItem>> getNotifications({int page = 0, int size = 20}) async {
    return PageResponse<NotificationItem>(
      content: [
        NotificationItem(
          notificationId: 101,
          title: 'Exam Schedule',
          body: 'Schedule posted.',
          senderId: 1,
          senderName: 'Admin',
          targetType: NotificationTargetType.CLASS,
          targetId: 5,
          createdAt: DateTime.parse('2026-10-04T10:00:00Z'),
          isRead: false,
        ),
      ],
      pageNumber: 0,
      pageSize: 20,
      totalElements: 1,
      totalPages: 1,
      last: true,
      first: true,
    );
  }

  @override
  Future<int> getUnreadCount() async => 1;

  @override
  Future<void> markAsRead(int notificationId) async {
    markAsReadCalled = true;
    markedId = notificationId;
  }

  @override
  Future<void> createNotification(CreateNotificationRequestModel request) async {}

  @override
  Future<void> registerDeviceToken({required String token, required String platform}) async {}

  @override
  Future<void> deregisterDeviceToken(String token) async {}
}

class MockStudentAdminDataSource extends StudentAdminRemoteDataSource {
  MockStudentAdminDataSource()
      : super(ApiClient(),
            SecureStorageService(storage: const FlutterSecureStorage()));

  @override
  Future<PagedStudents> getStudents({
    String? faculty,
    int? semester,
    String? search,
    int page = 0,
    int size = 20,
  }) async {
    final all = List.generate(
      25,
      (i) => StudentSummary(
        userId: 100 + i,
        studentId: 200 + i,
        name: 'Student $i',
        email: 'student$i@test.com',
        status: 'ACTIVE',
        faculty: 'BCA',
        semester: 2,
      ),
    );

    final filtered = search != null && search.isNotEmpty
        ? all
            .where((s) =>
                s.name.toLowerCase().contains(search.toLowerCase()) ||
                s.email.toLowerCase().contains(search.toLowerCase()))
            .toList()
        : all;

    final start = page * size;
    final end =
        (start + size) > filtered.length ? filtered.length : start + size;
    final pageItems = start < filtered.length
        ? filtered.sublist(start, end)
        : <StudentSummary>[];

    return PagedStudents(
      students: pageItems,
      totalElements: filtered.length,
      totalPages: (filtered.length / size).ceil(),
      currentPage: page,
    );
  }
}

void main() {
  group('Notification Model & Logic Tests', () {
    test('NotificationItemModel parses backend JSON correctly', () {
      final json = {
        "notificationId": 123,
        "title": "Exam Schedule",
        "body": "Your schedule has been published.",
        "senderId": 5,
        "senderName": "Dr. Smith",
        "targetType": "CLASS",
        "targetId": 10,
        "createdAt": "2026-10-04T05:52:00Z",
        "read": false,
      };

      final model = NotificationItemModel.fromJson(json);

      expect(model.notificationId, 123);
      expect(model.title, 'Exam Schedule');
      expect(model.body, 'Your schedule has been published.');
      expect(model.senderName, 'Dr. Smith');
      expect(model.targetType, NotificationTargetType.CLASS);
      expect(model.isRead, false);
    });

    test('NotificationNotifier fetches inbox and updates unread count', () async {
      final mockRepo = MockNotificationRepository();
      final notifier = NotificationNotifier(mockRepo);

      await notifier.fetchInbox();

      expect(notifier.state.items.length, 1);
      expect(notifier.state.unreadCount, 1);
      expect(notifier.state.items.first.isRead, false);
    });

    test('NotificationNotifier marks item as read and decrements unread count', () async {
      final mockRepo = MockNotificationRepository();
      final notifier = NotificationNotifier(mockRepo);

      await notifier.fetchInbox();
      expect(notifier.state.unreadCount, 1);

      await notifier.markAsRead(101);

      expect(mockRepo.markAsReadCalled, true);
      expect(mockRepo.markedId, 101);
      expect(notifier.state.items.first.isRead, true);
      expect(notifier.state.unreadCount, 0);
    });

    testWidgets('SearchableSelectionField renders loading and error states', (tester) async {
      bool retried = false;

      // Loading state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchableSelectionField<String>(
              label: 'Subject',
              hintText: 'Select a subject...',
              asyncItems: const AsyncValue.loading(),
              selectedItem: null,
              onSelected: (_) {},
              titleBuilder: (s) => s,
              searchMatcher: (s, q) => s.contains(q),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Loading options...'), findsOneWidget);

      // Error state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchableSelectionField<String>(
              label: 'Subject',
              hintText: 'Select a subject...',
              asyncItems: const AsyncValue.error('Network failure', StackTrace.empty),
              selectedItem: null,
              onSelected: (_) {},
              titleBuilder: (s) => s,
              searchMatcher: (s, q) => s.contains(q),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Network failure'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, true);
    });

    testWidgets('SearchableSelectionField renders data, opens search sheet, and selects item', (tester) async {
      String? selected;

      final subjects = ['Data Structures', 'Algorithms', 'Database Systems'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (ctx, setState) {
                return SearchableSelectionField<String>(
                  label: 'Subject',
                  hintText: 'Select a subject...',
                  asyncItems: AsyncValue.data(subjects),
                  selectedItem: selected,
                  onSelected: (val) => setState(() => selected = val),
                  titleBuilder: (s) => s,
                  searchMatcher: (s, q) => s.toLowerCase().contains(q.toLowerCase()),
                  onRetry: () {},
                );
              },
            ),
          ),
        ),
      );

      // Before selection
      expect(find.text('Select a subject...'), findsOneWidget);

      // Tap trigger to open sheet
      await tester.tap(find.text('Select a subject...'));
      await tester.pumpAndSettle();

      // Search sheet is open with all items
      expect(find.text('Data Structures'), findsOneWidget);
      expect(find.text('Algorithms'), findsOneWidget);
      expect(find.text('Database Systems'), findsOneWidget);

      // Filter via search
      await tester.enterText(find.byType(TextField), 'algo');
      await tester.pumpAndSettle();

      expect(find.text('Algorithms'), findsOneWidget);
      expect(find.text('Data Structures'), findsNothing);

      // Select filtered item
      await tester.tap(find.text('Algorithms'));
      await tester.pumpAndSettle();

      // Selection updated
      expect(selected, 'Algorithms');
      expect(find.text('Algorithms'), findsOneWidget);
    });

    test('CreateNotificationRequestModel formats userIds correctly', () {
      const request = CreateNotificationRequestModel(
        title: 'Meeting Alert',
        body: 'Please attend.',
        targetType: NotificationTargetType.USERS,
        userIds: [101, 102, 103],
        idempotencyKey: 'idemp-123',
      );

      final json = request.toJson();
      expect(json['title'], 'Meeting Alert');
      expect(json['body'], 'Please attend.');
      expect(json['targetType'], 'USERS');
      expect(json['userIds'], [101, 102, 103]);
      expect(json['idempotencyKey'], 'idemp-123');
    });

    testWidgets('StudentMultiSelectionField loads 10 students per page, allows multi-select, and pagination', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      Map<int, StudentSummary> selectedStudents = {};

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentAdminDataSourceProvider.overrideWithValue(MockStudentAdminDataSource()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return StudentMultiSelectionField(
                      selectedStudents: selectedStudents,
                      onSelectionChanged: (updated) {
                        setState(() {
                          selectedStudents = updated;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Page 1 should show 10 items (Student 0 to Student 9)
      expect(find.text('Page 1 of 3'), findsOneWidget);
      expect(find.text('25 total students'), findsOneWidget);
      expect(find.text('Student 0'), findsOneWidget);
      expect(find.text('Student 9'), findsOneWidget);
      expect(find.text('Student 10'), findsNothing);

      // Select Student 0
      await tester.tap(find.text('Student 0'));
      await tester.pumpAndSettle();
      expect(selectedStudents.containsKey(100), isTrue);
      expect(find.text('1 selected'), findsOneWidget);

      // Select Student 1
      await tester.tap(find.text('Student 1'));
      await tester.pumpAndSettle();
      expect(selectedStudents.containsKey(101), isTrue);
      expect(find.text('2 selected'), findsOneWidget);

      // Tap Next to go to Page 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2 of 3'), findsOneWidget);
      expect(find.text('Student 10'), findsOneWidget);
      expect(find.text('Student 19'), findsOneWidget);
      // Selected count is preserved
      expect(find.text('2 selected'), findsOneWidget);

      // Select Student 10 on Page 2
      await tester.tap(find.text('Student 10'));
      await tester.pumpAndSettle();
      expect(selectedStudents.containsKey(110), isTrue);
      expect(find.text('3 selected'), findsOneWidget);

      // Search functionality
      await tester.enterText(find.byType(TextField), 'Student 5');
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Should find Student 5 and Student 5 is displayed
      expect(find.widgetWithText(Clickable, 'Student 5'), findsOneWidget);
    });
  });
}
