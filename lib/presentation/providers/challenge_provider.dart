import 'package:flutter/material.dart';
import '../../data/models/daily_challenge.dart';
import '../../data/models/user_challenge.dart';
import '../../data/repositories/challenge_repository.dart';

class ChallengeProvider extends ChangeNotifier {
  final ChallengeRepository _challengeRepository = ChallengeRepository();

  DailyChallenge? _dailyChallenge;
  List<UserChallenge> _userChallenges = [];
  bool _isLoading = false;
  String? _errorMessage;

  DailyChallenge? get dailyChallenge => _dailyChallenge;
  List<UserChallenge> get userChallenges => _userChallenges;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

Future<DailyChallenge?> getChallenge(String challengeId) async {
  _setLoading(true);
  _clearError();
  
  try {
    final challenge = await _challengeRepository.getChallenge(challengeId);
    _setLoading(false);
    return challenge;
  } catch (e) {
    _setError('Erreur lors du chargement du défi: ${e.toString()}');
    return null;
  }
}

  Future<void> fetchDailyChallenge() async {
    _setLoading(true);
    _clearError();

    try {
      final today = DateTime.now();
      final formattedDate = DateTime(today.year, today.month, today.day);
      _dailyChallenge = await _challengeRepository.getDailyChallenge(
        formattedDate,
      );
      _setLoading(false);
    } catch (e) {
      _setError(
        'Erreur lors de la récupération du défi quotidien: ${e.toString()}',
      );
    }
  }

  Future<void> fetchUserChallenges(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _userChallenges = await _challengeRepository.getUserChallenges(userId);
      _setLoading(false);
    } catch (e) {
      _setError(
        'Erreur lors de la récupération des défis utilisateur: ${e.toString()}',
      );
    }
  }

  bool isChallengeCompleted(String challengeId) {
    return _userChallenges.any(
      (userChallenge) =>
          userChallenge.challengeId == challengeId &&
          userChallenge.status == 'completed',
    );
  }

  Future<bool> completeChallenge(String challengeId, String userId) async {
    if (challengeId.isEmpty || userId.isEmpty) {
      _setError('Identifiants de défi ou d\'utilisateur invalides');
      return false;
    }

    if (isChallengeCompleted(challengeId)) {
      return true; // Défi déjà complété
    }

    _setLoading(true);
    _clearError();

    try {
      // Création d'un nouvel objet UserChallenge
      final userChallenge = UserChallenge(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        challengeId: challengeId,
        assignedDate: DateTime.now(),
        status: 'completed',
        completionDate: DateTime.now(),
      );

      // Validation du défi
      await _challengeRepository.updateUserChallengeStatus(
        userChallenge.id,
        'completed',
      );

      // Mettre à jour localement
      _userChallenges.add(userChallenge);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la complétion du défi: ${e.toString()}');
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
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
