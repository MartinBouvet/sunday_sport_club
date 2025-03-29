import 'package:flutter/material.dart';
import '../../data/models/daily_challenge.dart';
import '../../data/models/user_challenge.dart';
import '../../data/repositories/challenge_repository.dart';

class ChallengeProvider extends ChangeNotifier {
  final ChallengeRepository _challengeRepository = ChallengeRepository();

  DailyChallenge? _dailyChallenge;
  List<UserChallenge> _userChallenges = [];
  List<DailyChallenge> _allChallenges = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Accesseurs publics
  DailyChallenge? get dailyChallenge => _dailyChallenge;
  List<UserChallenge> get userChallenges => _userChallenges;
  List<DailyChallenge> get allChallenges => _allChallenges;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Récupération d'un défi spécifique par son ID
  Future<DailyChallenge?> getChallenge(String challengeId) async {
    _isLoading = true;
    _errorMessage = null;

    try {
      // D'abord, vérifier dans la liste déjà chargée
      DailyChallenge? challenge;
      try {
        challenge = _allChallenges.firstWhere((c) => c.id == challengeId);
      } catch (_) {
        challenge = await _challengeRepository.getChallenge(challengeId);
      }

      _isLoading = false;
      notifyListeners();
      return challenge;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement du défi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Récupération du défi quotidien
  Future<void> fetchDailyChallenge() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final today = DateTime.now();
      _dailyChallenge = await _challengeRepository.getDailyChallenge(today);

      // Si aucun défi quotidien n'est trouvé, charger tous les défis
      if (_dailyChallenge == null) {
        await fetchAllChallenges();

        // Essayer de trouver un défi pour aujourd'hui
        final todayFormatted = DateTime(today.year, today.month, today.day);
        try {
          _dailyChallenge = _allChallenges.firstWhere((challenge) {
            final challengeDate = DateTime(
              challenge.date.year,
              challenge.date.month,
              challenge.date.day,
            );
            return challengeDate.isAtSameMomentAs(todayFormatted);
          });
        } catch (_) {
          // Si aucun défi trouvé pour aujourd'hui, prendre le premier si disponible
          if (_allChallenges.isNotEmpty) {
            _dailyChallenge = _allChallenges.first;
          }
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage =
          'Erreur lors de la récupération du défi quotidien: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Récupération de tous les défis
  Future<void> fetchAllChallenges() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allChallenges = await _challengeRepository.getAllChallenges();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage =
          'Erreur lors de la récupération des défis: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Récupération des défis de l'utilisateur
  Future<void> fetchUserChallenges(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userChallenges = await _challengeRepository.getUserChallenges(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage =
          'Erreur lors de la récupération des défis utilisateur: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Vérification si un défi est complété
  bool isChallengeCompleted(String challengeId) {
    return _userChallenges.any(
      (userChallenge) =>
          userChallenge.challengeId == challengeId &&
          userChallenge.status == 'completed',
    );
  }

  // Complétion d'un défi
  Future<bool> completeChallenge(String challengeId, String userId) async {
    // Validation des entrées
    if (challengeId.isEmpty || userId.isEmpty) {
      _errorMessage = 'Identifiants de défi ou d\'utilisateur invalides';
      notifyListeners();
      return false;
    }

    // Vérification si déjà complété
    if (isChallengeCompleted(challengeId)) {
      return true; // Déjà complété
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Créer un nouvel objet UserChallenge
      final userChallenge = UserChallenge(
        id: 'uc-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        challengeId: challengeId,
        assignedDate: DateTime.now(),
        status: 'completed',
        completionDate: DateTime.now(),
      );

      // Assigner le défi à l'utilisateur
      final newChallengeId = await _challengeRepository.assignChallengeToUser(
        userChallenge,
      );

      // Marquer comme terminé
      await _challengeRepository.updateUserChallengeStatus(
        newChallengeId,
        'completed',
      );

      // Mise à jour locale
      _userChallenges.add(userChallenge);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la complétion du défi: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Récupérer les défis à venir
  Future<List<DailyChallenge>> getUpcomingChallenges() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_allChallenges.isEmpty) {
      await fetchAllChallenges();
    }

    return _allChallenges.where((challenge) {
      final challengeDate = DateTime(
        challenge.date.year,
        challenge.date.month,
        challenge.date.day,
      );
      return challengeDate.isAfter(today);
    }).toList();
  }

  // Récupérer les défis passés
  Future<List<DailyChallenge>> getPastChallenges() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_allChallenges.isEmpty) {
      await fetchAllChallenges();
    }

    return _allChallenges.where((challenge) {
      final challengeDate = DateTime(
        challenge.date.year,
        challenge.date.month,
        challenge.date.day,
      );
      return challengeDate.isBefore(today);
    }).toList();
  }
}
