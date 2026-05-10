import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  /// Strips time — DST-safe because it uses the constructor, not Duration.
  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Monday of the week containing [date]. DST-safe.
  static DateTime startOfWeek(DateTime date) {
    final d = _dateOnly(date);
    // DateTime constructor normalises day underflow (e.g. day 0 → last day of prev month)
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  /// Sunday of the week containing [date]. DST-safe.
  static DateTime endOfWeek(DateTime date) {
    final start = startOfWeek(date);
    return DateTime(start.year, start.month, start.day + 6);
  }

  static DateTime today() => _dateOnly(DateTime.now());

  /// Go back one week. DST-safe.
  static DateTime previousWeek(DateTime weekStart) {
    final d = _dateOnly(weekStart);
    return DateTime(d.year, d.month, d.day - 7);
  }

  /// Go forward one week. DST-safe.
  static DateTime nextWeek(DateTime weekStart) {
    final d = _dateOnly(weekStart);
    return DateTime(d.year, d.month, d.day + 7);
  }

  static bool isInWeek(DateTime date, DateTime weekStart) {
    final d = _dateOnly(date);
    final end = endOfWeek(weekStart);
    return !d.isBefore(weekStart) && !d.isAfter(end);
  }

  /// e.g. "5–11 jan 2026" or "29 dec – 4 jan 2026"
  static String formatWeekRange(DateTime weekStart) {
    final end = endOfWeek(weekStart);
    final startDay = weekStart.day;
    final endDay = end.day;
    final startMonth = DateFormat('MMM', 'sv').format(weekStart);
    final endMonth = DateFormat('MMM', 'sv').format(end);
    final year = end.year;

    if (weekStart.month == end.month) {
      return '$startDay–$endDay $endMonth $year';
    } else {
      return '$startDay $startMonth – $endDay $endMonth $year';
    }
  }

  /// e.g. "Mån 5"
  static String formatDayShort(DateTime date) {
    final weekday = DateFormat('E', 'sv').format(date);
    return '${weekday[0].toUpperCase()}${weekday.substring(1, 3)} ${date.day}';
  }

  /// e.g. "Måndag 5 maj"
  static String formatDayFull(DateTime date) {
    final weekday = DateFormat('EEEE', 'sv').format(date);
    final month = DateFormat('MMM', 'sv').format(date);
    return '${weekday[0].toUpperCase()}${weekday.substring(1)} ${date.day} $month';
  }

  /// e.g. "10:30"
  static String formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  /// The 7 days of the week starting from [weekStart].
  static List<DateTime> weekDays(DateTime weekStart) => List.generate(
    7,
    (i) => DateTime(weekStart.year, weekStart.month, weekStart.day + i),
  );

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, today());

  static bool isPast(DateTime date) => _dateOnly(date).isBefore(today());

  /// ISO 8601 week number (1–53).
  static int weekNumber(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    // Thursday of the same ISO week (weeks are defined by their Thursday)
    final thursday = DateTime(d.year, d.month, d.day + (4 - d.weekday));
    // Use UTC so DST never causes a 23h difference to truncate to the wrong day
    final thursdayUtc = DateTime.utc(
      thursday.year,
      thursday.month,
      thursday.day,
    );
    final firstJanUtc = DateTime.utc(thursday.year, 1, 1);
    return (thursdayUtc.difference(firstJanUtc).inDays / 7).floor() + 1;
  }
}
