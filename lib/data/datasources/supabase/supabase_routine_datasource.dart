import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseRoutineDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getAllRoutines() async {
    final response = await _client.from('routines').select();
    return response;
  }

  Future<Map<String, dynamic>> getRoutine(String routineId) async {
    final response =
        await _client.from('routines').select().eq('id', routineId).single();
    return response;
  }

  Future<String> createRoutine(Map<String, dynamic> routineData) async {
    final response =
        await _client.from('routines').insert(routineData).select();
    return response[0]['id'];
  }

  Future<void> updateRoutine(
    String routineId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('routines').update(data).eq('id', routineId);
  }

  Future<void> deleteRoutine(String routineId) async {
    await _client.from('routines').delete().eq('id', routineId);
  }

  // User Routines
  Future<List<Map<String, dynamic>>> getUserRoutines(String userId) async {
    final response = await _client
        .from('user_routines')
        .select('*, routines(*)')
        .eq('user_id', userId)
        .order('assigned_date', ascending: false);
    return response;
  }

  Future<String> assignRoutineToUser(
    Map<String, dynamic> userRoutineData,
  ) async {
    final response =
        await _client.from('user_routines').insert(userRoutineData).select();
    return response[0]['id'];
  }

  Future<void> updateUserRoutineStatus(
    String userRoutineId,
    String status,
  ) async {
    Map<String, dynamic> updateData = {'status': status};

    if (status == 'completed') {
      updateData['completion_date'] = DateTime.now().toIso8601String();
    }

    await _client
        .from('user_routines')
        .update(updateData)
        .eq('id', userRoutineId);
  }

  Future<List<Map<String, dynamic>>> getPendingValidationRoutines() async {
    final response = await _client
        .from('user_routines')
        .select('*, routines(*), profiles(*)')
        .eq('status', 'completed');
    return response;
  }

  Future<void> validateUserRoutine(
    String userRoutineId,
    String coachId,
    String feedback,
    int experiencePoints,
  ) async {
    await _client
        .from('user_routines')
        .update({
          'status': 'validated',
          'validated_by': coachId,
          'feedback': feedback,
          'experience_gained': experiencePoints,
        })
        .eq('id', userRoutineId);

    // Récupérer l'ID de l'utilisateur
    final userRoutine =
        await _client
            .from('user_routines')
            .select('user_id')
            .eq('id', userRoutineId)
            .single();

    // Mettre à jour les points d'expérience de l'utilisateur
    if (userRoutine != null) {
      await _client.rpc(
        'add_user_experience',
        params: {
          'user_id_param': userRoutine['user_id'],
          'points_param': experiencePoints,
        },
      );
    }
  }
}
