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
  // lib/data/datasources/supabase/supabase_routine_datasource.dart
  Future<List<Map<String, dynamic>>> getUserRoutines(String userId) async {
    try {
      // Utilise les tables existantes
      final response = await _client
          .from('user_routines') // Table visible dans votre capture
          .select('*, routines(*)') // Jointure avec routines
          .eq('user_id', userId);

      return response;
    } catch (e) {
      debugPrint("Erreur récupération routines: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRoutineExercises(
    String routineId,
  ) async {
    try {
      final response = await _client
          .from('routine_exercises') // Table visible dans votre capture
          .select('*, exercises(*)')
          .eq('routine_id', routineId)
          .order('sequence_num');

      return response;
    } catch (e) {
      return [];
    }
  }

  Future<String> assignRoutineToUser(
    Map<String, dynamic> userRoutineData,
  ) async {
    try {
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
    if (lowercaseStatus.contains('progress') ||
        lowercaseStatus.contains('en cours'))
      return 'in_progress';
    if (lowercaseStatus.contains('complet') ||
        lowercaseStatus.contains('terminé'))
      return 'completed';
    if (lowercaseStatus.contains('validé')) return 'validated';

    // Si aucune correspondance n'est trouvée, retourner le statut d'origine
    return status;
  }

  Future<List<Map<String, dynamic>>> getPendingValidationRoutines() async {
    try {
      final response = await supabase
          .from('user_routines')
          .select()
          .in_('status', ['completed'])
          .order('completion_date', ascending: false);

      return response;
    } catch (e) {
      debugPrint("Erreur lors de la récupération des routines en attente: $e");
      rethrow;
    }
  }

  Future<void> validateUserRoutine(
    String userRoutineId,
    String validatedBy,
    String feedback,
    int experiencePoints,
  ) async {
    try {
      // 1. Mettre à jour la routine utilisateur
      await supabase
          .from('user_routines')
          .update({
            'status': 'validated',
            'validated_by': validatedBy,
            'validation_date': DateTime.now().toIso8601String(),
            'feedback': feedback,
          })
          .eq('id', userRoutineId);

      // 2. Récupérer l'ID de l'utilisateur associé à cette routine
      final routineData =
          await supabase
              .from('user_routines')
              .select('profile_id')
              .eq('id', userRoutineId)
              .single();

      // Déterminer le bon ID utilisateur
      String userId;
      if (routineData['profile_id'] != null) {
        userId = routineData['profile_id'];
      } else {
        throw Exception('Impossible de déterminer l\'ID utilisateur');
      }

      // 3. Ajouter des points d'expérience à l'utilisateur
      if (experiencePoints > 0) {
        // Récupérer les points actuels
        final userData =
            await supabase
                .from('profiles')
                .select('experience_points, level')
                .eq('id', userId)
                .single();

        final currentPoints = userData['experience_points'] ?? 0;
        final currentLevel = userData['level'] ?? 1;

        // Calculer les nouveaux points et niveau
        final newPoints = currentPoints + experiencePoints;
        final newLevel = (newPoints / 100).floor() + 1;

        // Déterminer le nouveau stade d'avatar si nécessaire
        String avatarStage = 'mince';
        if (newLevel >= 30) {
          avatarStage = 'muscle';
        } else if (newLevel >= 10) {
          avatarStage = 'moyen';
        }

        // Mettre à jour l'utilisateur
        await supabase
            .from('profiles')
            .update({
              'experience_points': newPoints,
              'level': newLevel,
              'avatar_stage': avatarStage,
            })
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint("Erreur lors de la validation de la routine: $e");
      rethrow;
    }
  }

  Future<void> createUserRoutine(Map<String, dynamic> data) async {
    try {
      debugPrint("Tentative de création d'une routine utilisateur");

      // Vérifier que les champs obligatoires sont présents
      if (!data.containsKey('profile_id')) {
        throw ArgumentError(
          "L'ID de l'utilisateur est obligatoire (profile_id)",
        );
      }

      if (!data.containsKey('routine_id')) {
        throw ArgumentError("L'ID de la routine est obligatoire");
      }

      // Vérifier quelle colonne est utilisée dans la base de données (profile_id ou user_id)
      // et adapter le payload en conséquence
      Map<String, dynamic> payload = Map.from(data);

      // Par défaut, on utilise la colonne telle qu'elle est fournie dans les données
      // Si aucune des deux n'est fournie, on lèvera une exception plus haut

      // Assurons-nous que la date d'assignation est présente
      if (!payload.containsKey('assigned_date')) {
        payload['assigned_date'] = DateTime.now().toIso8601String();
      }

      // Assurons-nous que le statut est présent
      if (!payload.containsKey('status')) {
        payload['status'] =
            'pending'; // ou 'assigné' selon votre logique métier
      }

      debugPrint("Payload pour création routine utilisateur: $payload");

      // Insertion dans la base de données
      final response =
          await supabase
              .from('user_routines')
              .insert(payload)
              .select('id')
              .single();

      debugPrint("√ Routine utilisateur créée avec ID: ${response['id']}");
    } catch (e) {
      debugPrint("❌ Erreur lors de la création de routine utilisateur: $e");
      rethrow;
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
      final response =
          await _client
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
