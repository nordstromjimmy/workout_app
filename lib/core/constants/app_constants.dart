class AppConstants {
  AppConstants._();

  // Hive box names
  static const String exerciseBox = 'exercises';
  static const String workoutBox = 'workouts';
  static const String templateBox = 'templates';
  static const String settingsBox = 'settings';

  // Settings keys
  static const String weightUnitKey = 'weight_unit';
  static const String firstLaunchKey = 'first_launch';

  // Defaults
  static const String defaultWeightUnit = 'kg'; // or 'lbs'

  // Muscle groups
  static const List<String> muscleGroups = [
    'Bröst',
    'Rygg',
    'Axlar',
    'Biceps',
    'Triceps',
    'Underarmar',
    'Core',
    //'Glutes',
    //'Quads',
    //'Hamstrings',
    'Vader',
    'Hela kroppen',
  ];

  // Exercise categories
  static const List<String> exerciseCategories = [
    'Styrka',
    'Kropssvikt',
    'Kondition',
    'Flexibilitet',
    'Meditation',
    'Annan',
  ];
}
