import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user.dart' as app_models;
import '../../core/utils/supabase_client.dart';

class AuthService {
  final UserRepository _userRepository = UserRepository();

  // Vérifier si utilisateur est connecté
  bool get isLoggedIn => supabase.auth.currentUser != null;

  // Vérifier validité session
  Future<bool> isSessionValid() async {
    try {
      final session = supabase.auth.currentSession;
      if (session == null) return false;

      // Vérifier expiration
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      if (session.expiresAt != null && session.expiresAt! < now) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Récupérer utilisateur actuel
  Future<app_models.User?> getCurrentUser() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId != null) {
      return await _userRepository.getUser(userId);
    }
    return null;
  }

  // Inscription nouvel utilisateur
  Future<app_models.User?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String gender = 'homme',
    String skinColor = 'blanc',
  }) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        final userId = response.user!.id;

        await _userRepository.createUser(
          id: userId,
          email: email,
          firstName: firstName,
          lastName: lastName,
          gender: gender,
          skinColor: skinColor,
        );

        return await _userRepository.getUser(userId);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Connexion utilisateur
  Future<app_models.User?> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await _userRepository.getUser(response.user!.id);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Déconnexion utilisateur
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // Mot de passe oublié
  Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }
}
