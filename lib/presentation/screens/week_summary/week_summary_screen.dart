import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/week_summary.dart';
import '../../../data/models/workout.dart';
import '../../../presentation/providers/providers.dart';

class WeekSummaryScreen extends ConsumerWidget {
  final DateTime? weekStart;

  const WeekSummaryScreen({super.key, this.weekStart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentWeek = ref.watch(currentWeekStartProvider);
    final targetWeek = weekStart ?? currentWeek;
    final repo = ref.watch(workoutRepositoryProvider);
    final summary = repo.summaryForWeek(targetWeek);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vecka ${AppDateUtils.weekNumber(targetWeek)} översikt'),
            Text(
              AppDateUtils.formatWeekRange(targetWeek),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Grade card ────────────────────────────────────────────────
          _GradeCard(summary: summary),
          const SizedBox(height: 20),

          // ── Stats row ─────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: summary.totalCompleted,
                  label: 'Färdiga',
                  color: AppTheme.completedColor,
                  icon: Icons.check_circle_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: summary.totalPlanned,
                  label: 'Planerade',
                  color: AppTheme.plannedColor,
                  icon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: summary.totalMissed,
                  label: 'Missade',
                  color: AppTheme.missedColor,
                  icon: Icons.cancel_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Planned workouts breakdown ─────────────────────────────────
          if (summary.planned.isNotEmpty) ...[
            _SectionHeader('Planerade träningar'),
            const SizedBox(height: 8),
            ...summary.planned.map((w) => _WorkoutSummaryTile(workout: w)),
            const SizedBox(height: 20),
          ],

          // ── Ad-hoc workouts ────────────────────────────────────────────
          if (summary.adhoc.isNotEmpty) ...[
            _SectionHeader('Extra träningar'),
            const SizedBox(height: 8),
            ...summary.adhoc.map((w) => _WorkoutSummaryTile(workout: w)),
            const SizedBox(height: 20),
          ],

          // ── Weekly total ───────────────────────────────────────────────
          _TotalMinutesCard(workouts: [...summary.completed, ...summary.adhoc]),
          const SizedBox(height: 20),

          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Tillbaka'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _GradeCard extends StatelessWidget {
  final WeekSummary summary;

  const _GradeCard({required this.summary});

  Color _gradeColor(WeekGrade grade) {
    switch (grade) {
      case WeekGrade.exceeded:
      case WeekGrade.perfect:
        return AppTheme.completedColor;
      case WeekGrade.good:
        return AppTheme.plannedColor;
      case WeekGrade.fair:
        return Colors.orange;
      case WeekGrade.poor:
        return AppTheme.missedColor;
      case WeekGrade.unplanned:
        return AppTheme.adhocColor;
      case WeekGrade.empty:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _gradeColor(summary.grade);
    final ratio = summary.planCompletionRatio.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            summary.gradeSummary,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          if (summary.totalPlanned > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${summary.totalCompleted} av ${summary.totalPlanned} planerade träningar färdiga',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            '$value',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
    );
  }
}

class _WorkoutSummaryTile extends StatelessWidget {
  final Workout workout;

  const _WorkoutSummaryTile({required this.workout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = workout.status;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case WorkoutStatus.completed:
        statusColor = AppTheme.completedColor;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'Färdig';
        break;
      case WorkoutStatus.missed:
        statusColor = AppTheme.missedColor;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'Missad';
        break;
      case WorkoutStatus.adhoc:
        statusColor = AppTheme.adhocColor;
        statusIcon = Icons.add_circle_rounded;
        statusLabel = 'Extra';
        break;
      case WorkoutStatus.planned:
        statusColor = AppTheme.plannedColor;
        statusIcon = Icons.schedule_rounded;
        statusLabel = 'Kommande';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  AppDateUtils.formatDayFull(workout.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (workout.durationMinutes != null)
                Text(
                  '${workout.durationMinutes}m',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalMinutesCard extends StatelessWidget {
  final List<Workout> workouts;

  const _TotalMinutesCard({required this.workouts});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalMinutes = workouts.fold(
      0,
      (sum, w) => sum + (w.durationMinutes ?? 0),
    );
    if (totalMinutes == 0) return const SizedBox.shrink();

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final label = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, size: 20),
          const SizedBox(width: 10),
          const Text('Träningstid denna vecka'),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
