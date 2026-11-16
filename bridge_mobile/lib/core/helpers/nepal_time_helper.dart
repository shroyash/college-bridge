/// Helper for Nepal Standard Time (NPT: UTC+5:45, no daylight saving time).
/// Guarantees that date labels and relative day descriptions ('Today', 'Tomorrow', etc.)
/// are evaluated strictly against Kathmandu calendar time, irrespective of the device's
/// local physical timezone.
abstract class NepalTimeHelper {
  /// Nepal Standard Time offset from UTC (+05:45).
  static const Duration nptOffset = Duration(hours: 5, minutes: 45);

  /// Returns current instant converted to Nepal calendar time.
  static DateTime nowInNepal([DateTime? customNow]) {
    final utc = (customNow ?? DateTime.now()).toUtc();
    return utc.add(nptOffset);
  }

  /// Extracts Nepal calendar date (year, month, day) with 00:00:00 time.
  static DateTime nepalDate(DateTime dateTime) {
    final npt = dateTime.isUtc ? dateTime.add(nptOffset) : dateTime.toUtc().add(nptOffset);
    return DateTime(npt.year, npt.month, npt.day);
  }

  /// Parses an ISO date string ('YYYY-MM-DD') into a date-only object.
  static DateTime parseDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length >= 3) {
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2].substring(0, 2)),
      );
    }
    return DateTime.parse(dateStr);
  }

  /// Computes relative day label in Nepal calendar days ('Today', 'Tomorrow', 'In N days', 'Yesterday', 'Past').
  static String relativeLabel(String dateStr, [DateTime? currentInstant]) {
    final target = parseDate(dateStr);
    final nepalNow = nowInNepal(currentInstant);
    final today = DateTime(nepalNow.year, nepalNow.month, nepalNow.day);

    final differenceInDays = target.difference(today).inDays;

    if (differenceInDays == 0) {
      return 'Today';
    } else if (differenceInDays == 1) {
      return 'Tomorrow';
    } else if (differenceInDays == -1) {
      return 'Yesterday';
    } else if (differenceInDays > 1) {
      return 'In $differenceInDays days';
    } else {
      return 'Passed';
    }
  }

  /// Formats date into readable English (e.g. 'Thursday, 17 Oct 2024').
  static String formatReadableDate(String dateStr) {
    try {
      final date = parseDate(dateStr);
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];

      final weekday = weekdays[date.weekday - 1];
      final month = months[date.month - 1];
      return '$weekday, ${date.day} $month ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  /// Formats an ISO Instant (UTC) into Nepal time display (e.g. '17 Oct 2024, 01:30 PM NPT').
  static String formatNepalDateTime(String isoUtc) {
    try {
      final utc = DateTime.parse(isoUtc).toUtc();
      final npt = utc.add(nptOffset);

      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];

      final month = months[npt.month - 1];
      final hour = npt.hour % 12 == 0 ? 12 : npt.hour % 12;
      final minute = npt.minute.toString().padLeft(2, '0');
      final period = npt.hour >= 12 ? 'PM' : 'AM';

      return '${npt.day} $month ${npt.year}, $hour:$minute $period NPT';
    } catch (_) {
      return isoUtc;
    }
  }
}
