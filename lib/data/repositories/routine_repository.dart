import 'package:flutter/foundation.dart';
import '../datasources/supabase/supabase_routine_datasource.dart';
import '../models/routine.dart';
import '../models/user_routine.dart';

class RoutineRepository {
  final SupabaseRoutineDatasource _datasource = SupabaseRoutineDatasource();

  Future<List<Routine>> getAllRoutines() async {
    try {
      final routinesData = await _datasource.getAllRoutines();
      
      debugPrint('Conversion de ${routinesData.length} routines depuis JSON');
      final routines = routinesData.map((data) {
        try {
          return Routine.fromJson(data);
        } catch (e) {
          debugPrint('Erreur lors de la conversion de routine: $e');
          debugPrint('Données problématiques: $data');
          return null;
        }
      }).where((routine) => routine != null).cast<Routine>().toList();
      
      debugPrint('Routines disponibles récupérées: ${routines.length}');
      return routines;
    } catch (e) {
      debugPrint('! ERREUR dans getAllRoutines: $e');
      return [];
    }
  }

  Future<Routine?> getRoutine(String routineId) async {
    try {
      final routineData = await _datasource.getRoutine(routineId);
      return Routine.fromJson(routineData);
    } catch (e) {
      debugPrint('! ERREUR dans getRoutine: $e');
      return null;
    }
  }

  Future<String> createRoutine(Routine routine) async {
    try {
      return await _datasource.createRoutine(routine.toJson());
    } catch (e) {
      debugPrint('! ERREUR dans createRoutine: $e');
      rethrow;
    }
  }

  Future<void> updateRoutine(
    String routineId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _datasource.updateRoutine(routineId, data);
    } catch (e) {
      debugPrint('! ERREUR dans updateRoutine: $e');
      rethrow;
    }
  }

  Future<void> deleteRoutine(String routineId) async {
    try {
      await _datasource.deleteRoutine(routineId);
    } catch (e) {
      debugPrint('! ERREUR dans deleteRoutine: $e');
      rethrow;
    }
  }

  Future<List<UserRoutine>> getUserRoutines(String userId) async {
    try {
      final userRoutinesData = await _datasource.getUserRoutines(userId);
      
      debugPrint('Nombre total de routines récupérées: ${userRoutinesData.length}');
      if (userRoutinesData.isEmpty) {
        return [];
      }
      
      // Log des statuts disponibles pour le débogage
      final statuses = userRoutinesData
          .map((data) => data['status']?.toString() ?? 'null')
          .toSet()
          .toList();
      debugPrint('Statuts de routines disponibles: $statuses');
      
      // Log des données brutes de quelques routines (pour débogage)
      if (userRoutinesData.isNotEmpty) {
        debugPrint('Exemple de données de routine utilisateur: ${userRoutinesData.first}');
      }
      
      final routines = userRoutinesData.map((data) {
        try {
          return UserRoutine.fromJson(data);
        } catch (e) {
          debugPrint('Erreur lors de la conversion d\'une routine utilisateur: $e');
          debugPrint('Données problématiques: $data');
          return null;
        }
      }).where((routine) => routine != null).cast<UserRoutine>().toList();
      
      // Log des statuts après conversion pour débogage
      final processedStatuses = routines
          .map((routine) => routine.status)
          .toSet()
          .toList();
      debugPrint('Statuts traités après conversion: $processedStatuses');
      
      debugPrint('Routines utilisateur traitées: ${routines.length}');
      return routines;
    } catch (e) {
      debugPrint('! ERREUR dans getUserRoutines: $e');
      return [];
    }
  }

  Future<String> assignRoutineToUser(UserRoutine userRoutine) async {
    try {
      debugPrint('Assignation de routine à utilisateur: ${userRoutine.userId}, routine: ${userRoutine.routineId}');
      return await _datasource.assignRoutineToUser(userRoutine.toJson());
    } catch (e) {
      debugPrint('! ERREUR dans assignRoutineToUser: $e');
      rethrow;
    }
  }

  Future<void> updateUserRoutineStatus(
    String userRoutineId,
    String status,
  ) async {
    try {
      debugPrint('Mise à jour du statut de routine utilisateur: $userRoutineId, nouveau statut: $status');
      await _datasource.updateUserRoutineStatus(userRoutineId, status);
      debugPrint('Statut de routine mis à jour avec succès');
    } catch (e) {
      debugPrint('! ERREUR dans updateUserRoutineStatus: $e');
      rethrow;
    }
  }
}