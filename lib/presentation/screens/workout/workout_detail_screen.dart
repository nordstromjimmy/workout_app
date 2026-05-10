import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/workout.dart';
import '../../../presentation/providers/providers.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  int _restSeconds = 0;
  Timer? _restTimer;
  bool _timerRunning = false;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() {
      _restSeconds = seconds;
      _timerRunning = true;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restSeconds <= 0) {
        t.cancel();
        setState(() => _timerRunning = false);
      } else {
        setState(() => _restSeconds--);
      }
    });
  }

  Future<void> _completeWorkout(Workout workout) async {
    final completedCount = workout.exercises.where((e) => e.isCompleted).length;
    final totalCount = workout.exercises.length;

    // If there are exercises and not all are done, ask first
    if (totalCount > 0 && completedCount < totalCount) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Inte alla övningar klara'),
          content: Text(
            '$completedCount av $totalCount övningar är markerade som klara. '
            'Vill du ändå avsluta träningen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Fortsätt träna'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Avsluta ändå'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final durationMinutes = _stopwatch.elapsed.inMinutes;
    _stopwatch.stop();
    await ref
        .read(workoutNotifierProvider.notifier)
        .complete(
          workout.id,
          durationMinutes: durationMinutes > 0 ? durationMinutes : null,
        );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Träning avklarad! 💪')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allWorkouts = ref.watch(workoutNotifierProvider);
    final workout = allWorkouts.firstWhere(
      (w) => w.id == widget.workoutId,
      orElse: () => throw Exception('Workout not found'),
    );
    final theme = Theme.of(context);

    final completedCount = workout.exercises.where((e) => e.isCompleted).length;
    final totalCount = workout.exercises.length;
    final allDone = totalCount == 0 || completedCount == totalCount;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _WorkoutHeader(
              workout: workout,
              elapsed: _stopwatch.elapsed,
              onBack: () => context.pop(),
              onComplete: workout.isCompleted
                  ? null
                  : () => _completeWorkout(workout),
            ),

            if (_timerRunning)
              _RestTimerBar(
                seconds: _restSeconds,
                onSkip: () {
                  _restTimer?.cancel();
                  setState(() => _timerRunning = false);
                },
              ),

            Expanded(
              child: workout.exercises.isEmpty
                  ? Center(
                      child: Text(
                        'Inga övningar tillagda',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: workout.exercises.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final exercise = workout.exercises[index];
                        return _ExerciseBlock(
                          exercise: exercise,
                          isWorkoutComplete: workout.isCompleted,
                          onToggleSet: (setId) async {
                            await ref
                                .read(workoutNotifierProvider.notifier)
                                .toggleSet(workout.id, exercise.id, setId);
                            _startRestTimer(90);
                          },
                          onToggleExercise: () async {
                            await ref
                                .read(workoutNotifierProvider.notifier)
                                .toggleExercise(workout.id, exercise.id);
                          },
                        );
                      },
                    ),
            ),

            // ── Complete button ───────────────────────────────────────────
            if (!workout.isCompleted)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Progress hint shown when not all exercises are done
                    if (totalCount > 0 && !allDone)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          '$completedCount av $totalCount övningar klara',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: () => _completeWorkout(workout),
                      // Slightly muted when not all done, but always tappable
                      style: allDone
                          ? null
                          : FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.6),
                            ),
                      icon: Icon(
                        allDone ? Icons.check_rounded : Icons.stop_rounded,
                      ),
                      label: Text(
                        allDone
                            ? 'Markera träningen som klar'
                            : 'Avsluta träning tidigt',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _WorkoutHeader extends StatelessWidget {
  final Workout workout;
  final Duration elapsed;
  final VoidCallback onBack;
  final VoidCallback? onComplete;

  const _WorkoutHeader({
    required this.workout,
    required this.elapsed,
    required this.onBack,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = workout.isCompleted
        ? AppTheme.completedColor
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(color: theme.colorScheme.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
              Expanded(
                child: Text(
                  workout.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (workout.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.completedColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.completedColor,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Färdig',
                        style: TextStyle(
                          color: AppTheme.completedColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 6),
                Text(
                  AppDateUtils.formatDayFull(workout.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
                if (workout.durationMinutes != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.timer_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${workout.durationMinutes}m',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  '${workout.exercises.where((e) => e.isCompleted).length}/${workout.exercises.length} övningar',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RestTimerBar extends StatelessWidget {
  final int seconds;
  final VoidCallback onSkip;

  const _RestTimerBar({required this.seconds, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.timer, color: theme.colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            'Vila: ${seconds}s',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onSkip, child: const Text('Hoppa över')),
        ],
      ),
    );
  }
}

class _ExerciseBlock extends StatelessWidget {
  final WorkoutExercise exercise;
  final bool isWorkoutComplete;
  final void Function(String setId) onToggleSet;
  final VoidCallback onToggleExercise;

  const _ExerciseBlock({
    required this.exercise,
    required this.isWorkoutComplete,
    required this.onToggleSet,
    required this.onToggleExercise,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedSets = exercise.sets.where((s) => s.isCompleted).length;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: exercise.isCompleted
            ? Border.all(color: AppTheme.completedColor.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggleExercise,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.exerciseName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: exercise.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        Text(
                          '$completedSets/${exercise.sets.length} sets',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: exercise.isCompleted,
                    onChanged: isWorkoutComplete
                        ? null
                        : (_) => onToggleExercise(),
                    activeColor: AppTheme.completedColor,
                    shape: const CircleBorder(),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          ...exercise.sets.asMap().entries.map((entry) {
            final i = entry.key;
            final set = entry.value;
            return _SetRow(
              setNumber: i + 1,
              set: set,
              isWorkoutComplete: isWorkoutComplete,
              onToggle: () => onToggleSet(set.id),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  final int setNumber;
  final ExerciseSet set;
  final bool isWorkoutComplete;
  final VoidCallback onToggle;

  const _SetRow({
    required this.setNumber,
    required this.set,
    required this.isWorkoutComplete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = set.isCompleted
        ? AppTheme.completedColor
        : theme.colorScheme.onSurface.withValues(alpha: 0.7);

    return InkWell(
      onTap: isWorkoutComplete ? null : onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: set.isCompleted
                    ? AppTheme.completedColor.withValues(alpha: 0.15)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: set.isCompleted
                    ? const Icon(
                        Icons.check,
                        size: 14,
                        color: AppTheme.completedColor,
                      )
                    : Text(
                        '$setNumber',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              set.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                decoration: set.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
