import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/workout.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onTap;

  const WorkoutCard({super.key, required this.workout, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = workout.status;
    final statusColor = _statusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),

              // Name + exercises
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (workout.exercises.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        workout.exercises
                            .map((e) => e.exerciseName)
                            .take(3)
                            .join(', ') +
                            (workout.exercises.length > 3
                                ? ' +${workout.exercises.length - 3}'
                                : ''),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Duration if completed
              if (workout.durationMinutes != null)
                Text(
                  '${workout.durationMinutes}m',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),

              const SizedBox(width: 8),

              // Status icon
              _StatusIcon(status: status),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(WorkoutStatus status) {
    switch (status) {
      case WorkoutStatus.completed:
        return AppTheme.completedColor;
      case WorkoutStatus.missed:
        return AppTheme.missedColor;
      case WorkoutStatus.adhoc:
        return AppTheme.adhocColor;
      case WorkoutStatus.planned:
        return AppTheme.plannedColor;
    }
  }
}

class _StatusIcon extends StatelessWidget {
  final WorkoutStatus status;

  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case WorkoutStatus.completed:
        return const Icon(Icons.check_circle_rounded,
            color: AppTheme.completedColor, size: 20);
      case WorkoutStatus.missed:
        return const Icon(Icons.cancel_rounded,
            color: AppTheme.missedColor, size: 20);
      case WorkoutStatus.adhoc:
        return const Icon(Icons.add_circle_rounded,
            color: AppTheme.adhocColor, size: 20);
      case WorkoutStatus.planned:
        return const Icon(Icons.radio_button_unchecked_rounded,
            color: AppTheme.plannedColor, size: 20);
    }
  }
}
