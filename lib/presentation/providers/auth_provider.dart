import 'package:flutter/material.dart';
import '../../domain/services/auth_service.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/datasources/supabase/shared_prefs_helper.dart';
import '../../presentation/screens/auth/login_screen.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();

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

    try {
      // Initialiser les préférences partagées
      await SharedPrefsHelper.init();
      
      // Vérifier si une session est valide
      final isValid = await _authService.isSessionValid();

      if (isValid) {
        await _loadUserData();
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Erreur d'initialisation AuthProvider: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<User?> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        
        // Sauvegarder le rôle dans les préférences pour référence rapide
        if (user.role != null) {
          await SharedPrefsHelper.saveUserRole(user.role);
        }
        
        debugPrint("Utilisateur chargé avec succès. Rôle: ${user.role}");
        notifyListeners();
        return user;
      }
    } catch (e) {
      _errorMessage = "Erreur lors du chargement des données utilisateur: ${e.toString()}";
      debugPrint(_errorMessage);
    }
    return null;
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      
      if (user != null) {
        _currentUser = user;
        
        // Vérifier et logger le rôle de l'utilisateur
        debugPrint("Connexion réussie - Rôle utilisateur: ${user.role}");
        
        // Sauvegarder les infos utilisateur
        await SharedPrefsHelper.saveUserId(user.id);
        await SharedPrefsHelper.saveUserEmail(user.email);
        await SharedPrefsHelper.saveUserName('${user.firstName} ${user.lastName}');
        await SharedPrefsHelper.saveUserRole(user.role);
        
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
      debugPrint("Erreur de connexion: $_errorMessage");
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
        
        // Sauvegarder les infos utilisateur
        await SharedPrefsHelper.saveUserId(user.id);
        await SharedPrefsHelper.saveUserEmail(user.email);
        await SharedPrefsHelper.saveUserName('${user.firstName} ${user.lastName}');
        await SharedPrefsHelper.saveUserRole(user.role); // Rôle 'user' par défaut
        
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

  Future<bool> logout([BuildContext? context]) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      
      // Effacer les données locales
      await SharedPrefsHelper.clearAuthData();
      
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      
      // Si un contexte est fourni, rediriger vers l'écran de connexion
      if (context != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false, // Supprime toutes les routes de l'historique
        );
      }
      
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint("Erreur de déconnexion: $_errorMessage");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Charge ou rafraîchit les données de l'utilisateur depuis le serveur
  Future<void> loadUserData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _loadUserData();
    } catch (e) {
      _errorMessage = "Erreur lors du chargement des données utilisateur: ${e.toString()}";
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rafraîchit les données de l'utilisateur
  Future<void> refreshUserData() async {
    if (!isAuthenticated) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final userId = _currentUser!.id;
      _currentUser = await _userRepository.getUser(userId);
      
      if (_currentUser != null) {
        debugPrint("Données utilisateur rafraîchies - Rôle: ${_currentUser!.role}");
        await SharedPrefsHelper.saveUserRole(_currentUser!.role);
      }
    } catch (e) {
      _errorMessage = "Erreur lors du rafraîchissement des données: ${e.toString()}";
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}