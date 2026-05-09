import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout.dart';
import '../../../presentation/providers/providers.dart';

class AddWorkoutScreen extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final WorkoutTemplate? template;

  const AddWorkoutScreen({super.key, this.initialDate, this.template});

  @override
  ConsumerState<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends ConsumerState<AddWorkoutScreen> {
  final _uuid = const Uuid();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  bool _isPlanned = true;
  List<WorkoutExercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? AppDateUtils.today();
    final tmpl = widget.template;
    if (tmpl != null) {
      _nameController.text = tmpl.name;
      _exercises = tmpl.exercises
          .map(
            (e) => WorkoutExercise(
              id: _uuid.v4(),
              exerciseId: e.exerciseId,
              exerciseName: e.exerciseName,
              exerciseCategory: e.exerciseCategory,
              sets: e.sets
                  .map(
                    (s) => ExerciseSet(
                      id: _uuid.v4(),
                      reps: s.reps,
                      weightKg: s.weightKg,
                      durationSeconds: s.durationSeconds,
                      distanceKm: s.distanceKm,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //final templates = ref.watch(templateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template != null ? 'Ny träning' : 'Planera träning'),
        /*         actions: [
          // Template picker
          if (templates.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bookmarks_outlined),
              tooltip: 'Use template',
              onPressed: () => _showTemplatePicker(templates),
            ),
          // Save as template
          IconButton(
            icon: const Icon(Icons.bookmark_add_outlined),
            tooltip: 'Save as template',
            onPressed: _saveAsTemplate,
          ),
        ], */
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Träning',
                hintText: '',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            // Date + planned toggle
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    date: _selectedDate,
                    onChanged: (d) => setState(() => _selectedDate = d),
                  ),
                ),
                const SizedBox(width: 12),
                FilterChip(
                  label: const Text('Planerad'),
                  selected: _isPlanned,
                  onSelected: (v) => setState(() => _isPlanned = v),
                  selectedColor: theme.colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Exercises header
            Row(
              children: [
                Text(
                  'Övningar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Lägg till'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_exercises.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Klicka på "Lägg till" för att lägga till övningar',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _exercises.removeAt(oldIndex);
                    _exercises.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final ex = _exercises[index];
                  return _ExerciseEditTile(
                    key: ValueKey(ex.id),
                    exercise: ex,
                    onRemove: () => setState(() => _exercises.removeAt(index)),
                    onSetsChanged: (sets) => setState(() {
                      _exercises[index] = ex.copyWith(sets: sets);
                    }),
                  );
                },
              ),

            const SizedBox(height: 24),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Anteckingar (frivilligt)',
                hintText: '',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            FilledButton(onPressed: _save, child: const Text('Spara träning')),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Avbryt'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExercise() async {
    final exercises = ref.read(exerciseNotifierProvider);
    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ExercisePickerSheet(exercises: exercises),
    );
    if (selected == null) return;

    // Default sets based on category
    final sets = _defaultSets(selected);
    setState(() {
      _exercises.add(
        WorkoutExercise(
          id: const Uuid().v4(),
          exerciseId: selected.id,
          exerciseName: selected.name,
          exerciseCategory: selected.category,
          sets: sets,
        ),
      );
    });
  }

  List<ExerciseSet> _defaultSets(Exercise e) {
    final uuid = const Uuid();
    final count =
        e.defaultSets ??
        (e.category == 'Cardio' || e.category == 'Flexibility' ? 1 : 3);

    if (e.category == 'Cardio') {
      return List.generate(
        count,
        (_) => ExerciseSet(
          id: uuid.v4(),
          durationSeconds: e.defaultDurationSeconds ?? 1800,
          distanceKm: e.defaultDistanceKm,
        ),
      );
    }
    if (e.category == 'Flexibility') {
      return List.generate(
        count,
        (_) => ExerciseSet(
          id: uuid.v4(),
          durationSeconds: e.defaultDurationSeconds ?? 60,
        ),
      );
    }
    // Strength / Bodyweight
    return List.generate(
      count,
      (_) => ExerciseSet(
        id: uuid.v4(),
        reps: e.defaultReps ?? 10,
        weightKg: e.category == 'Bodyweight' ? null : (e.defaultWeightKg ?? 0),
      ),
    );
  }

  /*   void _showTemplatePicker(List<WorkoutTemplate> templates) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choose Template',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...templates.map(
            (t) => ListTile(
              title: Text(t.name),
              subtitle: Text('${t.exercises.length} exercises'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _nameController.text = t.name;
                  _exercises = t.exercises
                      .map((e) => e.copyWith(id: _uuid.v4()))
                      .toList();
                });
              },
            ),
          ),
        ],
      ),
    );
  } */

  /*   Future<void> _saveAsTemplate() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add a name first')));
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }
    final template = WorkoutTemplate(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      exercises: _exercises,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await ref.read(templateNotifierProvider.notifier).save(template);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${template.name}" saved as template')),
      );
    }
  }
 */
  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ange ett namn för träningen')),
      );
      return;
    }
    final workout = Workout(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      date: _selectedDate,
      exercises: _exercises,
      isPlanned: _isPlanned,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await ref.read(workoutNotifierProvider.notifier).save(workout);
    if (mounted) context.pop();
  }
}

// ── Helper widgets ───────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final DateTime date;
  final void Function(DateTime) onChanged;

  const _DatePickerField({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E2E3E)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              AppDateUtils.formatDayFull(date),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  final List<Exercise> exercises;

  const _ExercisePickerSheet({required this.exercises});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _search = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.exercises.where((e) {
      final matchSearch =
          _search.isEmpty ||
          e.name.toLowerCase().contains(_search.toLowerCase());
      final matchCat = _category == null || e.category == _category;
      return matchSearch && matchCat;
    }).toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, sc) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Sök övningar..',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            // Category filter chips
            /* SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                  const SizedBox(width: 8),
                  ...['Strength', 'Bodyweight', 'Cardio', 'Flexibility'].map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(
                          () => _category = _category == c ? null : c,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ), */
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: sc,
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final ex = filtered[i];
                  return ListTile(
                    title: Text(ex.name),
                    subtitle: Text(ex.muscleGroups.take(3).join(', ')),
                    trailing: Text(
                      ex.category,
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, ex),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseEditTile extends StatelessWidget {
  final WorkoutExercise exercise;
  final VoidCallback onRemove;
  final void Function(List<ExerciseSet>) onSetsChanged;

  const _ExerciseEditTile({
    super.key,
    required this.exercise,
    required this.onRemove,
    required this.onSetsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              exercise.exerciseName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${exercise.sets.length} sets'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () {
                    final last = exercise.sets.lastOrNull;
                    final newSet = ExerciseSet(
                      id: const Uuid().v4(),
                      reps: last?.reps,
                      weightKg: last?.weightKg,
                      durationSeconds: last?.durationSeconds,
                      distanceKm: last?.distanceKm,
                    );
                    onSetsChanged([...exercise.sets, newSet]);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onRemove,
                  color: theme.colorScheme.error,
                ),
                const Icon(Icons.drag_handle, size: 20),
              ],
            ),
          ),
          ...exercise.sets.asMap().entries.map((entry) {
            final i = entry.key;
            final set = entry.value;
            return _SetEditRow(
              setNumber: i + 1,
              set: set,
              category: exercise.exerciseCategory,
              onChanged: (updated) {
                final sets = [...exercise.sets];
                sets[i] = updated;
                onSetsChanged(sets);
              },
              onRemove: exercise.sets.length > 1
                  ? () {
                      final sets = [...exercise.sets]..removeAt(i);
                      onSetsChanged(sets);
                    }
                  : null,
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SetEditRow extends StatelessWidget {
  final int setNumber;
  final ExerciseSet set;
  final String category;
  final void Function(ExerciseSet) onChanged;
  final VoidCallback? onRemove;

  const _SetEditRow({
    required this.setNumber,
    required this.set,
    required this.category,
    required this.onChanged,
    this.onRemove,
  });

  bool get isCardio => category == 'Kondition';
  bool get isFlexibility => category == 'Flexibilitet';
  bool get isBodyweight => category == 'Kropssvikt';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$setNumber',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!isCardio && !isFlexibility) ...[
            Expanded(
              child: _CompactNumberField(
                label: 'Reps',
                value: set.reps?.toDouble(),
                onChanged: (v) => onChanged(set.copyWith(reps: v?.toInt())),
                isInt: true,
              ),
            ),
            if (!isBodyweight) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _CompactNumberField(
                  label: 'kg',
                  value: set.weightKg,
                  onChanged: (v) => onChanged(set.copyWith(weightKg: v)),
                ),
              ),
            ],
          ],
          if (isCardio || isFlexibility) ...[
            Expanded(
              child: _CompactNumberField(
                label: 'Secs',
                value: set.durationSeconds?.toDouble(),
                onChanged: (v) =>
                    onChanged(set.copyWith(durationSeconds: v?.toInt())),
                isInt: true,
              ),
            ),
            if (isCardio) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _CompactNumberField(
                  label: 'km',
                  value: set.distanceKm,
                  onChanged: (v) => onChanged(set.copyWith(distanceKm: v)),
                ),
              ),
            ],
          ],
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                size: 18,
                color: theme.colorScheme.error.withOpacity(0.6),
              ),
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactNumberField extends StatelessWidget {
  final String label;
  final double? value;
  final void Function(double?) onChanged;
  final bool isInt;

  const _CompactNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isInt = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value == null
          ? ''
          : isInt
          ? value!.toInt().toString()
          : value!.toStringAsFixed(value! % 1 == 0 ? 0 : 1),
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) => onChanged(double.tryParse(v)),
      style: const TextStyle(fontSize: 14),
    );
  }
}
