import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/user_routine.dart';
import '../datasources/supabase/supabase_routine_datasource.dart';

class RoutineRepository {
  final SupabaseRoutineDatasource _datasource = SupabaseRoutineDatasource();

  Future<List<Routine>> getAllRoutines() async {
    try {
      final routinesData = await _datasource.getAllRoutines();
      return routinesData.map((data) => Routine.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Erreur getAllRoutines: $e');
      return [];
    }
  }

  Future<Routine?> getRoutine(String routineId) async {
    try {
      final routineData = await _datasource.getRoutine(routineId);
      return Routine.fromJson(routineData);
    } catch (e) {
      debugPrint('Erreur getRoutine: $e');
      return null;
    }
  }

  Future<List<UserRoutine>> getUserRoutines(String userId) async {
    try {
      final userRoutinesData = await _datasource.getUserRoutines(userId);

      return userRoutinesData.map((data) {
        final routineData = data['routines'];
        Routine? routine;

        if (routineData != null) {
          routine = Routine.fromJson(routineData);
        }

        return UserRoutine.fromJson({...data, 'routine': routine});
      }).toList();
    } catch (e) {
      debugPrint('Erreur getUserRoutines: $e');
      return [];
    }
  }

  Future<bool> completeUserRoutine(String userRoutineId) async {
    try {
      await _datasource.updateUserRoutineStatus(userRoutineId, 'completed');
      return true;
    } catch (e) {
      debugPrint('Erreur completeUserRoutine: $e');
      return false;
    }
  }

  // Pour créer des données de test
  Future<String> createRoutineForUser(String userId) async {
    try {
      // Créer routine
      final routineId = await _datasource.createTestRoutine();

      // Assigner à l'utilisateur
      final userRoutineData = {
        'user_id': userId,
        'routine_id': routineId,
        'assigned_date': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      return await _datasource.createUserRoutine(userRoutineData);
    } catch (e) {
      debugPrint('Erreur createRoutineForUser: $e');
      return '';
    }
  }

  Future<int> getPendingValidationCount() async {
  try {
    // Utiliser le datasource pour récupérer les routines en attente
    final pendingRoutines = await _datasource.getPendingValidationRoutines();
    
    // Retourner le nombre d'éléments dans la liste
    return pendingRoutines.length;
  } catch (e) {
    debugPrint('Erreur lors du comptage des routines en attente de validation: $e');
    
    // En cas d'erreur, retourner 0 comme valeur sécuritaire par défaut
    // Cela évite de bloquer l'affichage de l'UI en cas de problème
    return 0;
  }
}
}
