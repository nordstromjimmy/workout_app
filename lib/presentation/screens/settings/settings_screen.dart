import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //final weightUnit = ref.watch(weightUnitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inställningar')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Preferences ───────────────────────────────────────────────
          /*           _SectionLabel('Preferences'),
          _SettingCard(
            children: [
              ListTile(
                title: const Text('Weight unit'),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'kg', label: Text('kg')),
                    ButtonSegment(value: 'lbs', label: Text('lbs')),
                  ],
                  selected: {weightUnit},
                  onSelectionChanged: (s) async {
                    final unit = s.first;
                    ref.read(weightUnitProvider.notifier).state = unit;
                    await ref
                        .read(storageServiceProvider)
                        .setSetting('weight_unit', unit);
                  },
                ),
              ),
            ],
          ), */
          const SizedBox(height: 24),

          // ── Data ─────────────────────────────────────────────────────
          _SectionLabel('Data'),
          _SettingCard(
            children: [
              ListTile(
                leading: const Icon(Icons.upload_rounded),
                title: const Text('Export data'),
                subtitle: const Text('Share a JSON backup of all your data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _export(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Import data'),
                subtitle: const Text('Restore from a JSON backup'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _import(context, ref),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── About ─────────────────────────────────────────────────────
          _SectionLabel('Om'),
          _SettingCard(
            children: [
              const ListTile(
                title: Text('Workout App'),
                subtitle: Text('v1.0.0 · Alla data sparas lokalt'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(exportServiceProvider).exportToJson();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import backup?'),
        content: const Text(
          'This will replace ALL current data (exercises, workouts, templates) '
          'with the imported backup. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Import',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final success = await ref.read(exportServiceProvider).importFromJson();
      if (success) {
        // Refresh all providers
        ref.invalidate(exerciseNotifierProvider);
        ref.invalidate(workoutNotifierProvider);
        ref.invalidate(templateNotifierProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data imported successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}
