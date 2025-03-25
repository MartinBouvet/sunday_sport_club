import '../datasources/supabase/supabase_exercise_datasource.dart';
import '../models/exercise.dart';

class ExerciseRepository {
  final SupabaseExerciseDatasource _datasource = SupabaseExerciseDatasource();

  Future<List<Exercise>> getAllExercises() async {
    try {
      final exercisesData = await _datasource.getAllExercises();
      return exercisesData.map((data) => Exercise.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Exercise?> getExercise(String exerciseId) async {
    try {
      final exerciseData = await _datasource.getExercise(exerciseId);
      return Exercise.fromJson(exerciseData);
    } catch (e) {
      return null;
    }
  }

  Future<String> createExercise(Exercise exercise) async {
    return await _datasource.createExercise(exercise.toJson());
  }

  Future<void> updateExercise(
    String exerciseId,
    Map<String, dynamic> data,
  ) async {
    await _datasource.updateExercise(exerciseId, data);
  }

  Future<void> deleteExercise(String exerciseId) async {
    await _datasource.deleteExercise(exerciseId);
  }
}
