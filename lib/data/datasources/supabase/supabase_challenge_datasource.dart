import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseChallengeDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getAllChallenges() async {
    final response = await _client.from('daily_challenges').select();
    return response;
  }

  Future<Map<String, dynamic>> getChallenge(String challengeId) async {
    final response =
        await _client
            .from('daily_challenges')
            .select()
            .eq('id', challengeId)
            .single();
    return response;
  }

  Future<Map<String, dynamic>?> getDailyChallenge(DateTime date) async {
    final dateString = date.toIso8601String().split('T')[0];
    final response = await _client
        .from('daily_challenges')
        .select()
        .eq('date', dateString)
        .limit(1);

    if (response.isEmpty) {
      return null;
    }
    return response[0];
  }

  Future<String> createChallenge(Map<String, dynamic> challengeData) async {
    final response =
        await _client.from('daily_challenges').insert(challengeData).select();
    return response[0]['id'];
  }

  Future<void> updateChallenge(
    String challengeId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('daily_challenges').update(data).eq('id', challengeId);
  }

  Future<void> deleteChallenge(String challengeId) async {
    await _client.from('daily_challenges').delete().eq('id', challengeId);
  }

  // User Challenges
  Future<List<Map<String, dynamic>>> getUserChallenges(String userId) async {
    final response = await _client
        .from('user_challenges')
        .select('*, daily_challenges(*)')
        .eq('user_id', userId)
        .order('assigned_date', ascending: false);
    return response;
  }

  Future<String> assignChallengeToUser(
    Map<String, dynamic> userChallengeData,
  ) async {
    final response =
        await _client
            .from('user_challenges')
            .insert(userChallengeData)
            .select();
    return response[0]['id'];
  }

  Future<void> updateUserChallengeStatus(
    String userChallengeId,
    String status,
  ) async {
    Map<String, dynamic> updateData = {'status': status};

    if (status == 'completed') {
      updateData['completion_date'] = DateTime.now().toIso8601String();

      // Récupérer les informations du défi et de l'utilisateur
      final userChallenge =
          await _client
              .from('user_challenges')
              .select('user_id, challenge_id')
              .eq('id', userChallengeId)
              .single();

      final challenge =
          await _client
              .from('daily_challenges')
              .select('experience_points')
              .eq('id', userChallenge['challenge_id'])
              .single();

      // Mettre à jour l'enregistrement avec les points gagnés
      await _client
          .from('user_challenges')
          .update({'experience_gained': challenge['experience_points']})
          .eq('id', userChallengeId);

      // Ajouter les points d'expérience à l'utilisateur
      await _client.rpc(
        'add_user_experience',
        params: {
          'user_id_param': userChallenge['user_id'],
          'points_param': challenge['experience_points'],
        },
      );
    }

    // Mettre à jour le statut
    await _client
        .from('user_challenges')
        .update(updateData)
        .eq('id', userChallengeId);
  }

  Future<bool> hasCompletedTodaysChallenge(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final challenge = await _client
        .from('daily_challenges')
        .select('id')
        .eq('date', today)
        .limit(1);

    if (challenge.isEmpty) {
      return false;
    }

    final challengeId = challenge[0]['id'];

    final userChallenges = await _client
        .from('user_challenges')
        .select()
        .eq('user_id', userId)
        .eq('challenge_id', challengeId)
        .eq('status', 'completed');

    return userChallenges.isNotEmpty;
  }
}
