import '../datasources/supabase/supabase_challenge_datasource.dart';
import '../models/daily_challenge.dart';
import '../models/user_challenge.dart';

class ChallengeRepository {
  final SupabaseChallengeDatasource _datasource = SupabaseChallengeDatasource();

  Future<List<DailyChallenge>> getAllChallenges() async {
    try {
      final challengesData = await _datasource.getAllChallenges();
      return challengesData
          .map((data) => DailyChallenge.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<DailyChallenge?> getChallenge(String challengeId) async {
    try {
      final challengeData = await _datasource.getChallenge(challengeId);
      return DailyChallenge.fromJson(challengeData);
    } catch (e) {
      return null;
    }
  }

  Future<DailyChallenge?> getDailyChallenge(DateTime date) async {
    try {
      final challengeData = await _datasource.getDailyChallenge(date);
      return challengeData != null
          ? DailyChallenge.fromJson(challengeData)
          : null;
    } catch (e) {
      return null;
    }
  }

  Future<String> createChallenge(DailyChallenge challenge) async {
    return await _datasource.createChallenge(challenge.toJson());
  }

  Future<void> updateChallenge(
    String challengeId,
    Map<String, dynamic> data,
  ) async {
    await _datasource.updateChallenge(challengeId, data);
  }

  Future<void> deleteChallenge(String challengeId) async {
    await _datasource.deleteChallenge(challengeId);
  }

  Future<List<UserChallenge>> getUserChallenges(String userId) async {
    try {
      final userChallengesData = await _datasource.getUserChallenges(userId);
      return userChallengesData
          .map((data) => UserChallenge.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<String> assignChallengeToUser(UserChallenge userChallenge) async {
    return await _datasource.assignChallengeToUser(userChallenge.toJson());
  }

  Future<void> updateUserChallengeStatus(
    String userChallengeId,
    String status,
  ) async {
    await _datasource.updateUserChallengeStatus(userChallengeId, status);
  }
}
