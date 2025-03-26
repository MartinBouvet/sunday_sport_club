import 'package:flutter/material.dart';
import '../../domain/services/auth_service.dart';
import '../../data/models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _currentUser != null;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _currentUser?.role == 'admin';

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    final isValid = await _authService.isSessionValid();

    if (isValid) {
      await _loadUserData();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserData() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      _currentUser = user;
      notifyListeners();
    }
  }

  // Charge ou rafraîchit les données de l'utilisateur depuis le serveur
  /// Peut être appelée après la connexion initiale ou lorsque des données sont modifiées
  Future<void> loadUserData() async {
    if (!isAuthenticated) {
      _errorMessage = "Aucun utilisateur connecté";
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _loadUserData();
    } catch (e) {
      _errorMessage = "Erreur lors du chargement des données utilisateur: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Rafraîchit les données utilisateur depuis le serveur
  /// Utile après des mises à jour de profil ou autres modifications
  Future<void> refreshUserData() async {
    if (!isAuthenticated) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loadUserData();
    } catch (e) {
      _errorMessage = "Erreur lors du rafraîchissement des données: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Échec de connexion. Vérifiez vos identifiants.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String skinColor,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        skinColor: skinColor,
      );

      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Échec d'inscription. Veuillez réessayer.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}