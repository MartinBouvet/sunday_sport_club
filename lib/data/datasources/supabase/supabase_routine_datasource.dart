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
        .eq('profile_id', userId);

    debugPrint('Response brute: $response');
    debugPrint('Type de response: ${response.runtimeType}');
    
    // Gestion adéquate du format de réponse
    if (response is List) {
      // Conversion sécurisée avec vérification de type
      List<Map<String, dynamic>> typedResponse = [];
      for (var item in response) {
        if (item is Map<String, dynamic>) {
          typedResponse.add(item);
        } else {
          // Conversion explicite si nécessaire
          typedResponse.add(Map<String, dynamic>.from(item as Map));
        }
      }
      return typedResponse;
    } else if (response is Map && response.containsKey('data')) {
      // Fallback pour le format alternatif (ancienne API)
      var data = response['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(
          data.map((item) => item as Map<String, dynamic>)
        );
      }
    }
    
    // Retour par défaut si structure non reconnue
    return [];
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

  Future<List<Map<String, dynamic>>> getPendingValidationRoutines() async {
  try {
    // Requête à Supabase pour récupérer les routines avec statut 'completed'
    // mais qui n'ont pas encore été validées (isValidatedByCoach = false)
    final response = await supabase
        .from('user_routines')
        .select('*')
        .eq('status', 'completed')
        .eq('is_validated_by_coach', false);

    // Normalisation des données de réponse vers une liste de Map
    if (response is List) {
      return response.map((item) => item as Map<String, dynamic>).toList();
    } else if (response is Map) {
      if (response.containsKey('data') && response['data'] is List) {
        return (response['data'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }
    }
    
    // Si le format de réponse est inattendu, retourner une liste vide
    debugPrint('Format de réponse inattendu pour les routines en attente: ${response.runtimeType}');
    return [];
  } catch (e) {
    debugPrint('Erreur lors de la récupération des routines en attente: $e');
    // Propager l'exception pour permettre une gestion appropriée au niveau supérieur
    rethrow;
  }
}
Future<bool> validateUserRoutine(String userRoutineId, String adminId, String feedback, int xpPoints) async {
    try {
      // Mettre à jour le statut de la routine
      await supabase
          .from('user_routines')
          .update({
            'status': 'validated',
            'validated_by': adminId,
            'validation_date': DateTime.now().toIso8601String(),
            'feedback': feedback,
          })
          .eq('id', userRoutineId);
      
      // Récupérer l'ID de l'utilisateur
      final response = await supabase
          .from('user_routines')
          .select('user_id')
          .eq('id', userRoutineId)
          .single();
      
      final userId = response['user_id'];
      
      // Ajouter 25 points d'XP à l'utilisateur
      await supabase
          .from('profiles')
          .update({
            'experience_points': supabase.rpc('increment_xp', params: {'user_id': userId, 'amount': xpPoints})
          })
          .eq('id', userId);
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la validation de la routine: $e');
      return false;
    }
  }
}
