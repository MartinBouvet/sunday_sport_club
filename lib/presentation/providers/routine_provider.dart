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
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des routines: ${e.toString()}');
    }
  }

  Future<void> fetchUserRoutines(String userId) async {
    _setLoading(true);
    _clearMessages();

    try {
      _userRoutines = await _routineRepository.getUserRoutines(userId);
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
      _setError(
        'Erreur lors de la récupération de l\'exercice: ${e.toString()}',
      );
      return null;
    }
  }

  Future<bool> completeUserRoutine(String userRoutineId) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _routineRepository.updateUserRoutineStatus(
        userRoutineId,
        'completed',
      );

      // Mise à jour locale
      final index = _userRoutines.indexWhere((r) => r.id == userRoutineId);
      if (index != -1) {
        _userRoutines[index] = _userRoutines[index].copyWith(
          status: 'completed',
          completionDate: DateTime.now(),
        );
      }

      _setSuccess('Routine terminée avec succès');
      return true;
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
