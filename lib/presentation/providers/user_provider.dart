import 'package:flutter/material.dart';
import 'package:sunday_sport_club/data/models/user.dart';
import 'package:sunday_sport_club/domain/services/user_service.dart';
import 'package:sunday_sport_club/core/errors/exceptions.dart';

/// Provider responsable de la gestion de l'état lié à l'utilisateur.
///
/// Maintient les données utilisateur actuelles et fournit des méthodes
/// pour récupérer, mettre à jour et gérer l'état de l'utilisateur.
class UserProvider extends ChangeNotifier {
  final UserService _userService;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  /// Constructeur qui nécessite une instance de UserService
  UserProvider({required UserService userService}) : _userService = userService;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Récupère l'utilisateur actuellement connecté depuis le service
  Future<void> fetchCurrentUser() async {
    _setLoading(true);
    _clearError();
    
    try {
      _currentUser = await _userService.getCurrentUser();
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des données utilisateur: ${e.toString()}');
    }
  }

  /// Met à jour les informations de l'utilisateur actuel
  Future<void> updateUser(User updatedUser) async {
    _setLoading(true);
    _clearError();
    
    try {
      final updatedUserData = await _userService.updateUser(updatedUser);
      _currentUser = updatedUserData;
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la mise à jour de l\'utilisateur: ${e.toString()}');
    }
  }

  /// Met à jour uniquement certaines propriétés spécifiques de l'utilisateur
  Future<void> updateUserProperties({
    double? weight,
    int? endurance,
    int? strength,
  }) async {
    if (_currentUser == null) {
      _setError('Aucun utilisateur connecté');
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final updatedUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        phone: _currentUser!.phone,
        birthDate: _currentUser!.birthDate,
        gender: _currentUser!.gender,
        skinColor: _currentUser!.skinColor,
        isActive: _currentUser!.isActive,
        role: _currentUser!.role,
        level: _currentUser!.level,
        experiencePoints: _currentUser!.experiencePoints,
        avatarStage: _currentUser!.avatarStage,
        weight: weight ?? _currentUser!.weight,
        initialWeight: _currentUser!.initialWeight,
        endurance: endurance ?? _currentUser!.endurance,
        strength: strength ?? _currentUser!.strength,
        achievements: _currentUser!.achievements,
        ranking: _currentUser!.ranking,
        createdAt: _currentUser!.createdAt,
        lastLogin: _currentUser!.lastLogin,
      );
      
      await updateUser(updatedUser);
    } catch (e) {
      _setError('Erreur lors de la mise à jour des propriétés: ${e.toString()}');
    }
  }

  /// Ajoute des points d'expérience à l'utilisateur et met à jour son niveau si nécessaire
  Future<void> addExperiencePoints(int points) async {
    if (_currentUser == null) {
      _setError('Aucun utilisateur connecté');
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final newExperiencePoints = _currentUser!.experiencePoints + points;
      
      // Vérifier si l'utilisateur monte de niveau
      int newLevel = _currentUser!.level;
      String newAvatarStage = _currentUser!.avatarStage;
      
      // Logique simplifiée pour déterminer le niveau en fonction des XP
      // À ajuster selon les règles métier spécifiques
      if (newExperiencePoints >= 1000 && newLevel < 10) {
        newLevel = 10;
        newAvatarStage = 'musclé';
      } else if (newExperiencePoints >= 500 && newLevel < 5) {
        newLevel = 5;
        newAvatarStage = 'moyen';
      }
      
      final updatedUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        phone: _currentUser!.phone,
        birthDate: _currentUser!.birthDate,
        gender: _currentUser!.gender,
        skinColor: _currentUser!.skinColor,
        isActive: _currentUser!.isActive,
        role: _currentUser!.role,
        level: newLevel,
        experiencePoints: newExperiencePoints,
        avatarStage: newAvatarStage,
        weight: _currentUser!.weight,
        initialWeight: _currentUser!.initialWeight,
        endurance: _currentUser!.endurance,
        strength: _currentUser!.strength,
        achievements: _currentUser!.achievements,
        ranking: _currentUser!.ranking,
        createdAt: _currentUser!.createdAt,
        lastLogin: _currentUser!.lastLogin,
      );
      
      await updateUser(updatedUser);
    } catch (e) {
      _setError('Erreur lors de l\'ajout de points d\'expérience: ${e.toString()}');
    }
  }

  /// Ajoute un badge aux réalisations de l'utilisateur
  Future<void> addAchievement(String achievement) async {
    if (_currentUser == null) {
      _setError('Aucun utilisateur connecté');
      return;
    }
    
    // Vérifier si l'utilisateur possède déjà ce badge
    if (_currentUser!.achievements.contains(achievement)) {
      return;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      final updatedAchievements = List<String>.from(_currentUser!.achievements);
      updatedAchievements.add(achievement);
      
      final updatedUser = User(
        id: _currentUser!.id,
        email: _currentUser!.email,
        firstName: _currentUser!.firstName,
        lastName: _currentUser!.lastName,
        phone: _currentUser!.phone,
        birthDate: _currentUser!.birthDate,
        gender: _currentUser!.gender,
        skinColor: _currentUser!.skinColor,
        isActive: _currentUser!.isActive,
        role: _currentUser!.role,
        level: _currentUser!.level,
        experiencePoints: _currentUser!.experiencePoints,
        avatarStage: _currentUser!.avatarStage,
        weight: _currentUser!.weight,
        initialWeight: _currentUser!.initialWeight,
        endurance: _currentUser!.endurance,
        strength: _currentUser!.strength,
        achievements: updatedAchievements,
        ranking: _currentUser!.ranking,
        createdAt: _currentUser!.createdAt,
        lastLogin: _currentUser!.lastLogin,
      );
      
      await updateUser(updatedUser);
    } catch (e) {
      _setError('Erreur lors de l\'ajout du badge: ${e.toString()}');
    }
  }

  /// Déconnecte l'utilisateur actuel
  Future<void> logout() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _userService.logout();
      _currentUser = null;
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la déconnexion: ${e.toString()}');
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