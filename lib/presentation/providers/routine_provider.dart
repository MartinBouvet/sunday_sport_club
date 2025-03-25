import 'package:flutter/material.dart';
import 'package:sunday_sport_club/data/models/routine.dart';
import 'package:sunday_sport_club/data/models/user_routine.dart';
import 'package:sunday_sport_club/data/models/exercise.dart';
import 'package:sunday_sport_club/data/repositories/routine_repository.dart';
import 'package:sunday_sport_club/data/repositories/exercise_repository.dart';
import 'package:sunday_sport_club/domain/services/gamification_service.dart';
import 'package:sunday_sport_club/presentation/providers/user_provider.dart';

/// Provider responsable de la gestion des routines d'entraînement.
///
/// Gère la récupération, l'attribution, l'exécution et la validation des routines
/// d'entraînement pour les utilisateurs.
class RoutineProvider extends ChangeNotifier {
  final RoutineRepository _routineRepository;
  final ExerciseRepository _exerciseRepository;
  final GamificationService _gamificationService;
  final UserProvider _userProvider;

  List<Routine> _availableRoutines = [];
  List<UserRoutine> _userRoutines = [];
  Map<String, Exercise> _exercisesCache = {};
  UserRoutine? _currentUserRoutine;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  // État pour le suivi d'exécution d'une routine
  Map<String, bool> _exerciseCompletionStatus = {};
  int _currentExerciseIndex = 0;

  /// Constructeur qui nécessite les dépendances pour fonctionner
  RoutineProvider({
    required RoutineRepository routineRepository,
    required ExerciseRepository exerciseRepository,
    required GamificationService gamificationService,
    required UserProvider userProvider,
  })  : _routineRepository = routineRepository,
        _exerciseRepository = exerciseRepository,
        _gamificationService = gamificationService,
        _userProvider = userProvider;

  // Getters
  List<Routine> get availableRoutines => _availableRoutines;
  List<UserRoutine> get userRoutines => _userRoutines;
  UserRoutine? get currentUserRoutine => _currentUserRoutine;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;
  Map<String, bool> get exerciseCompletionStatus => _exerciseCompletionStatus;
  int get currentExerciseIndex => _currentExerciseIndex;

  /// Récupère toutes les routines disponibles
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

  /// Récupère les routines de l'utilisateur actuel
  Future<void> fetchUserRoutines() async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return;
    }

    _setLoading(true);
    _clearMessages();

    try {
      _userRoutines = await _routineRepository.getUserRoutines(user.id);
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des routines utilisateur: ${e.toString()}');
    }
  }

  /// Récupère les détails d'une routine spécifique avec ses exercices
  Future<Routine?> fetchRoutineDetails(String routineId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final routine = await _routineRepository.getRoutineById(routineId);
      
      // Si la routine est trouvée, précharger les exercices associés
      if (routine != null) {
        for (final routineExercise in routine.exercises) {
          if (!_exercisesCache.containsKey(routineExercise.exerciseId)) {
            final exercise = await _exerciseRepository.getExerciseById(routineExercise.exerciseId);
            if (exercise != null) {
              _exercisesCache[routineExercise.exerciseId] = exercise;
            }
          }
        }
      }
      
      _setLoading(false);
      return routine;
    } catch (e) {
      _setError('Erreur lors de la récupération des détails de la routine: ${e.toString()}');
      return null;
    }
  }

  /// Récupère un exercice par son ID, en utilisant d'abord le cache
  Future<Exercise?> getExerciseById(String exerciseId) async {
    // Vérifier si l'exercice est déjà dans le cache
    if (_exercisesCache.containsKey(exerciseId)) {
      return _exercisesCache[exerciseId];
    }

    try {
      final exercise = await _exerciseRepository.getExerciseById(exerciseId);
      if (exercise != null) {
        _exercisesCache[exerciseId] = exercise;
      }
      return exercise;
    } catch (e) {
      _setError('Erreur lors de la récupération de l\'exercice: ${e.toString()}');
      return null;
    }
  }

  /// Attribue une routine à l'utilisateur actuel
  Future<bool> assignRoutineToUser(String routineId, DateTime dueDate) async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return false;
    }

    _setLoading(true);
    _clearMessages();

    try {
      // Vérifier si la routine existe
      final routine = await _routineRepository.getRoutineById(routineId);
      if (routine == null) {
        _setError('Routine non trouvée');
        return false;
      }

      // Créer une nouvelle UserRoutine
      final userRoutine = UserRoutine(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        routineId: routineId,
        assignedDate: DateTime.now(),
        dueDate: dueDate,
        status: 'en cours',
        isValidatedByCoach: false,
        completedDate: null,
        exercisesCompleted: {},
      );

      // Initialiser exercisesCompleted avec tous les exercices de la routine à false
      for (final routineExercise in routine.exercises) {
        userRoutine.exercisesCompleted[routineExercise.exerciseId] = false;
      }

      // Enregistrer la UserRoutine
      await _routineRepository.saveUserRoutine(userRoutine);
      
      // Mettre à jour la liste locale
      _userRoutines.add(userRoutine);
      
      _setSuccess('Routine assignée avec succès');
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'attribution de la routine: ${e.toString()}');
      return false;
    }
  }

  /// Prépare une routine pour exécution
  Future<bool> startRoutineExecution(String userRoutineId) async {
    _setLoading(true);
    _clearMessages();

    try {
      // Trouver la UserRoutine dans la liste locale
      final userRoutine = _userRoutines.firstWhere(
        (ur) => ur.id == userRoutineId,
        orElse: () => throw Exception('Routine utilisateur non trouvée'),
      );

      // Récupérer les détails de la routine
      final routine = await _routineRepository.getRoutineById(userRoutine.routineId);
      if (routine == null) {
        _setError('Routine non trouvée');
        return false;
      }

      // Précharger tous les exercices de la routine
      for (final routineExercise in routine.exercises) {
        if (!_exercisesCache.containsKey(routineExercise.exerciseId)) {
          final exercise = await _exerciseRepository.getExerciseById(routineExercise.exerciseId);
          if (exercise != null) {
            _exercisesCache[routineExercise.exerciseId] = exercise;
          }
        }
      }

      // Initialiser l'état d'exécution
      _currentUserRoutine = userRoutine;
      _exerciseCompletionStatus = Map.from(userRoutine.exercisesCompleted);
      _currentExerciseIndex = 0;
      
      _setLoading(false);
      return true;
    } catch (e) {
      _currentUserRoutine = null;
      _exerciseCompletionStatus = {};
      _currentExerciseIndex = 0;
      _setError('Erreur lors du démarrage de la routine: ${e.toString()}');
      return false;
    }
  }

  /// Marque un exercice comme complété pendant l'exécution d'une routine
  void markExerciseCompleted(String exerciseId, bool completed) {
    if (_currentUserRoutine == null) {
      _setError('Aucune routine en cours d\'exécution');
      return;
    }

    _exerciseCompletionStatus[exerciseId] = completed;
    notifyListeners();
  }

  /// Passe à l'exercice suivant pendant l'exécution d'une routine
  Future<bool> moveToNextExercise() async {
    if (_currentUserRoutine == null) {
      _setError('Aucune routine en cours d\'exécution');
      return false;
    }

    try {
      final routine = await _routineRepository.getRoutineById(_currentUserRoutine!.routineId);
      if (routine == null) {
        _setError('Routine non trouvée');
        return false;
      }

      if (_currentExerciseIndex < routine.exercises.length - 1) {
        _currentExerciseIndex++;
        notifyListeners();
        return true;
      } else {
        // C'était le dernier exercice
        return false;
      }
    } catch (e) {
      _setError('Erreur lors du passage à l\'exercice suivant: ${e.toString()}');
      return false;
    }
  }

  /// Termine l'exécution d'une routine et enregistre les résultats
  Future<bool> completeRoutineExecution() async {
    if (_currentUserRoutine == null) {
      _setError('Aucune routine en cours d\'exécution');
      return false;
    }

    _setLoading(true);
    _clearMessages();

    try {
      // Mettre à jour la UserRoutine avec l'état de complétion des exercices
      final updatedUserRoutine = UserRoutine(
        id: _currentUserRoutine!.id,
        userId: _currentUserRoutine!.userId,
        routineId: _currentUserRoutine!.routineId,
        assignedDate: _currentUserRoutine!.assignedDate,
        dueDate: _currentUserRoutine!.dueDate,
        status: 'terminé',
        isValidatedByCoach: false,
        completedDate: DateTime.now(),
        exercisesCompleted: _exerciseCompletionStatus,
      );

      // Enregistrer les modifications
      await _routineRepository.updateUserRoutine(updatedUserRoutine);
      
      // Mettre à jour la liste locale
      final index = _userRoutines.indexWhere((ur) => ur.id == _currentUserRoutine!.id);
      if (index != -1) {
        _userRoutines[index] = updatedUserRoutine;
      }

      // Calculer les points d'expérience gagnés
      final routine = await _routineRepository.getRoutineById(_currentUserRoutine!.routineId);
      if (routine != null) {
        // Compter les exercices complétés
        final completedExercises = _exerciseCompletionStatus.values.where((isCompleted) => isCompleted).length;
        final totalExercises = routine.exercises.length;
        
        // Calculer les points (par exemple, 10 points par exercice complété)
        final experiencePoints = (completedExercises * 10).round();
        
        // Attribuer les points à l'utilisateur
        if (experiencePoints > 0) {
          await _gamificationService.awardExperiencePoints(
            userId: _currentUserRoutine!.userId,
            points: experiencePoints,
            source: 'Routine: ${routine.name}',
          );
          
          // Mettre à jour les points dans le UserProvider
          await _userProvider.addExperiencePoints(experiencePoints);
        }
      }

      // Réinitialiser l'état d'exécution
      _currentUserRoutine = null;
      _exerciseCompletionStatus = {};
      _currentExerciseIndex = 0;
      
      _setSuccess('Routine terminée avec succès');
      return true;
    } catch (e) {
      _setError('Erreur lors de la complétion de la routine: ${e.toString()}');
      return false;
    }
  }

  /// Valide une routine terminée (fonctionnalité coach)
  Future<bool> validateUserRoutine(String userRoutineId) async {
    _setLoading(true);
    _clearMessages();

    try {
      // Récupérer la UserRoutine
      final userRoutine = await _routineRepository.getUserRoutineById(userRoutineId);
      if (userRoutine == null) {
        _setError('Routine utilisateur non trouvée');
        return false;
      }

      if (userRoutine.status != 'terminé') {
        _setError('La routine n\'est pas encore terminée');
        return false;
      }

      // Mettre à jour le statut de validation
      final updatedUserRoutine = UserRoutine(
        id: userRoutine.id,
        userId: userRoutine.userId,
        routineId: userRoutine.routineId,
        assignedDate: userRoutine.assignedDate,
        dueDate: userRoutine.dueDate,
        status: 'validé',
        isValidatedByCoach: true,
        completedDate: userRoutine.completedDate,
        exercisesCompleted: userRoutine.exercisesCompleted,
      );

      await _routineRepository.updateUserRoutine(updatedUserRoutine);
      
      // Mettre à jour la liste locale si nécessaire
      final index = _userRoutines.indexWhere((ur) => ur.id == userRoutineId);
      if (index != -1) {
        _userRoutines[index] = updatedUserRoutine;
      }

      // Attribuer un bonus d'expérience pour la validation
      await _gamificationService.awardExperiencePoints(
        userId: userRoutine.userId,
        points: 20, // Bonus pour validation par le coach
        source: 'Validation de routine par le coach',
      );
      
      _setSuccess('Routine validée avec succès');
      return true;
    } catch (e) {
      _setError('Erreur lors de la validation de la routine: ${e.toString()}');
      return false;
    }
  }

  /// Récupère les statistiques de routines pour l'utilisateur actuel
  Future<Map<String, dynamic>> getUserRoutineStats() async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return {};
    }

    _setLoading(true);
    _clearMessages();

    try {
      await fetchUserRoutines();
      
      // Calculer les statistiques
      final totalRoutines = _userRoutines.length;
      final completedRoutines = _userRoutines.where((ur) => 
        ur.status == 'terminé' || ur.status == 'validé'
      ).length;
      final validatedRoutines = _userRoutines.where((ur) => 
        ur.status == 'validé'
      ).length;
      final inProgressRoutines = _userRoutines.where((ur) => 
        ur.status == 'en cours'
      ).length;
      
      // Calculer le taux de complétion
      final completionRate = totalRoutines > 0 
          ? (completedRoutines / totalRoutines) * 100 
          : 0;
      
      // Calculer le taux de validation
      final validationRate = completedRoutines > 0 
          ? (validatedRoutines / completedRoutines) * 100 
          : 0;

      _setLoading(false);
      
      return {
        'totalRoutines': totalRoutines,
        'completedRoutines': completedRoutines,
        'validatedRoutines': validatedRoutines,
        'inProgressRoutines': inProgressRoutines,
        'completionRate': completionRate,
        'validationRate': validationRate,
      };
    } catch (e) {
      _setError('Erreur lors du calcul des statistiques: ${e.toString()}');
      return {};
    }
  }

  /// Crée une nouvelle routine (fonctionnalité coach)
  Future<bool> createRoutine(Routine routine) async {
    _setLoading(true);
    _clearMessages();

    try {
      final createdRoutine = await _routineRepository.createRoutine(routine);
      
      // Ajouter à la liste locale
      _availableRoutines.add(createdRoutine);
      
      _setSuccess('Routine créée avec succès');
      return true;
    } catch (e) {
      _setError('Erreur lors de la création de la routine: ${e.toString()}');
      return false;
    }
  }

  // Méthodes utilitaires privées pour la gestion d'état
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