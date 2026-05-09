import 'workout.dart';

/// Computed summary for a Mon–Sun week.
class WeekSummary {
  final DateTime weekStart;
  final List<Workout> planned;
  final List<Workout> completed;
  final List<Workout> missed;
  final List<Workout> adhoc;

  const WeekSummary({
    required this.weekStart,
    required this.planned,
    required this.completed,
    required this.missed,
    required this.adhoc,
  });

  int get totalPlanned => planned.length;
  int get totalCompleted => completed.length;
  int get totalMissed => missed.length;
  int get totalAdhoc => adhoc.length;

  /// Ratio of planned workouts that were completed (0.0 – 1.0)
  double get planCompletionRatio =>
      totalPlanned == 0 ? 0 : totalCompleted / totalPlanned;

  WeekGrade get grade {
    if (totalPlanned == 0) {
      return totalAdhoc > 0 ? WeekGrade.unplanned : WeekGrade.empty;
    }
    final ratio = planCompletionRatio;
    if (ratio >= 1.0) {
      return totalAdhoc > 0 ? WeekGrade.exceeded : WeekGrade.perfect;
    }
    if (ratio >= 0.75) return WeekGrade.good;
    if (ratio >= 0.5) return WeekGrade.fair;
    return WeekGrade.poor;
  }

  String get gradeSummary {
    switch (grade) {
      case WeekGrade.exceeded:
        return 'Beyond plan 🔥';
      case WeekGrade.perfect:
        return 'Plan crushed ✅';
      case WeekGrade.good:
        return 'Solid week 💪';
      case WeekGrade.fair:
        return 'Halfway there 🙂';
      case WeekGrade.poor:
        return 'Rough week 😅';
      case WeekGrade.unplanned:
        return 'No plan, still showed up 👍';
      case WeekGrade.empty:
        return 'Rest week 😴';
    }
  }
}

enum WeekGrade { exceeded, perfect, good, fair, poor, unplanned, empty }
