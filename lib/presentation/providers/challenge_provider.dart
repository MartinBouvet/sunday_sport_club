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

  // Accesseurs publics
  DailyChallenge? get dailyChallenge => _dailyChallenge;
  List<UserChallenge> get userChallenges => _userChallenges;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Récupération d'un défi spécifique par son ID
  Future<DailyChallenge?> getChallenge(String challengeId) async {
    // Mettre à jour l'état sans notifier (pour éviter une notification pendant le build)
    _isLoading = true;
    _errorMessage = null;
    
    try {
      // Obtenir le défi depuis le repository
      final challenge = await _challengeRepository.getChallenge(challengeId);
      
      // Mettre à jour l'état et notifier
      _isLoading = false;
      notifyListeners();
      return challenge;
    } catch (e) {
      // Gérer l'erreur, mettre à jour l'état et notifier
      _isLoading = false;
      _errorMessage = 'Erreur lors du chargement du défi: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }

  // Récupération du défi quotidien
  Future<void> fetchDailyChallenge() async {
    // Cette méthode sera appelée en dehors du build,
    // donc nous pouvons utiliser la notification standard
    _isLoading = true;
    _errorMessage = null;


    try {
      final today = DateTime.now();
      final formattedDate = DateTime(today.year, today.month, today.day);
      final dailyChallenge = await _challengeRepository.getDailyChallenge(formattedDate);
      
      // Mise à jour de l'état
      _dailyChallenge = dailyChallenge;
      _isLoading = false;
      
      // Notification après mise à jour complète de l'état
      notifyListeners();
    } catch (e) {
      // Gestion d'erreur
      _errorMessage = 'Erreur lors de la récupération du défi quotidien: ${e.toString()}';
      _isLoading = false;
      
      // Notification après mise à jour complète de l'état
      notifyListeners();
    }
  }

  // Récupération des défis de l'utilisateur
  Future<void> fetchUserChallenges(String userId) async {
    // Mise à jour de l'état sans notification immédiate
    _isLoading = true;
    _errorMessage = null;
    
    // Notification après mise à jour initiale de l'état
    notifyListeners();

    try {
      // Obtenir les défis utilisateur
      final challenges = await _challengeRepository.getUserChallenges(userId);
      
      // Mise à jour de l'état
      _userChallenges = challenges;
      _isLoading = false;
      
      // Notification après mise à jour complète
      notifyListeners();
    } catch (e) {
      // Gestion d'erreur
      _errorMessage = 'Erreur lors de la récupération des défis utilisateur: ${e.toString()}';
      _isLoading = false;
      
      // Notification après mise à jour complète
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
      return true; // Défi déjà complété
    }

    // Mise à jour de l'état
    _isLoading = true;
    _errorMessage = null;
    
    // Notification après mise à jour initiale
    notifyListeners();

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

      // Validation du défi via le repository
      await _challengeRepository.updateUserChallengeStatus(
        userChallenge.id,
        'completed',
      );

      // Mise à jour locale
      _userChallenges.add(userChallenge);
      _isLoading = false;
      
      // Notification après mise à jour complète
      notifyListeners();
      return true;
    } catch (e) {
      // Gestion d'erreur
      _errorMessage = 'Erreur lors de la complétion du défi: ${e.toString()}';
      _isLoading = false;
      
      // Notification après mise à jour complète
      notifyListeners();
      return false;
    }
  }
}