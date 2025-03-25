import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase/supabase_auth_datasource.dart';

class AuthRepository {
  final SupabaseAuthDatasource _datasource = SupabaseAuthDatasource();

  Future<AuthResponse> signUp(String email, String password) async {
    return await _datasource.signUp(email, password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _datasource.signIn(email, password);
  }

  Future<void> signOut() async {
    await _datasource.signOut();
  }

  User? get currentUser => _datasource.currentUser;
}
