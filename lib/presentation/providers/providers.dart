import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app/core/utils/date_utils.dart';
import 'package:workout_app/data/models/exercise.dart';
import 'package:workout_app/data/models/week_summary.dart';
import 'package:workout_app/data/models/workout.dart';
import 'package:workout_app/data/repositories/exercise_repository.dart';
import 'package:workout_app/data/repositories/workout_repository.dart';
import 'package:workout_app/data/services/export_service.dart';
import 'package:workout_app/data/services/storage_service.dart';

// ── Infrastructure ─────────────────────────────────────────────────────────

/// Singleton storage service — initialised before runApp.
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Override in ProviderScope');
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(storageServiceProvider));
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(storageServiceProvider));
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.watch(storageServiceProvider));
});

// ── Exercises ──────────────────────────────────────────────────────────────

class ExerciseNotifier extends StateNotifier<List<Exercise>> {
  final ExerciseRepository _repo;

  ExerciseNotifier(this._repo) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();

  Future<void> save(Exercise exercise) async {
    await _repo.save(exercise);
    refresh();
  }

  Future<void> add(Exercise exercise) => save(exercise);

  Future<void> update(Exercise exercise) => save(exercise);

  Future<void> delete(String id) async {
    await _repo.delete(id);
    refresh();
  }
}

final exerciseNotifierProvider =
    StateNotifierProvider<ExerciseNotifier, List<Exercise>>((ref) {
      return ExerciseNotifier(ref.watch(exerciseRepositoryProvider));
    });

// ── Workouts ───────────────────────────────────────────────────────────────

class WorkoutNotifier extends StateNotifier<List<Workout>> {
  final WorkoutRepository _repo;

  WorkoutNotifier(this._repo) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();

  Future<void> save(Workout workout) async {
    await _repo.save(workout);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    refresh();
  }

  /// Marks a workout as complete and stamps completedAt.
  Future<void> complete(
    String id, {
    int? durationMinutes,
    String? notes,
  }) async {
    final workout = state.firstWhere((w) => w.id == id);
    final updated = workout.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      durationMinutes: durationMinutes,
      notes: notes ?? workout.notes,
    );
    await save(updated);
  }

  /// Toggles a single set completion inside a workout.
  Future<void> toggleSet(
    String workoutId,
    String exerciseId,
    String setId,
  ) async {
    final workout = state.firstWhere((w) => w.id == workoutId);
    final updatedExercises = workout.exercises.map((ex) {
      if (ex.id != exerciseId) return ex;
      final updatedSets = ex.sets.map((s) {
        if (s.id != setId) return s;
        return s.copyWith(isCompleted: !s.isCompleted);
      }).toList();
      final allDone = updatedSets.every((s) => s.isCompleted);
      return ex.copyWith(sets: updatedSets, isCompleted: allDone);
    }).toList();
    await save(workout.copyWith(exercises: updatedExercises));
  }

  /// Toggles a whole exercise's completion within a workout.
  Future<void> toggleExercise(String workoutId, String exerciseId) async {
    final workout = state.firstWhere((w) => w.id == workoutId);
    final updatedExercises = workout.exercises.map((ex) {
      if (ex.id != exerciseId) return ex;
      final newDone = !ex.isCompleted;
      final updatedSets = ex.sets
          .map((s) => s.copyWith(isCompleted: newDone))
          .toList();
      return ex.copyWith(isCompleted: newDone, sets: updatedSets);
    }).toList();
    await save(workout.copyWith(exercises: updatedExercises));
  }
}

final workoutNotifierProvider =
    StateNotifierProvider<WorkoutNotifier, List<Workout>>((ref) {
      return WorkoutNotifier(ref.watch(workoutRepositoryProvider));
    });

// ── Templates ──────────────────────────────────────────────────────────────

class TemplateNotifier extends StateNotifier<List<WorkoutTemplate>> {
  final WorkoutRepository _repo;

  TemplateNotifier(this._repo) : super(_repo.getAllTemplates());

  void refresh() => state = _repo.getAllTemplates();

  Future<void> save(WorkoutTemplate template) async {
    await _repo.saveTemplate(template);
    refresh();
  }

  Future<void> delete(String id) async {
    await _repo.deleteTemplate(id);
    refresh();
  }
}

final templateNotifierProvider =
    StateNotifierProvider<TemplateNotifier, List<WorkoutTemplate>>((ref) {
      return TemplateNotifier(ref.watch(workoutRepositoryProvider));
    });

// ── Week navigation ─────────────────────────────────────────────────────────

/// Currently displayed week (start = Monday). Defaults to current week.
final currentWeekStartProvider = StateProvider<DateTime>((ref) {
  return AppDateUtils.startOfWeek(DateTime.now());
});

/// Workouts for the currently displayed week.
final currentWeekWorkoutsProvider = Provider<List<Workout>>((ref) {
  final weekStart = ref.watch(currentWeekStartProvider);
  final allWorkouts = ref.watch(workoutNotifierProvider);
  final weekEnd = AppDateUtils.endOfWeek(weekStart);
  return allWorkouts.where((w) {
    final d = DateTime(w.date.year, w.date.month, w.date.day);
    return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
  }).toList();
});

/// Workouts for a specific day in the current week.
final workoutsForDayProvider = Provider.family<List<Workout>, DateTime>((
  ref,
  day,
) {
  final weekWorkouts = ref.watch(currentWeekWorkoutsProvider);
  return weekWorkouts
      .where((w) => AppDateUtils.isSameDay(w.date, day))
      .toList();
});

/// Week summary for the currently displayed week.
final currentWeekSummaryProvider = Provider<WeekSummary>((ref) {
  final weekStart = ref.watch(currentWeekStartProvider);
  ref.watch(workoutNotifierProvider); // re-run on workout changes
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.summaryForWeek(weekStart);
});

// ── Settings ───────────────────────────────────────────────────────────────

final weightUnitProvider = StateProvider<String>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.getSetting('weight_unit') ?? 'kg';
});
