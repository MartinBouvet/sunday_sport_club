import '../datasources/supabase/supabase_routine_datasource.dart';
import '../models/routine.dart';
import '../models/user_routine.dart';

class RoutineRepository {
  final SupabaseRoutineDatasource _datasource = SupabaseRoutineDatasource();

  Future<List<Routine>> getAllRoutines() async {
    try {
      final routinesData = await _datasource.getAllRoutines();
      return routinesData.map((data) => Routine.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Routine?> getRoutine(String routineId) async {
    try {
      final routineData = await _datasource.getRoutine(routineId);
      return Routine.fromJson(routineData);
    } catch (e) {
      return null;
    }
  }

  Future<String> createRoutine(Routine routine) async {
    return await _datasource.createRoutine(routine.toJson());
  }

  Future<void> updateRoutine(
    String routineId,
    Map<String, dynamic> data,
  ) async {
    await _datasource.updateRoutine(routineId, data);
  }

  Future<void> deleteRoutine(String routineId) async {
    await _datasource.deleteRoutine(routineId);
  }

  Future<List<UserRoutine>> getUserRoutines(String userId) async {
    try {
      final userRoutinesData = await _datasource.getUserRoutines(userId);
      return userRoutinesData
          .map((data) => UserRoutine.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<String> assignRoutineToUser(UserRoutine userRoutine) async {
    return await _datasource.assignRoutineToUser(userRoutine.toJson());
  }

  Future<void> updateUserRoutineStatus(
    String userRoutineId,
    String status,
  ) async {
    await _datasource.updateUserRoutineStatus(userRoutineId, status);
  }
}
