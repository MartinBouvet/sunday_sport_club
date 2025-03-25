import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_auth;

import '../../data/repositories/auth_repository.dart';
import '../../domain/services/auth_service.dart';
import '../../data/models/user.dart' as app_models;
import '../../data/datasources/local/shared_prefs_helper.dart';
import '../../core/utils/supabase_client.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AuthRepository _authRepository = AuthRepository();
  
  app_models.User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isAuthenticated => _authRepository.currentUser != null;
  
  // Vérification complète de la validité de la session (synchrone + asynchrone)
  Future<bool> isSessionValid() async {
    return await _authService.isSessionValid();
  }
  app_models.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdmin => _currentUser?.role == 'admin';
  
  AuthProvider() {
    _init();
  }
  
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    
    // Vérification complète de la validité de la session
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
      // Save user ID to shared preferences for quick access
      await SharedPrefsHelper.saveUserId(user.id);
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
        await SharedPrefsHelper.saveUserId(user.id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Failed to login. Please check your credentials.";
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
        await SharedPrefsHelper.saveUserId(user.id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "Failed to register. Please try again.";
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
      await SharedPrefsHelper.clearAuthData();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await supabase.auth.resetPasswordForEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}