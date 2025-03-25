import '../datasources/supabase/supabase_user_datasource.dart';
import '../models/user.dart';

class UserRepository {
  final SupabaseUserDatasource _datasource = SupabaseUserDatasource();

  Future<User?> getUser(String userId) async {
    try {
      final userData = await _datasource.getUser(userId);
      return User.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  Future<void> createUser({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    String gender = 'homme',
    String skinColor = 'blanc',
  }) async {
    await _datasource.createUser(
      id: id,
      email: email,
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      skinColor: skinColor,
    );
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _datasource.updateUser(userId, data);
  }
}
