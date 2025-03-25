import 'package:flutter/material.dart';
import 'package:sunday_sport_club/domain/services/auth_service.dart';
import 'package:sunday_sport_club/core/errors/exceptions.dart';
import 'package:sunday_sport_club/presentation/providers/user_provider.dart';

/// Provider responsable de la gestion de l'authentification dans l'application.
///
/// Gère les processus de connexion, d'inscription, de réinitialisation de mot de passe,
/// et maintient l'état d'authentification.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UserProvider _userProvider;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  /// Constructeur qui nécessite une instance d'AuthService et de UserProvider
  AuthProvider({
    required AuthService authService,
    required UserProvider userProvider,
  })  : _authService = authService,
        _userProvider = userProvider {
    // Initialisation: vérifier s'il y a une session active
    _checkCurrentSession();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  /// Vérifie si une session d'authentification est active au démarrage
  Future<void> _checkCurrentSession() async {
    _setLoading(true);
    
    try {
      final isValid = await _authService.isSessionValid();
      _isAuthenticated = isValid;
      
      if (isValid) {
        await _userProvider.fetchCurrentUser();
      }
      
      _setLoading(false);
    } catch (e) {
      _isAuthenticated = false;
      _setError('Erreur lors de la vérification de la session: ${e.toString()}');
    }
  }

  /// Connecte un utilisateur avec son email et mot de passe
  Future<bool> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _setError('Email et mot de passe sont requis');
      return false;
    }
    
    _setLoading(true);
    _clearMessages();
    
    try {
      final success = await _authService.login(email, password);
      
      if (success) {
        _isAuthenticated = true;
        await _userProvider.fetchCurrentUser();
        _setSuccess('Connexion réussie');
      } else {
        _setError('Échec de la connexion');
      }
      
      return success;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Erreur lors de la connexion: ${e.toString()}');
      return false;
    }
  }

  /// Inscrit un nouvel utilisateur
  Future<bool> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required DateTime birthDate,
    required String gender,
    required String skinColor,
  }) async {
    if (email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      _setError('Tous les champs obligatoires doivent être remplis');
      return false;
    }
    
    _setLoading(true);
    _clearMessages();
    
    try {
      final success = await _authService.signup(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        birthDate: birthDate,
        gender: gender,
        skinColor: skinColor,
      );
      
      if (success) {
        _isAuthenticated = true;
        await _userProvider.fetchCurrentUser();
        _setSuccess('Inscription réussie');
      } else {
        _setError('Échec de l\'inscription');
      }
      
      return success;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Erreur lors de l\'inscription: ${e.toString()}');
      return false;
    }
  }

  /// Déconnecte l'utilisateur actuel
  Future<bool> logout() async {
    _setLoading(true);
    _clearMessages();
    
    try {
      final success = await _authService.logout();
      
      if (success) {
        _isAuthenticated = false;
        await _userProvider.logout();
        _setSuccess('Déconnexion réussie');
      } else {
        _setError('Échec de la déconnexion');
      }
      
      return success;
    } catch (e) {
      _setError('Erreur lors de la déconnexion: ${e.toString()}');
      return false;
    }
  }

  /// Envoie un email de réinitialisation de mot de passe
  Future<bool> resetPasswordRequest(String email) async {
    if (email.isEmpty) {
      _setError('Email requis');
      return false;
    }
    
    _setLoading(true);
    _clearMessages();
    
    try {
      final success = await _authService.resetPasswordRequest(email);
      
      if (success) {
        _setSuccess('Email de réinitialisation envoyé');
      } else {
        _setError('Échec de l\'envoi de l\'email de réinitialisation');
      }
      
      return success;
    } catch (e) {
      _setError('Erreur lors de la demande de réinitialisation: ${e.toString()}');
      return false;
    }
  }

  /// Réinitialise le mot de passe avec un token de réinitialisation
  Future<bool> resetPassword(String token, String newPassword) async {
    if (token.isEmpty || newPassword.isEmpty) {
      _setError('Token et nouveau mot de passe requis');
      return false;
    }
    
    _setLoading(true);
    _clearMessages();
    
    try {
      final success = await _authService.resetPassword(token, newPassword);
      
      if (success) {
        _setSuccess('Mot de passe réinitialisé avec succès');
      } else {
        _setError('Échec de la réinitialisation du mot de passe');
      }
      
      return success;
    } catch (e) {
      _setError('Erreur lors de la réinitialisation du mot de passe: ${e.toString()}');
      return false;
    }
  }

  /// Modifie le mot de passe de l'utilisateur connecté
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (!_isAuthenticated) {
      _setError('Utilisateur non connecté');
      return false;
    }
    
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      _setError('Mot de passe actuel et nouveau mot de passe requis');
      return false;
    }
    
    _setLoading(true);
    _clearMessages();
    
    try {
      final success = await _authService.changePassword(currentPassword, newPassword);
      
      if (success) {
        _setSuccess('Mot de passe modifié avec succès');
      } else {
        _setError('Échec de la modification du mot de passe');
      }
      
      return success;
    } catch (e) {
      _setError('Erreur lors de la modification du mot de passe: ${e.toString()}');
      return false;
    }
  }

  /// Met à jour le profil de l'utilisateur avec authentification
  Future<bool> updateUserProfile({
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? gender,
    String? skinColor,
  }) async {
    if (!_isAuthenticated) {
      _setError('Utilisateur non connecté');
      return false;
    }
    
    _setLoading(true);
    _clearMessages();
    
    try {
      final user = _userProvider.currentUser;
      if (user == null) {
        _setError('Données utilisateur non disponibles');
        return false;
      }
      
      final success = await _authService.updateUserProfile(
        userId: user.id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        gender: gender,
        skinColor: skinColor,
      );
      
      if (success) {
        // Rafraîchir les données utilisateur
        await _userProvider.fetchCurrentUser();
        _setSuccess('Profil mis à jour avec succès');
      } else {
        _setError('Échec de la mise à jour du profil');
      }
      
      return success;
    } catch (e) {
      _setError('Erreur lors de la mise à jour du profil: ${e.toString()}');
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