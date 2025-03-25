import 'package:flutter/material.dart';
import 'package:sunday_sport_club/data/models/daily_challenge.dart';
import 'package:sunday_sport_club/data/models/user_challenge.dart';
import 'package:sunday_sport_club/data/repositories/challenge_repository.dart';
import 'package:sunday_sport_club/domain/services/gamification_service.dart';
import 'package:sunday_sport_club/presentation/providers/user_provider.dart';

/// Provider responsable de la gestion des défis quotidiens et des défis utilisateur.
///
/// Maintient l'état des défis quotidiens, des défis de l'utilisateur, et fournit
/// des méthodes pour récupérer, compléter et valider les défis.
class ChallengeProvider extends ChangeNotifier {
  final ChallengeRepository _challengeRepository;
  final GamificationService _gamificationService;
  final UserProvider _userProvider;

  DailyChallenge? _dailyChallenge;
  List<UserChallenge> _userChallenges = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Constructeur qui nécessite les dépendances pour fonctionner
  ChallengeProvider({
    required ChallengeRepository challengeRepository,
    required GamificationService gamificationService,
    required UserProvider userProvider,
  })  : _challengeRepository = challengeRepository,
        _gamificationService = gamificationService,
        _userProvider = userProvider;

  // Getters
  DailyChallenge? get dailyChallenge => _dailyChallenge;
  List<UserChallenge> get userChallenges => _userChallenges;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Récupère le défi quotidien actuel depuis le repository
  Future<void> fetchDailyChallenge() async {
    _setLoading(true);
    _clearError();

    try {
      // Obtenir la date du jour
      final today = DateTime.now();
      final formattedDate = DateTime(today.year, today.month, today.day);

      // Récupérer le défi quotidien
      _dailyChallenge = await _challengeRepository.getDailyChallenge(formattedDate);
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération du défi quotidien: ${e.toString()}');
    }
  }

  /// Récupère tous les défis de l'utilisateur spécifié
  Future<void> fetchUserChallenges(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _userChallenges = await _challengeRepository.getUserChallenges(userId);
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des défis utilisateur: ${e.toString()}');
    }
  }

  /// Indique si un défi spécifique a été complété par l'utilisateur
  bool isChallengeCompleted(String challengeId) {
    return _userChallenges.any(
      (userChallenge) => 
        userChallenge.challengeId == challengeId && 
        userChallenge.isCompleted
    );
  }

  /// Marque un défi comme complété par l'utilisateur et attribue les points d'expérience
  Future<void> completeChallenge(String challengeId, String userId) async {
    if (challengeId.isEmpty || userId.isEmpty) {
      _setError('Identifiants de défi ou d\'utilisateur invalides');
      return;
    }

    // Vérifier si le défi est déjà complété
    if (isChallengeCompleted(challengeId)) {
      return; // Défi déjà complété, ne rien faire
    }

    _setLoading(true);
    _clearError();

    try {
      // Création d'un nouvel objet UserChallenge pour le défi complété
      final userChallenge = UserChallenge(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // ID temporaire, sera remplacé par le repository
        userId: userId,
        challengeId: challengeId,
        isCompleted: true,
        completedDate: DateTime.now(),
      );

      // Enregistrement du défi complété
      await _challengeRepository.saveUserChallenge(userChallenge);

      // Mettre à jour la liste locale des défis utilisateur
      _userChallenges.add(userChallenge);

      // Si le défi quotidien existe et correspond à l'ID complété
      if (_dailyChallenge != null && _dailyChallenge!.id == challengeId) {
        // Attribuer les points d'expérience à l'utilisateur
        await _gamificationService.awardExperiencePoints(
          userId: userId,
          points: _dailyChallenge!.experiencePoints,
          source: 'Défi quotidien: ${_dailyChallenge!.title}',
        );

        // Mettre à jour les points d'expérience dans le UserProvider
        await _userProvider.addExperiencePoints(_dailyChallenge!.experiencePoints);

        // Vérifier si un badge doit être attribué (logique simplifiée)
        final completedChallengesCount = _userChallenges.where((uc) => uc.isCompleted).length;
        if (completedChallengesCount == 5) {
          await _userProvider.addAchievement('5 défis complétés');
        } else if (completedChallengesCount == 10) {
          await _userProvider.addAchievement('10 défis complétés');
        } else if (completedChallengesCount == 25) {
          await _userProvider.addAchievement('25 défis complétés');
        }
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la complétion du défi: ${e.toString()}');
    }
  }

  /// Récupère les défis hebdomadaires
  Future<List<DailyChallenge>> fetchWeeklyChallenges() async {
    _setLoading(true);
    _clearError();

    try {
      // Obtenir les dates de la semaine actuelle
      final today = DateTime.now();
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      
      final weeklyChallenges = <DailyChallenge>[];
      
      // Récupérer les défis pour chaque jour de la semaine
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));
        final challenge = await _challengeRepository.getDailyChallenge(date);
        if (challenge != null) {
          weeklyChallenges.add(challenge);
        }
      }
      
      _setLoading(false);
      return weeklyChallenges;
    } catch (e) {
      _setError('Erreur lors de la récupération des défis hebdomadaires: ${e.toString()}');
      return [];
    }
  }

  /// Génère un nouveau défi pour le jour spécifié (fonction admin)
  Future<void> generateChallenge(DateTime date, DailyChallenge challenge) async {
    _setLoading(true);
    _clearError();

    try {
      await _challengeRepository.createDailyChallenge(challenge);
      
      // Si la date est aujourd'hui, mettre à jour le défi quotidien dans le provider
      final today = DateTime.now();
      if (date.year == today.year && date.month == today.month && date.day == today.day) {
        _dailyChallenge = challenge;
      }
      
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la génération du défi: ${e.toString()}');
    }
  }

  // Méthodes utilitaires privées pour la gestion d'état
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