class Exercise {
  final String id;
  final String name;
  final String? description;
  final List<String> muscleGroups;
  final String category; // Strength | Bodyweight | Cardio | Flexibility | Other
  final bool isCustom;
  final DateTime createdAt;

  // ── Visual identity ───────────────────────────────────────────────────────
  /// Emoji shown as the exercise icon, e.g. "🏋️" or "🏃"
  final String? iconEmoji;

  /// Absolute path to a user-picked image on device (may be null)
  final String? imagePath;

  // ── Workout defaults (pre-fills sets when adding to a workout) ────────────
  final int? defaultSets;
  final int? defaultReps;
  final double? defaultWeightKg;
  final int? defaultDurationSeconds;
  final double? defaultDistanceKm;

  const Exercise({
    required this.id,
    required this.name,
    this.description,
    required this.muscleGroups,
    required this.category,
    this.isCustom = true,
    required this.createdAt,
    this.iconEmoji,
    this.imagePath,
    this.defaultSets,
    this.defaultReps,
    this.defaultWeightKg,
    this.defaultDurationSeconds,
    this.defaultDistanceKm,
  });

  /// Best single visual to show when there is no image.
  String get displayIcon {
    if (iconEmoji != null && iconEmoji!.isNotEmpty) return iconEmoji!;
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

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? muscleGroups,
    String? category,
    bool? isCustom,
    DateTime? createdAt,
    String? iconEmoji,
    String? imagePath,
    int? defaultSets,
    int? defaultReps,
    double? defaultWeightKg,
    int? defaultDurationSeconds,
    double? defaultDistanceKm,
    bool clearImagePath = false,
    bool clearIconEmoji = false,
  }) => Exercise(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    muscleGroups: muscleGroups ?? this.muscleGroups,
    category: category ?? this.category,
    isCustom: isCustom ?? this.isCustom,
    createdAt: createdAt ?? this.createdAt,
    iconEmoji: clearIconEmoji ? null : (iconEmoji ?? this.iconEmoji),
    imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
    defaultSets: defaultSets ?? this.defaultSets,
    defaultReps: defaultReps ?? this.defaultReps,
    defaultWeightKg: defaultWeightKg ?? this.defaultWeightKg,
    defaultDurationSeconds:
        defaultDurationSeconds ?? this.defaultDurationSeconds,
    defaultDistanceKm: defaultDistanceKm ?? this.defaultDistanceKm,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'muscleGroups': muscleGroups,
    'category': category,
    'isCustom': isCustom,
    'createdAt': createdAt.toIso8601String(),
    'iconEmoji': iconEmoji,
    'imagePath': imagePath,
    'defaultSets': defaultSets,
    'defaultReps': defaultReps,
    'defaultWeightKg': defaultWeightKg,
    'defaultDurationSeconds': defaultDurationSeconds,
    'defaultDistanceKm': defaultDistanceKm,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    muscleGroups: List<String>.from(json['muscleGroups'] as List),
    category: json['category'] as String,
    isCustom: json['isCustom'] as bool? ?? true,
    createdAt: DateTime.parse(json['createdAt'] as String),
    iconEmoji: json['iconEmoji'] as String?,
    imagePath: json['imagePath'] as String?,
    defaultSets: json['defaultSets'] as int?,
    defaultReps: json['defaultReps'] as int?,
    defaultWeightKg: (json['defaultWeightKg'] as num?)?.toDouble(),
    defaultDurationSeconds: json['defaultDurationSeconds'] as int?,
    defaultDistanceKm: (json['defaultDistanceKm'] as num?)?.toDouble(),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Exercise && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
