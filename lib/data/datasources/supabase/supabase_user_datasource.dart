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
    try {
      // Option 1: Utiliser le service client avec service_role (si vous avez configuré un secret côté serveur)
      // Cette option contourne les politiques RLS
      
      // Option 2: Utiliser la fonction RPC personnalisée (recommandée)
      await _client.rpc('create_user_profile', params: {
        'user_id': id,
        'user_email': email,
        'first_name': firstName,
        'last_name': lastName,
        'user_gender': gender,
        'user_skin_color': skinColor,
      });
      
      
      await _client.from('profiles').insert({
        'id': id, // Spécifiez explicitement que l'ID de profil est le même que l'ID d'authentification
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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', userId);
  }
}
