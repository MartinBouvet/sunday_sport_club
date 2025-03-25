import 'package:flutter/material.dart';
import 'package:sunday_sport_club/data/models/progress_tracking.dart';
import 'package:sunday_sport_club/data/repositories/progress_repository.dart';
import 'package:sunday_sport_club/domain/services/progress_service.dart';
import 'package:sunday_sport_club/presentation/providers/user_provider.dart';

/// Provider responsable de la gestion de la progression de l'utilisateur.
///
/// Maintient l'état des données de progression, de l'historique de progression,
/// et fournit des méthodes pour récupérer et mettre à jour ces données.
class ProgressProvider extends ChangeNotifier {
  final ProgressRepository _progressRepository;
  final ProgressService _progressService;
  final UserProvider _userProvider;

  ProgressTracking? _latestProgress;
  List<ProgressTracking> _progressHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  /// Constructeur qui nécessite les dépendances pour fonctionner
  ProgressProvider({
    required ProgressRepository progressRepository,
    required ProgressService progressService,
    required UserProvider userProvider,
  })  : _progressRepository = progressRepository,
        _progressService = progressService,
        _userProvider = userProvider;

  // Getters
  ProgressTracking? get latestProgress => _latestProgress;
  List<ProgressTracking> get progressHistory => _progressHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Récupère la dernière entrée de progression pour l'utilisateur actuel
  Future<void> fetchLatestProgress() async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      _latestProgress = await _progressRepository.getLatestProgress(user.id);
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des données de progression: ${e.toString()}');
    }
  }

  /// Récupère l'historique complet de progression pour l'utilisateur actuel
  Future<void> fetchProgressHistory() async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Récupérer l'historique des 30 derniers jours par défaut
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));
      
      _progressHistory = await _progressRepository.getProgressHistory(
        user.id,
        startDate,
        endDate,
      );
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération de l\'historique de progression: ${e.toString()}');
    }
  }

  /// Récupère l'historique de progression pour une période spécifique
  Future<List<ProgressTracking>> fetchProgressHistoryForPeriod(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return [];
    }

    _setLoading(true);
    _clearError();

    try {
      final history = await _progressRepository.getProgressHistory(
        user.id,
        startDate,
        endDate,
      );
      _setLoading(false);
      return history;
    } catch (e) {
      _setError('Erreur lors de la récupération de l\'historique pour la période: ${e.toString()}');
      return [];
    }
  }

  /// Enregistre une nouvelle entrée de progression pour l'utilisateur actuel
  Future<void> saveProgress({
    required double weight,
    required int endurance,
    required int strength,
    String? notes,
  }) async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Créer une nouvelle entrée de progression
      final newProgress = ProgressTracking(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // ID temporaire, sera remplacé par le repository
        userId: user.id,
        date: DateTime.now(),
        weight: weight,
        endurance: endurance,
        strength: strength,
        notes: notes ?? '',
      );

      // Enregistrer dans le repository
      final savedProgress = await _progressRepository.saveProgress(newProgress);
      
      // Mise à jour de l'état local
      _latestProgress = savedProgress;
      
      // Si l'historique a été chargé, l'ajouter aussi à l'historique
      if (_progressHistory.isNotEmpty) {
        _progressHistory.insert(0, savedProgress);
      }
      
      // Mise à jour des statistiques de l'utilisateur si nécessaire
      await _syncUserStats(weight, endurance, strength);

      // Vérifier si des badges doivent être attribués
      await _checkForAchievements(weight, endurance, strength);
      
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de l\'enregistrement de la progression: ${e.toString()}');
    }
  }

  /// Analyse la progression pour détecter les tendances significatives
  Future<Map<String, dynamic>> analyzeProgress() async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return {};
    }

    if (_progressHistory.length < 2) {
      await fetchProgressHistory();
      
      if (_progressHistory.length < 2) {
        return {
          'insufficientData': true,
          'message': 'Pas assez de données pour l\'analyse'
        };
      }
    }

    // Analyse basique des tendances
    final weightTrend = _calculateTrend(_progressHistory.map((p) => p.weight).toList());
    final enduranceTrend = _calculateTrend(_progressHistory.map((p) => p.endurance.toDouble()).toList());
    final strengthTrend = _calculateTrend(_progressHistory.map((p) => p.strength.toDouble()).toList());

    // Calcul des valeurs moyennes, min et max
    final weightStats = _calculateStats(_progressHistory.map((p) => p.weight).toList());
    final enduranceStats = _calculateStats(_progressHistory.map((p) => p.endurance.toDouble()).toList());
    final strengthStats = _calculateStats(_progressHistory.map((p) => p.strength.toDouble()).toList());
    
    return {
      'trends': {
        'weight': weightTrend,
        'endurance': enduranceTrend,
        'strength': strengthTrend,
      },
      'stats': {
        'weight': weightStats,
        'endurance': enduranceStats,
        'strength': strengthStats,
      },
    };
  }

  /// Met à jour les statistiques de l'utilisateur si nécessaire
  Future<void> _syncUserStats(double weight, int endurance, int strength) async {
    final user = _userProvider.currentUser;
    if (user == null) return;

    // Vérifier si les valeurs ont changé
    bool hasChanged = false;
    
    if (user.weight != weight) hasChanged = true;
    if (user.endurance != endurance) hasChanged = true;
    if (user.strength != strength) hasChanged = true;

    // Si au moins une valeur a changé, mettre à jour l'utilisateur
    if (hasChanged) {
      await _userProvider.updateUserProperties(
        weight: weight,
        endurance: endurance,
        strength: strength,
      );
    }
  }

  /// Vérifie si des badges doivent être attribués en fonction de la progression
  Future<void> _checkForAchievements(double weight, int endurance, int strength) async {
    final user = _userProvider.currentUser;
    if (user == null) return;

    // Exemple de règles d'attribution de badges
    if (_progressHistory.length >= 10) {
      await _userProvider.addAchievement('10 jours de suivi');
    }
    
    if (endurance >= 50 && strength >= 50) {
      await _userProvider.addAchievement('Équilibré');
    }
    
    if (user.initialWeight > 0 && weight < user.initialWeight * 0.9) {
      await _userProvider.addAchievement('Perte de poids');
    }
    
    if (endurance >= 75) {
      await _userProvider.addAchievement('Endurant');
    }
    
    if (strength >= 75) {
      await _userProvider.addAchievement('Fort');
    }
  }

  /// Calcule la tendance d'une série de valeurs (positive, négative ou stable)
  String _calculateTrend(List<double> values) {
    if (values.length < 2) return 'stable';
    
    // Utiliser les 7 dernières valeurs maximum pour la tendance récente
    final recentValues = values.length > 7 
        ? values.sublist(0, 7) 
        : values;
    
    // Calculer la différence entre la dernière et la première valeur
    final firstValue = recentValues.last;
    final lastValue = recentValues.first;
    final difference = lastValue - firstValue;
    
    // Déterminer la tendance en fonction de la différence
    if (difference > firstValue * 0.05) {
      return 'positive';
    } else if (difference < -firstValue * 0.05) {
      return 'négative';
    } else {
      return 'stable';
    }
  }

  /// Calcule les statistiques (moyenne, min, max) pour une série de valeurs
  Map<String, double> _calculateStats(List<double> values) {
    if (values.isEmpty) {
      return {
        'average': 0,
        'min': 0,
        'max': 0,
      };
    }
    
    double sum = 0;
    double min = values[0];
    double max = values[0];
    
    for (final value in values) {
      sum += value;
      if (value < min) min = value;
      if (value > max) max = value;
    }
    
    return {
      'average': sum / values.length,
      'min': min,
      'max': max,
    };
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