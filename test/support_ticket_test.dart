import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_mobile/features/support/data/models/support_ticket_model.dart';

void main() {
  group('SupportTicketModel Tests', () {
    test('SupportTicketModel parses JSON correctly', () {
      final json = {
        'ticketId': 101,
        'ticketNumber': 'TK-4821',
        'userId': 42,
        'userName': 'John Doe',
        'userEmail': 'john@example.com',
        'userRole': 'STUDENT',
        'institutionId': 1,
        'category': 'Account & Security',
        'subject': 'Cannot reset password',
        'description': 'Getting 400 error on submit.',
        'status': 'OPEN',
        'createdAt': '2026-11-02T10:00:00',
        'updatedAt': '2026-11-02T10:05:00',
      };

      final ticket = SupportTicketModel.fromJson(json);

      expect(ticket.ticketId, 101);
      expect(ticket.ticketNumber, 'TK-4821');
      expect(ticket.userId, 42);
      expect(ticket.userName, 'John Doe');
      expect(ticket.userEmail, 'john@example.com');
      expect(ticket.userRole, 'STUDENT');
      expect(ticket.institutionId, 1);
      expect(ticket.category, 'Account & Security');
      expect(ticket.subject, 'Cannot reset password');
      expect(ticket.description, 'Getting 400 error on submit.');
      expect(ticket.status, 'OPEN');
      expect(ticket.createdAt, isNotNull);
      expect(ticket.updatedAt, isNotNull);
    });

    test('SupportTicketModel serialization roundtrip', () {
      final ticket = SupportTicketModel(
        ticketId: 202,
        ticketNumber: 'TK-9999',
        userId: 55,
        userName: 'Prof. Smith',
        userEmail: 'smith@college.edu',
        userRole: 'TEACHER',
        category: 'Course/Subject Issue',
        subject: 'Missing grades view',
        description: 'Grades tab is not responding.',
        status: 'IN_PROGRESS',
        createdAt: DateTime(2026, 11, 2, 8, 30),
      );

      final map = ticket.toJson();
      expect(map['ticketId'], 202);
      expect(map['ticketNumber'], 'TK-9999');
      expect(map['category'], 'Course/Subject Issue');
      expect(map['status'], 'IN_PROGRESS');

      final deserialized = SupportTicketModel.fromJson(map);
      expect(deserialized.ticketNumber, 'TK-9999');
      expect(deserialized.userRole, 'TEACHER');
    });
  });
}

