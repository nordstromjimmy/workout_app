// ---------------------------------------------------------------------------
// ExerciseSet — one set within a workout exercise
// ---------------------------------------------------------------------------
class ExerciseSet {
  final String id;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds; // for timed sets / cardio
  final double? distanceKm; // for cardio
  final bool isCompleted;

  const ExerciseSet({
    required this.id,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceKm,
    this.isCompleted = false,
  });

  ExerciseSet copyWith({
    String? id,
    int? reps,
    double? weightKg,
    int? durationSeconds,
    double? distanceKm,
    bool? isCompleted,
  }) =>
      ExerciseSet(
        id: id ?? this.id,
        reps: reps ?? this.reps,
        weightKg: weightKg ?? this.weightKg,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        distanceKm: distanceKm ?? this.distanceKm,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'reps': reps,
        'weightKg': weightKg,
        'durationSeconds': durationSeconds,
        'distanceKm': distanceKm,
        'isCompleted': isCompleted,
      };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
        id: json['id'] as String,
        reps: json['reps'] as int?,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        durationSeconds: json['durationSeconds'] as int?,
        distanceKm: (json['distanceKm'] as num?)?.toDouble(),
        isCompleted: json['isCompleted'] as bool? ?? false,
      );

  /// Human-readable label like "3 × 10 @ 80 kg" or "5 km"
  String get label {
    final parts = <String>[];
    if (reps != null) parts.add('$reps reps');
    if (weightKg != null) parts.add('${weightKg!.toStringAsFixed(weightKg! % 1 == 0 ? 0 : 1)} kg');
    if (durationSeconds != null) {
      final m = durationSeconds! ~/ 60;
      final s = durationSeconds! % 60;
      parts.add(m > 0 ? '${m}m ${s}s' : '${s}s');
    }
    if (distanceKm != null) parts.add('${distanceKm!.toStringAsFixed(1)} km');
    return parts.isEmpty ? 'Set' : parts.join(' · ');
  }
}

// ---------------------------------------------------------------------------
// WorkoutExercise — exercise + its sets within a workout
// ---------------------------------------------------------------------------
class WorkoutExercise {
  final String id;
  final String exerciseId;
  final String exerciseName; // denormalised for display without a join
  final String exerciseCategory;
  final List<ExerciseSet> sets;
  final String? notes;
  final bool isCompleted;

  const WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseCategory,
    required this.sets,
    this.notes,
    this.isCompleted = false,
  });

  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    String? exerciseCategory,
    List<ExerciseSet>? sets,
    String? notes,
    bool? isCompleted,
  }) =>
      WorkoutExercise(
        id: id ?? this.id,
        exerciseId: exerciseId ?? this.exerciseId,
        exerciseName: exerciseName ?? this.exerciseName,
        exerciseCategory: exerciseCategory ?? this.exerciseCategory,
        sets: sets ?? this.sets,
        notes: notes ?? this.notes,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  double get completionRatio {
    if (sets.isEmpty) return 0;
    return sets.where((s) => s.isCompleted).length / sets.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'exerciseCategory': exerciseCategory,
        'sets': sets.map((s) => s.toJson()).toList(),
        'notes': notes,
        'isCompleted': isCompleted,
      };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      WorkoutExercise(
        id: json['id'] as String,
        exerciseId: json['exerciseId'] as String,
        exerciseName: json['exerciseName'] as String,
        exerciseCategory: json['exerciseCategory'] as String? ?? 'Strength',
        sets: (json['sets'] as List)
            .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String?,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

// ---------------------------------------------------------------------------
// Workout — a single training session (planned or ad-hoc)
// ---------------------------------------------------------------------------
enum WorkoutStatus {
  planned,    // planned, not yet due
  completed,  // done ✓
  missed,     // planned + date in past + not completed
  adhoc,      // not planned, but completed
}

class Workout {
  final String id;
  final String name;
  final DateTime date; // planned/target date (date only, time stripped)
  final List<WorkoutExercise> exercises;
  final bool isPlanned; // was this created during weekly planning?
  final bool isCompleted;
  final DateTime? completedAt;
  final int? durationMinutes; // actual session length
  final String? notes;

  // Template reference — if this workout was spawned from a template
  final String? templateId;

  const Workout({
    required this.id,
    required this.name,
    required this.date,
    required this.exercises,
    this.isPlanned = false,
    this.isCompleted = false,
    this.completedAt,
    this.durationMinutes,
    this.notes,
    this.templateId,
  });

  Workout copyWith({
    String? id,
    String? name,
    DateTime? date,
    List<WorkoutExercise>? exercises,
    bool? isPlanned,
    bool? isCompleted,
    DateTime? completedAt,
    int? durationMinutes,
    String? notes,
    String? templateId,
  }) =>
      Workout(
        id: id ?? this.id,
        name: name ?? this.name,
        date: date ?? this.date,
        exercises: exercises ?? this.exercises,
        isPlanned: isPlanned ?? this.isPlanned,
        isCompleted: isCompleted ?? this.isCompleted,
        completedAt: completedAt ?? this.completedAt,
        durationMinutes: durationMinutes ?? this.durationMinutes,
        notes: notes ?? this.notes,
        templateId: templateId ?? this.templateId,
      );

  WorkoutStatus get status {
    if (isCompleted) {
      return isPlanned ? WorkoutStatus.completed : WorkoutStatus.adhoc;
    }
    if (isPlanned) {
      final today = DateTime.now();
      final dateOnly = DateTime(date.year, date.month, date.day);
      final todayOnly = DateTime(today.year, today.month, today.day);
      if (dateOnly.isBefore(todayOnly)) return WorkoutStatus.missed;
      return WorkoutStatus.planned;
    }
    return WorkoutStatus.planned;
  }

  double get exerciseCompletionRatio {
    if (exercises.isEmpty) return 0;
    return exercises.where((e) => e.isCompleted).length / exercises.length;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date.toIso8601String(),
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'isPlanned': isPlanned,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'durationMinutes': durationMinutes,
        'notes': notes,
        'templateId': templateId,
      };

  factory Workout.fromJson(Map<String, dynamic> json) => Workout(
        id: json['id'] as String,
        name: json['name'] as String,
        date: DateTime.parse(json['date'] as String),
        exercises: (json['exercises'] as List)
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        isPlanned: json['isPlanned'] as bool? ?? false,
        isCompleted: json['isCompleted'] as bool? ?? false,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        durationMinutes: json['durationMinutes'] as int?,
        notes: json['notes'] as String?,
        templateId: json['templateId'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Workout && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ---------------------------------------------------------------------------
// WorkoutTemplate — saved layout to reuse when planning
// ---------------------------------------------------------------------------
class WorkoutTemplate {
  final String id;
  final String name;
  final String? description;
  final List<WorkoutExercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<WorkoutExercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      WorkoutTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        exercises: exercises ?? this.exercises,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'exercises': exercises.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) =>
      WorkoutTemplate(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        exercises: (json['exercises'] as List)
            .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
