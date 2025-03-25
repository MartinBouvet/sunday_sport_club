import 'package:supabase_flutter/supabase_flutter.dart' as supabase_auth;
import '../../data/datasources/supabase/supabase_auth_datasource.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user.dart';
import '../../core/utils/supabase_client.dart';

class AuthService {
  final SupabaseAuthDatasource _authDatasource = SupabaseAuthDatasource();
  final UserRepository _userRepository = UserRepository();

  // Get the current authenticated user's ID
  String? get currentUserId => _authDatasource.currentUser?.id;

  // Check if user is logged in
  bool get isLoggedIn => _authDatasource.currentUser != null;

  // Check if the current session is valid
  Future<bool> isSessionValid() async {
    try {
      // Check if there's a current session
      final session = supabase.auth.currentSession;
      if (session == null) {
        return false;
      }
      
      // Check if token is expired
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      if (session.expiresAt != null && session.expiresAt! < now) {
        return false;
      }
      
      // Optional: Perform a lightweight API call to verify the token is still accepted
      await supabase.auth.getUser();
      
      return true;
    } catch (e) {
      // If any error occurs, consider the session invalid
      return false;
    }
  }

  // Get the current authenticated user's data
  Future<User?> getCurrentUser() async {
    final userId = currentUserId;
    if (userId != null) {
      return await _userRepository.getUser(userId);
    }
    return null;
  }

  // Register a new user
  Future<User?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String gender = 'homme',
    String skinColor = 'blanc',
  }) async {
    try {
      // Register user with Supabase Auth
      final response = await _authDatasource.signUp(email, password);
      
      if (response.user != null) {
        final userId = response.user!.id;
        
        // Create user profile in the database
        await _userRepository.createUser(
          id: userId,
          email: email,
          firstName: firstName,
          lastName: lastName,
          gender: gender,
          skinColor: skinColor,
        );
        
        // Return the newly created user
        return await _userRepository.getUser(userId);
      }
      return null;
    } catch (e) {
      // Handle registration errors
      rethrow;
    }
  }

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      final response = await _authDatasource.signIn(email, password);
      
      if (response.user != null) {
        return await _userRepository.getUser(response.user!.id);
      }
      return null;
    } catch (e) {
      // Handle login errors
      rethrow;
    }
  }

  // Logout current user
  Future<void> logout() async {
    await _authDatasource.signOut();
  }

  // Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await supabase.auth.updateUser(
        supabase_auth.UserAttributes(
          password: newPassword,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Request password reset email
  Future<void> resetPassword(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }
}