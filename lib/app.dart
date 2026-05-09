import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';

class WorkoutTrackerApp extends ConsumerWidget {
  const WorkoutTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Workout Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark, // default dark; could be a settings toggle
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
