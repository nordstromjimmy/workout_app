import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
//import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/exercise.dart';
import '../../../presentation/providers/providers.dart';

// ── Emoji presets grouped by category ────────────────────────────────────────
const _emojiPresets = ['🏋️', '💪', '🏃', '🚴', '🧘'];

class AddExerciseScreen extends ConsumerStatefulWidget {
  final Exercise? exercise;

  const AddExerciseScreen({super.key, this.exercise});

  @override
  ConsumerState<AddExerciseScreen> createState() => _AddExerciseScreenState();
}

class _AddExerciseScreenState extends ConsumerState<AddExerciseScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();

  String _category = 'Styrka';
  final Set<String> _selectedMuscles = {};
  String? _iconEmoji;
  String? _imagePath;

  bool get _isCardio => _category == 'Kondition';
  bool get _isFlexibility => _category == 'Flexibilitet';
  bool get _isMeditation => _category == 'Meditation';
  bool get _isBodyweight => _category == 'Kropssvikt';
  bool get _isStrengthLike => !_isCardio && !_isFlexibility && !_isMeditation;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    if (ex != null) {
      _nameController.text = ex.name;
      _descController.text = ex.description ?? '';
      _category = ex.category;
      _selectedMuscles.addAll(ex.muscleGroups);
      _iconEmoji = ex.iconEmoji;
      _imagePath = ex.imagePath;
      if (ex.defaultSets != null) _setsController.text = '${ex.defaultSets}';
      if (ex.defaultReps != null) _repsController.text = '${ex.defaultReps}';
      if (ex.defaultWeightKg != null) {
        _weightController.text = _fmt(ex.defaultWeightKg!);
      }
      if (ex.defaultDurationSeconds != null) {
        _durationController.text = '${ex.defaultDurationSeconds}';
      }
      if (ex.defaultDistanceKm != null) {
        _distanceController.text = _fmt(ex.defaultDistanceKm!);
      }
    }
  }

  String _fmt(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  void dispose() {
    for (final c in [
      _nameController,
      _descController,
      _setsController,
      _repsController,
      _weightController,
      _durationController,
      _distanceController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Image picker ────────────────────────────────────────────────────────

  /*   Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (file != null) setState(() => _imagePath = file.path);
  } */

  /*   void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  'Remove photo',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _imagePath = null);
                },
              ),
          ],
        ),
      ),
    );
  } */

  // ── Emoji picker ────────────────────────────────────────────────────────

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Välj ikon',
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _emojiPresets.map((e) {
                  final selected = _iconEmoji == e;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _iconEmoji = e);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: selected
                            ? Theme.of(ctx).colorScheme.primaryContainer
                            : Theme.of(ctx).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? Border.all(
                                color: Theme.of(ctx).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              if (_iconEmoji != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _iconEmoji = null);
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Ta bort ikon'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ange ett namn för övningen')),
      );
      return;
    }

    final exercise = Exercise(
      id: widget.exercise?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      muscleGroups: _selectedMuscles.toList(),
      category: _category,
      isCustom: true,
      createdAt: widget.exercise?.createdAt ?? DateTime.now(),
      iconEmoji: _iconEmoji,
      imagePath: _imagePath,
      defaultSets: int.tryParse(_setsController.text),
      defaultReps: int.tryParse(_repsController.text),
      defaultWeightKg: double.tryParse(_weightController.text),
      defaultDurationSeconds: int.tryParse(_durationController.text),
      defaultDistanceKm: double.tryParse(_distanceController.text),
    );

    await ref.read(exerciseNotifierProvider.notifier).save(exercise);
    if (mounted) context.pop();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.exercise != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Redigera övning' : 'Ny övning')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Icon + Image row ────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji icon button
              _IconSelector(
                emoji: _iconEmoji,
                category: _category,
                onTap: _showEmojiPicker,
              ),
              const SizedBox(width: 16),
              // Image picker
              /*               Expanded(
                child: _ImageSelector(
                  imagePath: _imagePath,
                  onTap: _showImageSourceSheet,
                ),
              ), */
            ],
          ),

          const SizedBox(height: 24),

          // ── Name ────────────────────────────────────────────────────────
          _SectionLabel('Namn på övning'),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: 'Bänkpress etc..'),
            textCapitalization: TextCapitalization.words,
            style: theme.textTheme.titleMedium,
          ),

          const SizedBox(height: 20),

          // ── Category ────────────────────────────────────────────────────
          _SectionLabel('Kategori'),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: AppConstants.exerciseCategories
                .map(
                  (c) => ChoiceChip(
                    label: Text(c),
                    showCheckmark: false,
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 20),

          // ── Muscle groups ────────────────────────────────────────────────
          _SectionLabel('Muskelgrupper'),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: AppConstants.muscleGroups
                .map(
                  (m) => FilterChip(
                    label: Text(m),
                    showCheckmark: false,
                    selected: _selectedMuscles.contains(m),
                    onSelected: (on) => setState(
                      () => on
                          ? _selectedMuscles.add(m)
                          : _selectedMuscles.remove(m),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 24),

          // ── Default values ───────────────────────────────────────────────
          Row(
            children: [
              _SectionLabelInline('Värden'),
              const SizedBox(width: 6),
              Tooltip(
                message:
                    'These pre-fill sets when you add this exercise to a workout.',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Sets (always shown)
                if (!_isCardio && !_isFlexibility && !_isMeditation)
                  _DefaultRow(
                    icon: Icons.layers_outlined,
                    label: 'Sets',
                    controller: _setsController,
                    hint: '3',
                    isInt: true,
                    suffix: 'sets',
                  ),

                if (_isStrengthLike) ...[
                  const Divider(height: 24),
                  _DefaultRow(
                    icon: Icons.repeat_rounded,
                    label: 'Reps',
                    controller: _repsController,
                    hint: '10',
                    isInt: true,
                    suffix: 'reps',
                  ),

                  if (!_isBodyweight) ...[
                    const Divider(height: 24),
                    _DefaultRow(
                      icon: Icons.fitness_center_rounded,
                      label: 'Vikt',
                      controller: _weightController,
                      hint: '0',
                      suffix: 'kg',
                    ),
                  ],
                ],

                if (_isCardio || _isFlexibility) ...[
                  _DefaultRow(
                    icon: Icons.timer_outlined,
                    label: 'Tid',
                    controller: _durationController,
                    hint: '60',
                    isInt: true,
                    suffix: 'sec',
                  ),
                ],

                if (_isMeditation) ...[
                  _DefaultRow(
                    icon: Icons.timer_outlined,
                    label: 'Tid',
                    controller: _durationController,
                    hint: '60',
                    isInt: true,
                    suffix: 'sec',
                  ),
                ],

                if (_isCardio) ...[
                  const Divider(height: 24),
                  _DefaultRow(
                    icon: Icons.straighten_rounded,
                    label: 'Längd',
                    controller: _distanceController,
                    hint: '0',
                    suffix: 'km',
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Description / notes ──────────────────────────────────────────
          _SectionLabel('Anteckningar'),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(hintText: 'Frivillig info..'),
            maxLines: 4,
          ),

          const SizedBox(height: 32),

          FilledButton(onPressed: _save, child: const Text('Spara övning')),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: const Text('Avbryt'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    ),
  );
}

class _SectionLabelInline extends StatelessWidget {
  final String text;
  const _SectionLabelInline(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
  );
}

class _IconSelector extends StatelessWidget {
  final String? emoji;
  final String category;
  final VoidCallback onTap;

  const _IconSelector({
    required this.emoji,
    required this.category,
    required this.onTap,
  });

  String get _fallback {
    switch (category) {
      case 'Cardio':
        return '🏃';
      case 'Bodyweight':
        return '🤸';
      case 'Flexibility':
        return '🧘';
      default:
        return '🏋️';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                emoji ?? _fallback,
                style: const TextStyle(fontSize: 36),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit,
                  size: 12,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* class _ImageSelector extends StatelessWidget {
  final String? imagePath;
  final VoidCallback onTap;

  const _ImageSelector({required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imagePath != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: hasImage ? null : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage
                ? Colors.transparent
                : theme.colorScheme.onSurface.withOpacity(0.1),
            style: hasImage ? BorderStyle.none : BorderStyle.solid,
          ),
          image: hasImage
              ? DecorationImage(
                  image: FileImage(File(imagePath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasImage
            ? Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Change photo',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 28,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add photo',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} */

class _DefaultRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final bool isInt;

  const _DefaultRow({
    required this.icon,
    required this.label,
    required this.controller,
    required this.hint,
    required this.suffix,
    this.isInt = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.numberWithOptions(
              decimal: !isInt,
              signed: false,
            ),
            decoration: InputDecoration(
              hintText: hint,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            suffix,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
        ),
      ],
    );
  }
}
