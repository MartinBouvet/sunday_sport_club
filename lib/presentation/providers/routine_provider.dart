import 'package:flutter/material.dart';
import '../../data/models/routine.dart';
import '../../data/models/user_routine.dart';
import '../../data/models/exercise.dart';
import '../../data/repositories/routine_repository.dart';
import '../../data/repositories/exercise_repository.dart';

class RoutineProvider extends ChangeNotifier {
  final RoutineRepository _routineRepository = RoutineRepository();
  final ExerciseRepository _exerciseRepository = ExerciseRepository();

  List<Routine> _availableRoutines = [];
  List<UserRoutine> _userRoutines = [];
  Map<String, Exercise> _exercisesCache = {};
  UserRoutine? _currentUserRoutine;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<Routine> get availableRoutines => _availableRoutines;
  List<UserRoutine> get userRoutines => _userRoutines;
  UserRoutine? get currentUserRoutine => _currentUserRoutine;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  Future<void> fetchAvailableRoutines() async {
    _setLoading(true);
    _clearMessages();

    try {
      _availableRoutines = await _routineRepository.getAllRoutines();
      debugPrint("Routines disponibles récupérées: ${_availableRoutines.length}");
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des routines: ${e.toString()}');
    }
  }

  Future<void> fetchUserRoutines(String userId) async {
    _setLoading(true);
    _clearMessages();

    try {
      debugPrint("Récupération des routines pour l'utilisateur: $userId");
      _userRoutines = await _routineRepository.getUserRoutines(userId);
      
      // Analyse des statuts de routine
      final Map<String, int> statusCounts = {};
      for (var routine in _userRoutines) {
        statusCounts[routine.status] = (statusCounts[routine.status] ?? 0) + 1;
        debugPrint("Routine ID: ${routine.id}, Status: ${routine.status}, RoutineID: ${routine.routineId}");
      }
      
      // Afficher un résumé des statuts
      statusCounts.forEach((status, count) {
        debugPrint("Statut '$status': $count routines");
      });
      
      _setLoading(false);
    } catch (e) {
      debugPrint("⚠️ ERREUR lors de la récupération des routines: $e");
      _setError(
        'Erreur lors de la récupération des routines utilisateur: ${e.toString()}',
      );
    }
  }

  Future<Exercise?> getExerciseById(String exerciseId) async {
    if (_exercisesCache.containsKey(exerciseId)) {
      return _exercisesCache[exerciseId];
    }

    try {
      final exercise = await _exerciseRepository.getExercise(exerciseId);
      if (exercise != null) {
        _exercisesCache[exerciseId] = exercise;
      }
      return exercise;
    } catch (e) {
      _setError(
        'Erreur lors de la récupération de l\'exercice: ${e.toString()}',
      );
      return null;
    }
  }

  Future<Routine?> getRoutineById(String routineId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final routine = await _routineRepository.getRoutine(routineId);
      debugPrint("Routine récupérée: id=${routine?.id}, nom=${routine?.name}");
      _setLoading(false);
      return routine;
    } catch (e) {
      _setError('Erreur lors du chargement de la routine: ${e.toString()}');
      return null;
    }
  }

  Future<bool> completeUserRoutine(String userRoutineId) async {
    _setLoading(true);
    _clearMessages();

    try {
      debugPrint("Tentative de complétion de la routine: $userRoutineId");
      await _routineRepository.updateUserRoutineStatus(
        userRoutineId,
        'terminé',
      );

      // Mise à jour locale
      final index = _userRoutines.indexWhere((r) => r.id == userRoutineId);
      if (index != -1) {
        debugPrint("Mise à jour locale de la routine: statut précédent=${_userRoutines[index].status}");
        _userRoutines[index] = _userRoutines[index].copyWith(
          status: 'terminé',
          completionDate: DateTime.now(),
        );
        debugPrint("Routine mise à jour localement: nouveau statut=${_userRoutines[index].status}");
      } else {
        debugPrint("⚠️ Routine non trouvée localement pour mise à jour: $userRoutineId");
      }

      _setSuccess('Routine terminée avec succès');
      return true;
    } catch (e) {
      debugPrint("⚠️ ERREUR lors de la complétion de routine: $e");
      _setError('Erreur lors de la complétion de la routine: ${e.toString()}');
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _successMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}