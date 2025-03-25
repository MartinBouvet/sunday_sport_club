import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseExerciseDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getAllExercises() async {
    final response = await _client.from('exercises').select();
    return response;
  }

  Future<Map<String, dynamic>> getExercise(String exerciseId) async {
    final response =
        await _client.from('exercises').select().eq('id', exerciseId).single();
    return response;
  }

  Future<String> createExercise(Map<String, dynamic> exerciseData) async {
    final response =
        await _client.from('exercises').insert(exerciseData).select();
    return response[0]['id'];
  }

  Future<void> updateExercise(
    String exerciseId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('exercises').update(data).eq('id', exerciseId);
  }

  Future<void> deleteExercise(String exerciseId) async {
    await _client.from('exercises').delete().eq('id', exerciseId);
  }

  Future<List<Map<String, dynamic>>> getExercisesByCategory(
    String category,
  ) async {
    final response = await _client
        .from('exercises')
        .select()
        .eq('category', category);
    return response;
  }

  Future<List<Map<String, dynamic>>> getExercisesByMuscleGroup(
    String muscleGroup,
  ) async {
    final response = await _client
        .from('exercises')
        .select()
        .eq('muscle_group', muscleGroup);
    return response;
  }

  Future<List<Map<String, dynamic>>> getExercisesByIds(List<String> ids) async {
    final response = await _client.from('exercises').select().in_('id', ids);
    return response;
  }
}
