import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseRoutineDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getAllRoutines() async {
    try {
      final response = await _client.from('routines').select();
      debugPrint('getAllRoutines: ${response.length} routines récupérées');
      return List<Map<String, dynamic>>.from(response);
    } catch (e, stackTrace) {
      debugPrint('Erreur dans getAllRoutines: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<Map<String, dynamic>> getRoutine(String routineId) async {
    try {
      final response =
          await _client.from('routines').select().eq('id', routineId).single();
      return response;
    } catch (e) {
      debugPrint('Erreur dans getRoutine($routineId): $e');
      throw Exception('Routine non trouvée: $e');
    }
  }

  Future<String> createRoutine(Map<String, dynamic> routineData) async {
    try {
      final response =
          await _client.from('routines').insert(routineData).select();
      return response[0]['id'];
    } catch (e) {
      debugPrint('Erreur dans createRoutine: $e');
      throw Exception('Échec de création de routine: $e');
    }
  }

  Future<void> updateRoutine(
    String routineId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client.from('routines').update(data).eq('id', routineId);
    } catch (e) {
      debugPrint('Erreur dans updateRoutine: $e');
      throw Exception('Échec de mise à jour de routine: $e');
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    try {
      await _client.from('routines').delete().eq('id', routineId);
    } catch (e) {
      debugPrint('Erreur dans deleteRoutine: $e');
      throw Exception('Échec de suppression de routine: $e');
    }
  }

  // Méthode optimisée pour récupérer les routines d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserRoutines(String userId) async {
    // Validation d'entrée
    if (userId.isEmpty) {
      debugPrint('ERREUR: getUserRoutines appelée avec un userId vide');
      return [];
    }
    
    debugPrint('Récupération des routines pour l\'utilisateur: $userId');
    
    try {
      // Premièrement, vérifions que l'utilisateur existe
      final userCheck = await _client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (userCheck == null) {
        debugPrint('Utilisateur non trouvé dans la base de données: $userId');
        return [];
      }
      
      // Déterminons la structure de la table user_routines
      List<Map<String, dynamic>> userRoutines = [];
      
      // Essai avec profile_id (variante la plus courante)
      debugPrint('Tentative de récupération avec profile_id...');
      final profileIdResponse = await _client
          .from('user_routines')
          .select('*, routines(*)')
          .eq('profile_id', userId);
      
      if (profileIdResponse.isNotEmpty) {
        userRoutines = List<Map<String, dynamic>>.from(profileIdResponse);
        debugPrint('Routines récupérées avec profile_id: ${userRoutines.length}');
      } else {
        // Essai avec user_id (autre variante courante)
        debugPrint('Tentative de récupération avec user_id...');
        final userIdResponse = await _client
            .from('user_routines')
            .select('*, routines(*)')
            .eq('user_id', userId);
        
        if (userIdResponse.isNotEmpty) {
          userRoutines = List<Map<String, dynamic>>.from(userIdResponse);
          debugPrint('Routines récupérées avec user_id: ${userRoutines.length}');
        } else {
          // Si aucune routine n'est trouvée, nous allons insérer une routine de test
          debugPrint('Aucune routine trouvée - création d\'une routine de test...');
          
          // 1. Récupérer une routine existante
          final routinesResponse = await _client
              .from('routines')
              .select('id')
              .limit(1);
          
          if (routinesResponse.isNotEmpty) {
            final routineId = routinesResponse[0]['id'];
            
            // 2. Créer une routine utilisateur de test
            await _client
                .from('user_routines')
                .insert({
                  'profile_id': userId,
                  'routine_id': routineId,
                  'assigned_date': DateTime.now().toIso8601String(),
                  'status': 'assigned'
                });
            
            // 3. Récupérer à nouveau les routines
            final newResponse = await _client
                .from('user_routines')
                .select('*, routines(*)')
                .eq('profile_id', userId);
            
            userRoutines = List<Map<String, dynamic>>.from(newResponse);
            debugPrint('Routine de test créée et récupérée: ${userRoutines.length}');
          }
        }
      }
      
      // Vérification des données récupérées
      if (userRoutines.isNotEmpty) {
        // Journalisation des clés disponibles dans la première routine
        final firstRoutine = userRoutines.first;
        debugPrint('Clés disponibles dans la routine: ${firstRoutine.keys.join(', ')}');
        
        // Vérification de la présence des routines liées
        if (firstRoutine.containsKey('routines')) {
          final routineData = firstRoutine['routines'];
          debugPrint('Données de routine liées disponibles: ${routineData != null}');
          
          if (routineData != null) {
            debugPrint('Clés dans routine liée: ${(routineData as Map<String, dynamic>).keys.join(', ')}');
          }
        }
        
        // Vérification des statuts disponibles
        final statusValues = userRoutines
            .map((routine) => routine['status']?.toString() ?? 'null')
            .toSet()
            .toList();
        debugPrint('Statuts de routines disponibles: $statusValues');
      }
      
      return userRoutines;
    } catch (e, stackTrace) {
      debugPrint('ERREUR dans getUserRoutines: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  Future<String> assignRoutineToUser(
    Map<String, dynamic> userRoutineData,
  ) async {
    try {
      // Garantir que nous utilisons le bon nom de colonne pour l'ID utilisateur
      if (userRoutineData.containsKey('user_id') && !userRoutineData.containsKey('profile_id')) {
        userRoutineData['profile_id'] = userRoutineData['user_id'];
        userRoutineData.remove('user_id');
      }
      
      // Ajouter la date d'assignation si manquante
      if (!userRoutineData.containsKey('assigned_date')) {
        userRoutineData['assigned_date'] = DateTime.now().toIso8601String();
      }
      
      // Ajouter le statut par défaut si manquant
      if (!userRoutineData.containsKey('status')) {
        userRoutineData['status'] = 'assigned';
      }
      
      debugPrint('Assignation de routine: $userRoutineData');
      
      final response =
          await _client.from('user_routines').insert(userRoutineData).select();
      
      if (response.isEmpty) {
        throw Exception('Aucune donnée retournée après insertion');
      }
      
      final newId = response[0]['id'];
      debugPrint('Routine assignée avec succès, ID: $newId');
      return newId;
    } catch (e, stackTrace) {
      debugPrint('ERREUR dans assignRoutineToUser: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Échec d\'assignation de routine: $e');
    }
  }

  Future<void> updateUserRoutineStatus(
    String userRoutineId,
    String status,
  ) async {
    try {
      debugPrint('Mise à jour du statut de routine: $userRoutineId à $status');
      
      // Normalisation du statut
      String normalizedStatus = _normalizeStatus(status);
      
      // Données à mettre à jour
      Map<String, dynamic> updateData = {'status': normalizedStatus};
      
      // Si le statut est "terminé", ajouter la date de complétion
      if (normalizedStatus == 'completed') {
        updateData['completion_date'] = DateTime.now().toIso8601String();
      }
      
      // Exécution de la mise à jour
      await _client
          .from('user_routines')
          .update(updateData)
          .eq('id', userRoutineId);
      
      debugPrint('Statut de routine mis à jour avec succès');
    } catch (e, stackTrace) {
      debugPrint('ERREUR dans updateUserRoutineStatus: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Échec de mise à jour du statut: $e');
    }
  }

  // Fonction utilitaire pour normaliser les statuts
  String _normalizeStatus(String status) {
    final String lowercaseStatus = status.toLowerCase();
    
    if (lowercaseStatus.contains('assigné')) return 'assigned';
    if (lowercaseStatus.contains('progress') || lowercaseStatus.contains('en cours')) return 'in_progress';
    if (lowercaseStatus.contains('complet') || lowercaseStatus.contains('terminé')) return 'completed';
    if (lowercaseStatus.contains('validé')) return 'validated';
    
    // Si aucune correspondance n'est trouvée, retourner le statut d'origine
    return status;
  }

  Future<List<Map<String, dynamic>>> getPendingValidationRoutines() async {
    final response = await _client
        .from('user_routines')
        .select('*, routines(*), profiles(*)')
        .eq('status', 'completed');
    
    // Conversion explicite pour assurer le bon type
    return List<Map<String, dynamic>>.from(response);
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
            .select('profile_id')
            .eq('id', userRoutineId)
            .single();

    // Mettre à jour les points d'expérience de l'utilisateur
    if (userRoutine != null) {
      await _client.rpc(
        'add_user_experience',
        params: {
          'user_id_param': userRoutine['profile_id'],
          'points_param': experiencePoints,
        },
      );
    }
  }
  Future<int> getPendingValidationCount() async {
  try {
    final response = await _client
        .from('routines')
        .select('id')
        .eq('status', 'pending_validation');

    return response.count ?? 0;
  } catch (e) {
    rethrow;
  }
}
Future<bool> isValidatedByCoach(String routineId) async {
  try {
    final response = await _client
        .from('user_routines')
        .select('is_validated_by_coach')
        .eq('routine_id', routineId)
        .single();

    return response['is_validated_by_coach'] ?? false;
  } catch (e) {
    rethrow;
  }
}
}