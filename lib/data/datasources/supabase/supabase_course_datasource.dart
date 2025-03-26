import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseCourseDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getAllCourses() async {
    final response = await _client.from('courses').select();
    return response;
  }

  Future<Map<String, dynamic>> getCourse(String courseId) async {
    final response =
        await _client.from('courses').select().eq('id', courseId).single();
    return response;
  }

  Future<String> createCourse(Map<String, dynamic> courseData) async {
    final response = await _client.from('courses').insert(courseData).select();
    return response[0]['id'];
  }

  Future<void> updateCourse(String courseId, Map<String, dynamic> data) async {
    await _client.from('courses').update(data).eq('id', courseId);
  }

  Future<void> deleteCourse(String courseId) async {
    await _client.from('courses').delete().eq('id', courseId);
  }

  Future<List<Map<String, dynamic>>> getUpcomingCourses() async {
    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from('courses')
        .select()
        .gte('date', now)
        .order('date');
    return response;
  }

  Future<List<Map<String, dynamic>>> getCoursesByType(String type) async {
    final response = await _client
        .from('courses')
        .select()
        .eq('type', type)
        .order('date');
    return response;
  }

  Future<List<Map<String, dynamic>>> getCoursesByCoach(String coachId) async {
    final response = await _client
        .from('courses')
        .select()
        .eq('coach_id', coachId)
        .order('date');
    return response;
  }

  Future<List<Map<String, dynamic>>> getAvailableCourses(
      DateTime startDate, DateTime endDate) async {
    final startDateIso = startDate.toIso8601String();
    final endDateIso = endDate.toIso8601String();
    
    final response = await _client
        .from('courses')
        .select()
        .gte('date', startDateIso)
        .lte('date', endDateIso)
        .eq('status', 'available')
        .order('date');
    return response;
  }

  Future<bool> incrementCourseParticipants(String courseId) async {
    try {
      await _client.rpc(
        'increment_course_participants',
        params: {'course_id_param': courseId},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> decrementCourseParticipants(String courseId) async {
    try {
      await _client.rpc(
        'decrement_course_participants',
        params: {'course_id_param': courseId},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> searchCourses(String query) async {
    // Cette fonction suppose que vous avez configuré une recherche plein texte dans Supabase
    // Si non disponible, vous pouvez simuler une recherche simple comme ceci:
    final response = await _client
        .from('courses')
        .select()
        .or('title.ilike.%${query}%, description.ilike.%${query}%')
        .order('date');
    return response;
  }
}