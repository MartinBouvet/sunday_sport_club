import 'package:flutter/material.dart';
import '../../data/models/progress_tracking.dart';
import '../../domain/services/progress_service.dart';

class ProgressProvider extends ChangeNotifier {
  final ProgressService _progressService = ProgressService();

  ProgressTracking? _latestProgress;
  List<ProgressTracking> _progressHistory = [];
  bool _isLoading = false;
  String? _errorMessage;

  ProgressTracking? get latestProgress => _latestProgress;
  List<ProgressTracking> get progressHistory => _progressHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> fetchLatestProgress(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _latestProgress = await _progressService.getLatestProgress(userId);
      _setLoading(false);
    } catch (e) {
      _setError(
        'Erreur lors de la récupération des données de progression: ${e.toString()}',
      );
    }
  }

  Future<void> fetchProgressHistory(String userId) async {
    _setLoading(true);
    _clearError();

    try {
      _progressHistory = await _progressService.getProgressHistory(userId);
      _setLoading(false);
    } catch (e) {
      _setError(
        'Erreur lors de la récupération de l\'historique de progression: ${e.toString()}',
      );
    }
  }

  Future<bool> saveProgress({
    required String userId,
    required double weight,
    required int endurance,
    required int strength,
    String? notes,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _progressService.recordProgress(
        userId,
        weight: weight,
        endurance: endurance,
        strength: strength,
        notes: notes,
      );

      // Recharger les données
      await fetchLatestProgress(userId);

      _setLoading(false);
      return true;
    } catch (e) {
      _setError(
        'Erreur lors de l\'enregistrement de la progression: ${e.toString()}',
      );
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
