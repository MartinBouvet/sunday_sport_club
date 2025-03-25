import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseUserDatasource {
  final SupabaseClient _client = supabase;

  Future<Map<String, dynamic>> getUser(String userId) async {
    final response =
        await _client.from('profiles').select().eq('id', userId).single();

    return response;
  }

  Future<void> createUser({
    required String id,
    required String email,
    required String firstName,
    required String lastName,
    String gender = 'homme',
    String skinColor = 'blanc',
  }) async {
    await _client.from('profiles').insert({
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'skin_color': skinColor,
      'avatar_stage': 'mince',
      'is_active': true,
      'role': 'user',
      'level': 1,
      'experience_points': 0,
      'endurance': 1,
      'strength': 1,
    });
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', userId);
  }
}
