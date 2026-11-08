import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_mobile/features/holiday_notices/data/models/holiday_notice_models.dart';
import 'package:bridge_mobile/features/holiday_notices/domain/entities/holiday_notice_enums.dart';

void main() {
  group('HolidayNoticeModel JSON deserialization', () {
    test('PendingNoticeModel parses Spring Boot API JSON correctly', () {
      final json = {
        'id': 101,
        'institutionId': 42,
        'status': 'AWAITING_DECISION',
        'holidayId': 1,
        'holidayDateAd': '2026-10-17',
        'holidayDateBs': '2083-07-01',
        'holidayName': 'Dashain - Vijaya Dashami',
        'holidayScope': 'NATIONWIDE',
        'closedDraft': {
          'title': 'Official Dashain Holiday Notice',
          'body': 'College will remain closed.',
          'origin': 'AI',
          'model': 'gemini-1.5-flash',
        },
        'openDraft': {
          'title': 'Notice: College Operations as Usual',
          'body': 'Classes proceed as scheduled.',
          'origin': 'TEMPLATE',
          'model': 'template',
        },
        'createdAt': '2026-10-16T12:00:00Z',
      };

      final model = PendingNoticeModel.fromJson(json);
      expect(model.id, equals(101));
      expect(model.institutionId, equals(42));
      expect(model.status, equals('AWAITING_DECISION'));
      expect(model.holidayName, equals('Dashain - Vijaya Dashami'));
      expect(model.closedDraft?.title, equals('Official Dashain Holiday Notice'));
      expect(model.openDraft?.origin, equals('TEMPLATE'));

      final entity = model.toEntity();
      expect(entity.status, equals(NoticeStatus.AWAITING_DECISION));
      expect(entity.closedDraft.variant, equals(NoticeVariant.CLOSED));
      expect(entity.closedDraft.origin, equals(NoticeOrigin.AI));
      expect(entity.openDraft.variant, equals(NoticeVariant.OPEN));
      expect(entity.openDraft.origin, equals(NoticeOrigin.TEMPLATE));
    });

    test('PendingNoticeModel handles NoticeView drafts array format', () {
      final json = {
        'holidayId': 12,
        'holidayName': 'Vijaya Dashami',
        'date': '2026-10-21',
        'dateBs': '2083-07-04',
        'status': 'AWAITING_DECISION',
        'drafts': [
          {
            'variant': 'CLOSED',
            'title': 'Closed Draft',
            'body': 'Closed body',
            'origin': 'AI',
          },
          {
            'variant': 'OPEN',
            'title': 'Open Draft',
            'body': 'Open body',
            'origin': 'TEMPLATE',
          }
        ],
      };

      final model = PendingNoticeModel.fromJson(json);
      expect(model.holidayId, equals(12));
      expect(model.holidayDateAd, equals('2026-10-21'));
      expect(model.closedDraft?.title, equals('Closed Draft'));
      expect(model.openDraft?.title, equals('Open Draft'));
    });

    test('InstitutionNoticeModel parses approved notice JSON and maps to entity', () {
      final json = {
        'id': 202,
        'holidayId': 5,
        'holidayDateAd': '2026-11-15',
        'holidayDateBs': '2083-07-29',
        'holidayName': 'Tihar',
        'institutionId': 10,
        'status': 'APPROVED',
        'variant': 'CLOSED',
        'finalTitle': 'Tihar Holiday Notice',
        'finalBody': 'Happy Tihar! College closed.',
        'customTitle': 'Tihar Holiday Notice',
        'customBody': 'Happy Tihar! College closed.',
        'notifyStudents': true,
        'notifyTeachers': false,
        'approvedBy': 99,
        'approvedAt': '2026-11-14T08:00:00Z',
        'attempts': 0,
        'version': 1,
      };

      final model = InstitutionNoticeModel.fromJson(json);
      expect(model.id, equals(202));
      expect(model.status, equals('APPROVED'));
      expect(model.notifyTeachers, isFalse);

      final entity = model.toEntity();
      expect(entity.status, equals(NoticeStatus.APPROVED));
      expect(entity.variant, equals(NoticeVariant.CLOSED));
      expect(entity.notifyStudents, isTrue);
      expect(entity.notifyTeachers, isFalse);
    });

    test('OfficialNoticeModel parses public endpoint JSON', () {
      final json = {
        'noticeId': 505,
        'institutionId': 88,
        'dateAd': '2026-10-17',
        'dateBs': '2083-07-01',
        'holidayName': 'Dashain',
        'variant': 'CLOSED',
        'title': 'Dashain Public Announcement',
        'body': 'College remains closed.',
        'publishedAt': '2026-10-16T12:30:00Z',
      };

      final model = OfficialNoticeModel.fromJson(json);
      expect(model.noticeId, equals(505));
      expect(model.variant, equals('CLOSED'));

      final entity = model.toEntity();
      expect(entity.noticeId, equals(505));
      expect(entity.variant, equals(NoticeVariant.CLOSED));
      expect(entity.holidayName, equals('Dashain'));
    });
  });
}
