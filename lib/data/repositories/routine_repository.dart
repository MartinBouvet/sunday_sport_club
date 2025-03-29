import 'package:flutter/material.dart';
import '../models/routine.dart';
import '../models/user_routine.dart';
import '../datasources/supabase/supabase_routine_datasource.dart';
import '../../../core/utils/supabase_client.dart';

class RoutineRepository {
  final SupabaseRoutineDatasource _datasource = SupabaseRoutineDatasource();

  // Récupérer toutes les routines disponibles
  Future<List<Routine>> getAllRoutines() async {
    try {
      final response = await _datasource.getAllRoutines();
      debugPrint("getAllRoutines: ${response.length} routines récupérées");

      List<Routine> routines = [];
      for (var data in response) {
        try {
          routines.add(Routine.fromJson(data));
        } catch (e) {
          debugPrint("Erreur lors de la conversion de routine: $e");
        }
      }

      debugPrint("Conversion de ${routines.length} routines depuis JSON");
      return routines;
    } catch (e) {
      debugPrint("Erreur lors de la récupération de toutes les routines: $e");
      return [];
    }
  }

  // Récupérer une routine spécifique par ID
  Future<Routine?> getRoutine(String routineId) async {
    try {
      final response = await _datasource.getRoutine(routineId);
      return Routine.fromJson(response);
    } catch (e) {
      debugPrint("Erreur lors de la récupération de la routine $routineId: $e");
      return null;
    }
  }

  // Récupérer toutes les routines d'un utilisateur
  Future<List<UserRoutine>> getUserRoutines(String userId) async {
    try {
      final response = await _datasource.getUserRoutines(userId);
      debugPrint("getUserRoutines: ${response.length} routines trouvées");

      List<UserRoutine> userRoutines = [];
      for (var data in response) {
        try {
          // Vérifions le format des données
          debugPrint(
            "Data: ${data.toString().substring(0, min(100, data.toString().length))}...",
          );
          userRoutines.add(UserRoutine.fromJson(data));
        } catch (e) {
          debugPrint("Erreur de conversion pour UserRoutine: $e");
        }
      }

      return userRoutines;
    } catch (e) {
      debugPrint("Erreur lors de la récupération des routines utilisateur: $e");
      return [];
    }
  }

  // Créer une nouvelle routine utilisateur
  Future<void> createUserRoutine(UserRoutine userRoutine) async {
    try {
      await _datasource.createUserRoutine(userRoutine.toJson());
    } catch (e) {
      debugPrint("Erreur lors de la création de la routine utilisateur: $e");
      rethrow;
    }
  }

  // lib/data/repositories/routine_repository.dart
  Future<String> createTestRoutine() async {
    try {
      final routine = Routine(
        id: 'routine-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Routine d\'entraînement hebdomadaire',
        description: 'Exercices de base pour renforcer tout le corps',
        difficulty: 'intermédiaire',
        estimatedDurationMinutes: 30,
        exerciseIds: ['ex1', 'ex2', 'ex3'],
        createdBy: 'system',
        createdAt: DateTime.now(),
        isPublic: true,
      );

      // Créer les exercices si nécessaire
      await _createSampleExercises();

      return await _datasource.createRoutine(routine.toJson());
    } catch (e) {
      debugPrint("Erreur création routine test: $e");
      throw e;
    }
  }

  Future<void> _createSampleExercises() async {
    try {
      final exercises = [
        {
          'id': 'ex1',
          'name': 'Pompes',
          'description': 'Effectuer des pompes en gardant le dos droit',
          'category': 'force',
          'difficulty': 'intermédiaire',
          'duration_seconds': 60,
          'repetitions': 15,
          'sets': 3,
          'muscle_group': 'pectoraux',
        },
        {
          'id': 'ex2',
          'name': 'Squats',
          'description': 'Effectuer des squats en gardant le dos droit',
          'category': 'force',
          'difficulty': 'intermédiaire',
          'duration_seconds': 60,
          'repetitions': 20,
          'sets': 3,
          'muscle_group': 'jambes',
        },
        {
          'id': 'ex3',
          'name': 'Burpees',
          'description': 'Enchaîner les mouvements rapidement',
          'category': 'cardio',
          'difficulty': 'difficile',
          'duration_seconds': 45,
          'repetitions': 10,
          'sets': 3,
          'muscle_group': 'full_body',
        },
      ];

      for (var exercise in exercises) {
        await supabase.from('exercises').upsert(exercise);
      }
    } catch (e) {
      debugPrint("Erreur création exercices: $e");
    }
  }

  // Mettre à jour le statut d'une routine utilisateur
  Future<void> updateUserRoutineStatus(
    String userRoutineId,
    String status,
  ) async {
    try {
      await _datasource.updateUserRoutineStatus(userRoutineId, status);
    } catch (e) {
      debugPrint("Erreur lors de la mise à jour du statut: $e");
      rethrow;
    }
  }

  // Obtenir le nombre de routines en attente de validation
  Future<int> getPendingValidationCount() async {
    try {
      final routines = await _datasource.getPendingValidationRoutines();
      return routines.length;
    } catch (e) {
      debugPrint("Erreur lors du comptage des routines en attente: $e");
      return 0;
    }
  }
}

// Fonction utilitaire pour obtenir le minimum de 2 nombres
int min(int a, int b) => a < b ? a : b;
