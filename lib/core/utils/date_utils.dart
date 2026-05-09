import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  /// Returns the Monday of the week containing [date].
  static DateTime startOfWeek(DateTime date) {
    final weekday = date.weekday; // 1=Mon … 7=Sun
    return _dateOnly(date.subtract(Duration(days: weekday - 1)));
  }

  /// Returns the Sunday of the week containing [date].
  static DateTime endOfWeek(DateTime date) {
    return startOfWeek(date).add(const Duration(days: 6));
  }

  /// Strips time component from a [DateTime].
  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DateTime today() => _dateOnly(DateTime.now());

  /// Returns true if [date] falls in the same Mon–Sun week as [weekStart].
  static bool isInWeek(DateTime date, DateTime weekStart) {
    final d = _dateOnly(date);
    final end = endOfWeek(weekStart);
    return !d.isBefore(weekStart) && !d.isAfter(end);
  }

  /// e.g. "May 5 – 11, 2025"
  static String formatWeekRange(DateTime weekStart) {
    final end = endOfWeek(weekStart);
    final startFmt = DateFormat('MMM d').format(weekStart);
    final endFmt = weekStart.month == end.month
        ? DateFormat('d').format(end)
        : DateFormat('MMM d').format(end);
    final year = DateFormat('yyyy').format(end);
    return '$startFmt – $endFmt, $year';
  }

  /// e.g. "Mon 5"
  static String formatDayShort(DateTime date) =>
      DateFormat('E d').format(date);

  /// e.g. "Monday, May 5"
  static String formatDayFull(DateTime date) =>
      DateFormat('EEEE, MMM d').format(date);

  /// e.g. "10:30 AM"
  static String formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  /// Returns the 7 days of the week starting from [weekStart].
  static List<DateTime> weekDays(DateTime weekStart) =>
      List.generate(7, (i) => weekStart.add(Duration(days: i)));

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, today());

  static bool isPast(DateTime date) => _dateOnly(date).isBefore(today());

  /// ISO week number (1–53)
  static int weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday <= 4
        ? startOfYear.subtract(Duration(days: startOfYear.weekday - 1))
        : startOfYear.add(Duration(days: 8 - startOfYear.weekday));
    final diff = startOfWeek(date).difference(firstMonday).inDays;
    return (diff / 7).floor() + 1;
  }
}
