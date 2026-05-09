import '../models/workout.dart';
import '../models/week_summary.dart';
import '../services/storage_service.dart';
import '../../core/utils/date_utils.dart';

class WorkoutRepository {
  final StorageService _storage;

  WorkoutRepository(this._storage);

  List<Workout> getAll() => _storage.getAllWorkouts();

  List<Workout> getForWeek(DateTime weekStart) =>
      _storage.getWorkoutsForWeek(weekStart);

  Future<void> save(Workout workout) => _storage.saveWorkout(workout);

  Future<void> delete(String id) => _storage.deleteWorkout(id);

  // ── Templates ─────────────────────────────────────────────────────────────

  List<WorkoutTemplate> getAllTemplates() => _storage.getAllTemplates();

  Future<void> saveTemplate(WorkoutTemplate template) =>
      _storage.saveTemplate(template);

  Future<void> deleteTemplate(String id) => _storage.deleteTemplate(id);

  // ── Week summary ──────────────────────────────────────────────────────────

  WeekSummary summaryForWeek(DateTime weekStart) {
    final workouts = getForWeek(weekStart);
    /*     final today = AppDateUtils.today();
    final weekEnd = AppDateUtils.endOfWeek(weekStart); */

    final planned = <Workout>[];
    final completed = <Workout>[];
    final missed = <Workout>[];
    final adhoc = <Workout>[];

    for (final w in workouts) {
      switch (w.status) {
        case WorkoutStatus.completed:
          planned.add(w);
          completed.add(w);
          break;
        case WorkoutStatus.missed:
          planned.add(w);
          missed.add(w);
          break;
        case WorkoutStatus.planned:
          // Only include planned future/today workouts in planned list
          // for in-progress weeks
          planned.add(w);
          break;
        case WorkoutStatus.adhoc:
          adhoc.add(w);
          break;
      }
    }

    return WeekSummary(
      weekStart: weekStart,
      planned: planned.where((w) => w.isPlanned).toList(),
      completed: completed,
      missed: missed,
      adhoc: adhoc,
    );
  }

  /// Returns all distinct week starts (Mondays) that have workouts.
  List<DateTime> getWeeksWithData() {
    final weeks = <DateTime>{};
    for (final w in getAll()) {
      weeks.add(AppDateUtils.startOfWeek(w.date));
    }
    final sorted = weeks.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }
}
