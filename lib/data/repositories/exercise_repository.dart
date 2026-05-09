import '../models/exercise.dart';
import '../services/storage_service.dart';

class ExerciseRepository {
  final StorageService _storage;

  ExerciseRepository(this._storage);

  List<Exercise> getAll() => _storage.getAllExercises();

  List<Exercise> search(String query) {
    if (query.isEmpty) return getAll();
    final q = query.toLowerCase();
    return getAll()
        .where(
          (e) =>
              e.name.toLowerCase().contains(q) ||
              e.muscleGroups.any((m) => m.toLowerCase().contains(q)) ||
              e.category.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Exercise> filterByCategory(String? category) {
    if (category == null) return getAll();
    return getAll().where((e) => e.category == category).toList();
  }

  Future<void> save(Exercise exercise) => _storage.saveExercise(exercise);

  Future<void> delete(String id) => _storage.deleteExercise(id);
}
