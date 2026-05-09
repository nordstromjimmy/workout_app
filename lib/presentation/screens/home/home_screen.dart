import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_utils.dart';
import '../../../presentation/providers/providers.dart';
import '../../widgets/day_row.dart';
import '../../widgets/week_progress_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(currentWeekStartProvider);
    final weekWorkouts = ref.watch(currentWeekWorkoutsProvider);
    final summary = ref.watch(currentWeekSummaryProvider);
    final days = AppDateUtils.weekDays(weekStart);
    final isCurrentWeek = AppDateUtils.isSameDay(
      weekStart,
      AppDateUtils.startOfWeek(DateTime.now()),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCurrentWeek
                              ? 'Denna vecka'
                              : 'Vecka ${AppDateUtils.weekNumber(weekStart)}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppDateUtils.formatWeekRange(weekStart),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                        ),
                      ],
                    ),
                  ),
                  // Week navigation
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () =>
                        ref.read(currentWeekStartProvider.notifier).state =
                            weekStart.subtract(const Duration(days: 7)),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: isCurrentWeek
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.2)
                          : null,
                    ),
                    onPressed: isCurrentWeek
                        ? null
                        : () =>
                              ref
                                  .read(currentWeekStartProvider.notifier)
                                  .state = weekStart.add(
                                const Duration(days: 7),
                              ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Week progress header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: WeekProgressHeader(summary: summary),
            ),

            const SizedBox(height: 16),

            // ── Day rows ─────────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final dayWorkouts = weekWorkouts
                      .where((w) => AppDateUtils.isSameDay(w.date, day))
                      .toList();
                  return DayRow(
                    day: day,
                    workouts: dayWorkouts,
                    onAddWorkout: () =>
                        context.push('/workout/new', extra: {'date': day}),
                    onTapWorkout: (w) => context.push('/workout/${w.id}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── FABs ──────────────────────────────────────────────────────────────
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // View summary button
          if (weekWorkouts.isNotEmpty) ...[
            FloatingActionButton.extended(
              heroTag: 'summary',
              onPressed: () => context.push('/week-summary', extra: weekStart),
              icon: const Icon(Icons.bar_chart_rounded),
              label: const Text('Veckosammanfattning'),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(
                context,
              ).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 12),
          ],
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => context.push('/workout/new'),
            child: const Icon(Icons.add),
          ),
        ],
      ),

      // ── Bottom nav ────────────────────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Color(0xFF6C63FF))),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.calendar_today_rounded,
                label: 'Vecka',
                isSelected: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.fitness_center_rounded,
                label: 'Övningar',
                isSelected: false,
                onTap: () => context.push('/exercises'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
