import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/exercise.dart';
import '../../../presentation/providers/providers.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  /// When true the screen is embedded inside a tab — no Scaffold/AppBar.
  final bool embedded;

  const ExerciseLibraryScreen({super.key, this.embedded = false});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _search = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exerciseNotifierProvider);
    final theme = Theme.of(context);

    final filtered = allExercises.where((e) {
      final matchSearch =
          _search.isEmpty ||
          e.name.toLowerCase().contains(_search.toLowerCase()) ||
          e.muscleGroups.any(
            (m) => m.toLowerCase().contains(_search.toLowerCase()),
          );
      final matchCat = _category == null || e.category == _category;
      return matchSearch && matchCat;
    }).toList();

    // Group by category
    final Map<String, List<Exercise>> grouped = {};
    for (final e in filtered) {
      grouped.putIfAbsent(e.category, () => []).add(e);
    }
    final sortedCats = grouped.keys.toList()..sort();

    final body = Column(
      children: [
        // ── Search ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Sök övning..',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        const SizedBox(height: 8),

        // ── List ────────────────────────────────────────────────────────
        Expanded(
          child: allExercises.isEmpty
              ? _EmptyState(onAdd: () => context.push('/exercises/new'))
              : filtered.isEmpty
              ? Center(
                  child: Text(
                    'Inga övningar hittades',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: sortedCats.length,
                  itemBuilder: (context, catIndex) {
                    final cat = sortedCats[catIndex];
                    final exercises = grouped[cat]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
                          child: Text(
                            cat,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: exercises.asMap().entries.map((entry) {
                              final i = entry.key;
                              final ex = entry.value;
                              return Column(
                                children: [
                                  if (i > 0)
                                    const Divider(height: 1, indent: 72),
                                  Slidable(
                                    key: ValueKey(ex.id),
                                    endActionPane: ActionPane(
                                      motion: const DrawerMotion(),
                                      children: [
                                        SlidableAction(
                                          onPressed: (_) => _editExercise(ex),
                                          backgroundColor:
                                              theme.colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          icon: Icons.edit,
                                          label: 'Redigera',
                                        ),
                                        SlidableAction(
                                          onPressed: (_) => _deleteExercise(ex),
                                          backgroundColor:
                                              theme.colorScheme.error,
                                          foregroundColor: Colors.white,
                                          icon: Icons.delete,
                                          label: 'Ta bort',
                                        ),
                                      ],
                                    ),
                                    child: _ExerciseTile(
                                      exercise: ex,
                                      onTap: () => _editExercise(ex),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );

    // When embedded in a tab, skip the Scaffold — home_screen provides it
    if (widget.embedded) return body;

    return Scaffold(
      appBar: AppBar(title: const Text('Övningar')),
      body: body,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exercises/new'),
        icon: const Icon(Icons.add),
        label: const Text('Ny övning'),
      ),
    );
  }

  void _editExercise(Exercise exercise) {
    context.push('/exercises/${exercise.id}/edit', extra: exercise);
  }

  Future<void> _deleteExercise(Exercise exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ta bort övning?'),
        content: Text(
          '"${exercise.name}" tas bort. Befintliga träningspass påverkas inte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Ta bort',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(exerciseNotifierProvider.notifier).delete(exercise.id);
    }
  }
}

// ── Exercise tile ─────────────────────────────────────────────────────────────

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;

  const _ExerciseTile({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: _ExerciseAvatar(exercise: exercise),
      title: Text(
        exercise.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exercise.muscleGroups.isNotEmpty)
            Text(
              exercise.muscleGroups.take(3).join(', '),
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          if (_hasDefaults(exercise)) ...[
            const SizedBox(height: 3),
            _DefaultsPill(exercise: exercise),
          ],
        ],
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
    );
  }

  bool _hasDefaults(Exercise e) =>
      e.defaultSets != null ||
      e.defaultReps != null ||
      e.defaultWeightKg != null ||
      e.defaultDurationSeconds != null;
}

class _ExerciseAvatar extends StatelessWidget {
  final Exercise exercise;

  const _ExerciseAvatar({required this.exercise});

  @override
  Widget build(BuildContext context) {
    if (exercise.imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(exercise.imagePath!),
          width: 52,
          height: 52,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _EmojiAvatar(exercise: exercise),
        ),
      );
    }

    return _EmojiAvatar(exercise: exercise);
  }
}

class _EmojiAvatar extends StatelessWidget {
  final Exercise exercise;
  const _EmojiAvatar({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(exercise.displayIcon, style: const TextStyle(fontSize: 26)),
      ),
    );
  }
}

class _DefaultsPill extends StatelessWidget {
  final Exercise exercise;
  const _DefaultsPill({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (exercise.defaultSets != null) parts.add('${exercise.defaultSets} sets');
    if (exercise.defaultReps != null) parts.add('${exercise.defaultReps} reps');
    if (exercise.defaultWeightKg != null) {
      final w = exercise.defaultWeightKg!;
      parts.add('${w % 1 == 0 ? w.toInt() : w} kg');
    }
    if (exercise.defaultDurationSeconds != null) {
      final s = exercise.defaultDurationSeconds!;
      parts.add(s >= 60 ? '${s ~/ 60}m' : '${s}s');
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(
          Icons.tune,
          size: 11,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 3),
        Text(
          parts.join(' · '),
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💪', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 20),
            Text(
              'Inga övningar tillagda',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Lägg till dina egna övningar med namn, muskelgrupp, set, repetitioner, vikt — exakt hur du tränar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Lägg till övning'),
            ),
          ],
        ),
      ),
    );
  }
}
