import 'package:flutter_test/flutter_test.dart';
import 'package:bridge_mobile/core/helpers/nepal_time_helper.dart';

void main() {
  group('NepalTimeHelper', () {
    test('nptOffset is exactly 5 hours and 45 minutes', () {
      expect(NepalTimeHelper.nptOffset.inMinutes, equals(5 * 60 + 45));
    });

    test('nowInNepal converts UTC instant correctly to NPT (+05:45)', () {
      // 2026-10-15 18:30:00 UTC -> 2026-10-16 00:15:00 NPT (next day in Nepal)
      final utcTime = DateTime.utc(2026, 10, 15, 18, 30);
      final nptTime = NepalTimeHelper.nowInNepal(utcTime);

      expect(nptTime.year, equals(2026));
      expect(nptTime.month, equals(10));
      expect(nptTime.day, equals(16));
      expect(nptTime.hour, equals(0));
      expect(nptTime.minute, equals(15));
    });

    test('nepalDate returns midnight boundary of the Nepal calendar date', () {
      final utcTime = DateTime.utc(2026, 10, 15, 20, 0); // 01:45 AM Oct 16 in NPT
      final nptDate = NepalTimeHelper.nepalDate(utcTime);

      expect(nptDate.year, equals(2026));
      expect(nptDate.month, equals(10));
      expect(nptDate.day, equals(16));
      expect(nptDate.hour, equals(0));
      expect(nptDate.minute, equals(0));
    });

    test('relativeLabel computes Today, Tomorrow, In N days, Yesterday, and Passed', () {
      // Set fixed reference instant: 2026-10-16 10:00:00 NPT
      final fixedCurrentInstant = DateTime.utc(2026, 10, 16, 4, 15);

      expect(NepalTimeHelper.relativeLabel('2026-10-16', fixedCurrentInstant), equals('Today'));
      expect(NepalTimeHelper.relativeLabel('2026-10-17', fixedCurrentInstant), equals('Tomorrow'));
      expect(NepalTimeHelper.relativeLabel('2026-10-19', fixedCurrentInstant), equals('In 3 days'));
      expect(NepalTimeHelper.relativeLabel('2026-10-15', fixedCurrentInstant), equals('Yesterday'));
      expect(NepalTimeHelper.relativeLabel('2026-10-10', fixedCurrentInstant), equals('Passed'));
    });

    test('formatReadableDate produces formatted English date string', () {
      expect(NepalTimeHelper.formatReadableDate('2026-10-17'), equals('Saturday, 17 Oct 2026'));
      expect(NepalTimeHelper.formatReadableDate('2024-10-03'), equals('Thursday, 3 Oct 2024'));
    });

    test('formatNepalDateTime formats UTC ISO string to NPT representation', () {
      // 2026-10-16T07:15:00Z + 05:45 = 13:00 NPT (01:00 PM)
      final nptString = NepalTimeHelper.formatNepalDateTime('2026-10-16T07:15:00Z');
      expect(nptString, contains('16 Oct 2026, 1:00 PM NPT'));
    });
  });
}
