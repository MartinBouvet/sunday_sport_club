import '../datasources/supabase/supabase_progress_datasource.dart';
import '../models/progress_tracking.dart';

class ProgressRepository {
  final SupabaseProgressDatasource _datasource = SupabaseProgressDatasource();

  Future<List<ProgressTracking>> getUserProgress(String userId) async {
    try {
      final progressData = await _datasource.getUserProgress(userId);
      return progressData
          .map((data) => ProgressTracking.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<ProgressTracking?> getProgressEntry(String entryId) async {
    try {
      final entryData = await _datasource.getProgressEntry(entryId);
      return ProgressTracking.fromJson(entryData);
    } catch (e) {
      return null;
    }
  }

  Future<String> createProgressEntry(ProgressTracking entry) async {
    return await _datasource.createProgressEntry(entry.toJson());
  }

  Future<void> updateProgressEntry(
    String entryId,
    Map<String, dynamic> data,
  ) async {
    await _datasource.updateProgressEntry(entryId, data);
  }

  Future<void> deleteProgressEntry(String entryId) async {
    await _datasource.deleteProgressEntry(entryId);
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    return await _datasource.getUserStats(userId);
  }

  Future<bool> updateUserExperiencePoints(String userId, int points) async {
    return await _datasource.updateUserExperiencePoints(userId, points);
  }

  Future<bool> updateUserLevel(String userId, int level) async {
    return await _datasource.updateUserLevel(userId, level);
  }
}
