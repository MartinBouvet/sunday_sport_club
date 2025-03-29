import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/user_routine.dart';
import '../datasources/supabase/supabase_routine_datasource.dart';
import '../models/exercise.dart';

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

  // Méthodes ajoutées pour l'admin dashboard
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
Future<List<Exercise>> getRoutineExercises(String routineId) async {
    try {
      final exercisesData = await _datasource.getRoutineExercises(routineId);
      
      // Convertir les données brutes en objets Exercise
      List<Exercise> exercises = [];
      
      for (var data in exercisesData) {
        // Vérifier si les données d'exercice sont présentes
        if (data['exercises'] != null) {
          // Créer un objet Exercise à partir des données de l'exercice
          final exercise = Exercise(
            id: data['exercises']['id'] ?? '',
            name: data['exercises']['name'] ?? 'Exercice sans nom',
            description: data['exercises']['description'] ?? '',
            category: data['exercises']['category'] ?? '',
            difficulty: data['exercises']['difficulty'] ?? 'intermédiaire',
            durationSeconds: data['exercises']['duration_seconds'] ?? 60,
            repetitions: data['reps'] ?? data['exercises']['repetitions'] ?? 10,
            sets: data['sets'] ?? data['exercises']['sets'] ?? 3,
            muscleGroup: data['exercises']['muscle_group'] ?? '',
          );
          
          exercises.add(exercise);
        }
      }
      
      return exercises;
    } catch (e) {
      debugPrint('Erreur getRoutineExercises: $e');
      return [];
    }
  }
}
