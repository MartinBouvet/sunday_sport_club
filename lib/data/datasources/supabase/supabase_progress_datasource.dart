import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseProgressDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getUserProgress(String userId) async {
    final response = await _client
        .from('progress_tracking')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    return response;
  }

  Future<Map<String, dynamic>> getProgressEntry(String entryId) async {
    final response =
        await _client
            .from('progress_tracking')
            .select()
            .eq('id', entryId)
            .single();
    return response;
  }

  Future<String> createProgressEntry(Map<String, dynamic> entryData) async {
    final response =
        await _client.from('progress_tracking').insert(entryData).select();
    return response[0]['id'];
  }

  Future<void> updateProgressEntry(
    String entryId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('progress_tracking').update(data).eq('id', entryId);
  }

  Future<void> deleteProgressEntry(String entryId) async {
    await _client.from('progress_tracking').delete().eq('id', entryId);
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    // Récupérer les informations de profil
    final profile =
        await _client
            .from('profiles')
            .select(
              'level, experience_points, endurance, strength, weight, avatar_stage',
            )
            .eq('id', userId)
            .single();

    // Calculer les statistiques d'activité
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    // Statistiques des défis
    final challenges = await _client
        .from('user_challenges')
        .select('status')
        .eq('user_id', userId)
        .gte('assigned_date', startOfMonth);

    int totalChallenges = challenges.length;
    int completedChallenges =
        challenges.where((c) => c['status'] == 'completed').length;

    // Statistiques des routines
    final routines = await _client
        .from('user_routines')
        .select('status')
        .eq('user_id', userId)
        .gte('assigned_date', startOfMonth);

    int totalRoutines = routines.length;
    int completedRoutines =
        routines
            .where(
              (r) => r['status'] == 'completed' || r['status'] == 'validated',
            )
            .length;

    // Statistiques des cours
    final bookings = await _client
        .from('bookings')
        .select('status')
        .eq('user_id', userId)
        .gte('booking_date', startOfMonth);

    int totalClasses = bookings.length;
    int attendedClasses =
        bookings.where((b) => b['status'] == 'completed').length;

    // Assembler les statistiques
    Map<String, dynamic> stats = {
      ...profile,
      'total_challenges': totalChallenges,
      'completed_challenges': completedChallenges,
      'challenge_completion_rate':
          totalChallenges > 0
              ? (completedChallenges / totalChallenges) * 100
              : 0,
      'total_routines': totalRoutines,
      'completed_routines': completedRoutines,
      'routine_completion_rate':
          totalRoutines > 0 ? (completedRoutines / totalRoutines) * 100 : 0,
      'total_classes': totalClasses,
      'attended_classes': attendedClasses,
      'class_attendance_rate':
          totalClasses > 0 ? (attendedClasses / totalClasses) * 100 : 0,
    };

    return stats;
  }

  Future<bool> updateUserExperiencePoints(String userId, int points) async {
    try {
      await _client.rpc(
        'add_user_experience',
        params: {'user_id_param': userId, 'points_param': points},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUserLevel(String userId, int level) async {
    try {
      await _client.from('profiles').update({'level': level}).eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAvatarStage(String userId, String stage) async {
    try {
      await _client
          .from('profiles')
          .update({'avatar_stage': stage})
          .eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getProgressHistory(
    String userId,
    String metric,
  ) async {
    final response = await _client
        .from('progress_tracking')
        .select('date, $metric')
        .eq('user_id', userId)
        .not('$metric', 'is', null)
        .order('date');
    return response;
  }
}
