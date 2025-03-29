import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseRoutineDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getAllRoutines() async {
    try {
      final response = await _client.from('routines').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur getAllRoutines: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getRoutine(String routineId) async {
    try {
      final response =
          await _client.from('routines').select().eq('id', routineId).single();
      return response;
    } catch (e) {
      debugPrint('Erreur getRoutine($routineId): $e');
      throw Exception('Routine non trouvée: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserRoutines(String userId) async {
    try {
      debugPrint('Récupération des routines pour utilisateur: $userId');

      final response = await _client
          .from('user_routines')
          .select('*, routines(*)')
          .eq('user_id', userId);

      debugPrint('Routines récupérées: ${response.length}');
      return response;
    } catch (e) {
      debugPrint('Erreur getUserRoutines: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRoutineExercises(
    String routineId,
  ) async {
    try {
      final response = await _client
          .from('routine_exercises')
          .select('*, exercises(*)')
          .eq('routine_id', routineId)
          .order('sequence_num');
      return response;
    } catch (e) {
      debugPrint('Erreur getRoutineExercises: $e');
      return [];
    }
  }

  Future<void> updateUserRoutineStatus(
    String userRoutineId,
    String status,
  ) async {
    try {
      Map<String, dynamic> updateData = {'status': status};

      if (status == 'completed') {
        updateData['completion_date'] = DateTime.now().toIso8601String();
      }

      await _client
          .from('user_routines')
          .update(updateData)
          .eq('id', userRoutineId);
    } catch (e) {
      debugPrint('Erreur updateUserRoutineStatus: $e');
      throw Exception('Échec de mise à jour du statut: $e');
    }
  }

  // Créer une routine pour l'utilisateur (pour test)
  Future<String> createTestRoutine() async {
    try {
      // Créer la routine
      final routineData = {
        'name': 'Routine Hebdomadaire',
        'description': 'Exercices de base pour renforcer tout le corps',
        'difficulty': 'intermédiaire',
        'estimated_duration_minutes': 30,
        'exercise_ids': ['ex1', 'ex2', 'ex3'],
        'created_by': 'system',
        'created_at': DateTime.now().toIso8601String(),
        'is_public': true,
      };

      final routineResponse =
          await _client.from('routines').insert(routineData).select();
      return routineResponse[0]['id'];
    } catch (e) {
      debugPrint('Erreur createTestRoutine: $e');
      throw Exception('Erreur création routine: $e');
    }
  }

  Future<String> createUserRoutine(Map<String, dynamic> userRoutineData) async {
    try {
      final response =
          await _client.from('user_routines').insert(userRoutineData).select();
      return response[0]['id'];
    } catch (e) {
      debugPrint('Erreur createUserRoutine: $e');
      throw Exception('Erreur création routine utilisateur: $e');
    }
  }
}
