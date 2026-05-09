import 'package:go_router/go_router.dart';
import 'data/models/exercise.dart';
import 'data/models/workout.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/workout/workout_detail_screen.dart';
import 'presentation/screens/workout/add_workout_screen.dart';
import 'presentation/screens/exercise/exercise_library_screen.dart';
import 'presentation/screens/exercise/add_exercise_screen.dart';
import 'presentation/screens/week_summary/week_summary_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => const HomeScreen()),
    GoRoute(
      path: '/workout/new',
      builder: (ctx, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final date = extra?['date'] as DateTime?;
        final template = extra?['template'] as WorkoutTemplate?;
        return AddWorkoutScreen(initialDate: date, template: template);
      },
    ),
    GoRoute(
      path: '/workout/:id',
      builder: (ctx, state) {
        final workoutId = state.pathParameters['id']!;
        return WorkoutDetailScreen(workoutId: workoutId);
      },
    ),
    GoRoute(
      path: '/exercises',
      builder: (ctx, state) => const ExerciseLibraryScreen(),
    ),
    GoRoute(
      path: '/exercises/new',
      builder: (ctx, state) => const AddExerciseScreen(),
    ),
    GoRoute(
      path: '/exercises/:id/edit',
      builder: (ctx, state) {
        return AddExerciseScreen(exercise: state.extra as Exercise);
      },
    ),
    GoRoute(
      path: '/week-summary',
      builder: (ctx, state) {
        final weekStart = state.extra as DateTime?;
        return WeekSummaryScreen(weekStart: weekStart);
      },
    ),
    GoRoute(path: '/settings', builder: (ctx, state) => const SettingsScreen()),
  ],
);
