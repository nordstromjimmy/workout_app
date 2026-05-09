import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../../core/constants/app_constants.dart';

/// Low-level wrapper around Hive boxes.
/// All boxes store JSON strings keyed by entity ID.
class StorageService {
  late Box<String> _exerciseBox;
  late Box<String> _workoutBox;
  late Box<String> _templateBox;
  late Box<String> _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _exerciseBox = await Hive.openBox<String>(AppConstants.exerciseBox);
    _workoutBox = await Hive.openBox<String>(AppConstants.workoutBox);
    _templateBox = await Hive.openBox<String>(AppConstants.templateBox);
    _settingsBox = await Hive.openBox<String>(AppConstants.settingsBox);
  }

  /// Wipes all boxes. Use once during development, then remove the call.
  Future<void> clearAll() async {
    await _exerciseBox.clear();
    await _workoutBox.clear();
    await _templateBox.clear();
  }

  // ── Settings ─────────────────────────────────────────────────────────────

  String? getSetting(String key) => _settingsBox.get(key);
  Future<void> setSetting(String key, String value) =>
      _settingsBox.put(key, value);

  // ── Exercises ─────────────────────────────────────────────────────────────

  List<Exercise> getAllExercises() {
    return _exerciseBox.values
        .map(
          (json) => Exercise.fromJson(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> saveExercise(Exercise exercise) =>
      _exerciseBox.put(exercise.id, jsonEncode(exercise.toJson()));

  Future<void> deleteExercise(String id) => _exerciseBox.delete(id);

  bool get hasExercises => _exerciseBox.isNotEmpty;

  // ── Workouts ──────────────────────────────────────────────────────────────

  List<Workout> getAllWorkouts() {
    return _workoutBox.values
        .map(
          (json) => Workout.fromJson(jsonDecode(json) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<Workout> getWorkoutsForWeek(DateTime weekStart) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    return getAllWorkouts().where((w) {
      final d = DateTime(w.date.year, w.date.month, w.date.day);
      return !d.isBefore(weekStart) && !d.isAfter(weekEnd);
    }).toList();
  }

  Future<void> saveWorkout(Workout workout) =>
      _workoutBox.put(workout.id, jsonEncode(workout.toJson()));

  Future<void> deleteWorkout(String id) => _workoutBox.delete(id);

  // ── Templates ─────────────────────────────────────────────────────────────

  List<WorkoutTemplate> getAllTemplates() {
    return _templateBox.values
        .map(
          (json) => WorkoutTemplate.fromJson(
            jsonDecode(json) as Map<String, dynamic>,
          ),
        )
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> saveTemplate(WorkoutTemplate template) =>
      _templateBox.put(template.id, jsonEncode(template.toJson()));

  Future<void> deleteTemplate(String id) => _templateBox.delete(id);

  // ── Full export / import ──────────────────────────────────────────────────

  /// Returns the full data snapshot as a JSON-encodable map.
  Map<String, dynamic> exportAll() => {
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'exercises': getAllExercises().map((e) => e.toJson()).toList(),
    'workouts': getAllWorkouts().map((w) => w.toJson()).toList(),
    'templates': getAllTemplates().map((t) => t.toJson()).toList(),
  };

  /// Replaces all data with the imported snapshot.
  Future<void> importAll(Map<String, dynamic> data) async {
    await _exerciseBox.clear();
    await _workoutBox.clear();
    await _templateBox.clear();

    final exercises =
        (data['exercises'] as List?)
            ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    for (final e in exercises) {
      await saveExercise(e);
    }

    final workouts =
        (data['workouts'] as List?)
            ?.map((w) => Workout.fromJson(w as Map<String, dynamic>))
            .toList() ??
        [];
    for (final w in workouts) {
      await saveWorkout(w);
    }

    final templates =
        (data['templates'] as List?)
            ?.map((t) => WorkoutTemplate.fromJson(t as Map<String, dynamic>))
            .toList() ??
        [];
    for (final t in templates) {
      await saveTemplate(t);
    }
  }
}
