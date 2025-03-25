import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/datasources/supabase/supabase_auth_datasource.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user.dart';

class AuthService {
  final SupabaseAuthDatasource _authDatasource = SupabaseAuthDatasource();
  final UserRepository _userRepository = UserRepository();

  // Get the current authenticated user's ID
  String? get currentUserId => _authDatasource.currentUser?.id;

  // Check if user is logged in
  bool get isLoggedIn => _authDatasource.currentUser != null;

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
    // Implementation depends on Supabase's password update mechanism
    // You may need to add this method to your SupabaseAuthDatasource
  }

  // Request password reset email
  Future<void> resetPassword(String email) async {
    // Implementation depends on Supabase's password reset mechanism
    // You may need to add this method to your SupabaseAuthDatasource
  }
}