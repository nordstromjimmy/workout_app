import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/week_summary.dart';

class WeekProgressHeader extends StatelessWidget {
  final WeekSummary summary;

  const WeekProgressHeader({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = summary.planCompletionRatio.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            runSpacing: 6,
            children: [
              _StatChip(
                icon: Icons.check_circle_outline,
                value: summary.totalCompleted,
                label: 'Färdiga',
                color: AppTheme.completedColor,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.calendar_today_outlined,
                value: summary.totalPlanned,
                label: 'Planerade',
                color: AppTheme.plannedColor,
              ),
              const SizedBox(width: 8),
              if (summary.totalMissed > 0)
                _StatChip(
                  icon: Icons.cancel_outlined,
                  value: summary.totalMissed,
                  label: 'Missade',
                  color: AppTheme.missedColor,
                ),
              if (summary.totalAdhoc > 0) ...[
                if (summary.totalMissed > 0) const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.add_circle_outline,
                  value: summary.totalAdhoc,
                  label: 'Extra',
                  color: AppTheme.adhocColor,
                ),
              ],
            ],
          ),
          if (summary.totalPlanned > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.1,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _progressColor(ratio),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              summary.totalPlanned == 0
                  ? 'Ingen träning planerad'
                  : '${(ratio * 100).round()}% av planerad träning färdig',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _progressColor(double ratio) {
    if (ratio >= 1.0) return AppTheme.completedColor;
    if (ratio >= 0.6) return AppTheme.plannedColor;
    if (ratio >= 0.3) return Colors.orange;
    return AppTheme.missedColor;
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
