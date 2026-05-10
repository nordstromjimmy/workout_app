import 'package:flutter/material.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/workout.dart';
import 'workout_card.dart';

class DayRow extends StatelessWidget {
  final DateTime day;
  final List<Workout> workouts;
  final VoidCallback onAddWorkout;
  final void Function(Workout) onTapWorkout;

  const DayRow({
    super.key,
    required this.day,
    required this.workouts,
    required this.onAddWorkout,
    required this.onTapWorkout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = AppDateUtils.isToday(day);
    final isPast = AppDateUtils.isPast(day) && !isToday;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(
                color: theme.colorScheme.primary.withOpacity(0.5),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Day header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                // Day label
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isToday
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: !isToday
                        ? Border.all(
                            color: theme.colorScheme.onSurface.withOpacity(0.1),
                          )
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppDateUtils.formatDayShort(day).split(' ')[0],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isToday
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface.withOpacity(
                                    isPast ? 0.4 : 0.7,
                                  ),
                          ),
                        ),
                        Text(
                          AppDateUtils.formatDayShort(day).split(' ')[1],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface.withOpacity(
                                    isPast ? 0.4 : 1.0,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Workout count or rest label
                if (workouts.isEmpty)
                  Text(
                    'Vilodag',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.35),
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Text(
                    '${workouts.length} träning${workouts.length > 1 ? 'ar' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                const Spacer(),
                // Add workout button
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: onAddWorkout,
                  color: theme.colorScheme.primary,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // ── Workout cards ──────────────────────────────────────────────
          if (workouts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: workouts
                    .map(
                      (w) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: WorkoutCard(
                          workout: w,
                          onTap: () => onTapWorkout(w),
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}
