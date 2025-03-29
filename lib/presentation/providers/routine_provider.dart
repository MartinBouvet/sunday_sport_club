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
  bool _isLoading = false;
  String? _errorMessage;

  List<Routine> get availableRoutines => _availableRoutines;
  List<UserRoutine> get userRoutines => _userRoutines;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> fetchAvailableRoutines() async {
    _setLoading(true);
    _clearError();

    try {
      _availableRoutines = await _routineRepository.getAllRoutines();
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des routines: ${e.toString()}');
    }
  }

  Future<void> fetchUserRoutines(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('Récupération des routines utilisateur: $userId');
      _userRoutines = await _routineRepository.getUserRoutines(userId);

      if (_userRoutines.isEmpty) {
        debugPrint('Aucune routine trouvée, création d\'une routine de test');
        // Créer une routine de test si l'utilisateur n'en a pas
        await _routineRepository.createRoutineForUser(userId);
        // Récupérer à nouveau les routines
        _userRoutines = await _routineRepository.getUserRoutines(userId);
      }

      _setLoading(false);
    } catch (e) {
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
      debugPrint('Erreur getExerciseById: $e');
      return null;
    }
  }

  Future<Routine?> getRoutineById(String routineId) async {
    _setLoading(true);
    _clearError();

    try {
      final routine = await _routineRepository.getRoutine(routineId);
      _setLoading(false);
      return routine;
    } catch (e) {
      _setError('Erreur lors du chargement de la routine: ${e.toString()}');
      return null;
    }
  }

  Future<bool> completeUserRoutine(String userRoutineId) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _routineRepository.completeUserRoutine(
        userRoutineId,
      );

      if (success) {
        // Mise à jour locale
        final index = _userRoutines.indexWhere((r) => r.id == userRoutineId);
        if (index != -1) {
          _userRoutines[index] = UserRoutine(
            id: _userRoutines[index].id,
            userId: _userRoutines[index].userId,
            routineId: _userRoutines[index].routineId,
            assignedDate: _userRoutines[index].assignedDate,
            status: 'completed',
            completionDate: DateTime.now(),
            routine: _userRoutines[index].routine,
          );
        }
      }

      _setLoading(false);
      return success;
    } catch (e) {
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
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
