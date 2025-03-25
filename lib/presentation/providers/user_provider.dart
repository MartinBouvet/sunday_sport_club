import 'package:flutter/material.dart';
import '../../data/models/user.dart';
import '../../domain/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> fetchCurrentUser() async {
    _setLoading(true);
    _clearError();

    try {
      _currentUser = await _userService.getUserById(
        'current_user_id',
      ); // Remplacer par la logique réelle
      _setLoading(false);
    } catch (e) {
      _setError(
        'Erreur lors de la récupération des données utilisateur: ${e.toString()}',
      );
    }
  }

  Future<bool> updateUserProperties({
    double? weight,
    int? endurance,
    int? strength,
  }) async {
    if (_currentUser == null) {
      _setError('Aucun utilisateur connecté');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _userService.updateUserStats(
        _currentUser!.id,
        weight: weight,
        endurance: endurance,
        strength: strength,
      );

      // Mettre à jour l'utilisateur courant
      await fetchCurrentUser();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour: ${e.toString()}');
      return false;
    }
  }

  Future<bool> addExperiencePoints(int points) async {
    if (_currentUser == null) {
      _setError('Aucun utilisateur connecté');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _userService.addExperiencePoints(_currentUser!.id, points);
      await fetchCurrentUser();
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'ajout des points: ${e.toString()}');
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
