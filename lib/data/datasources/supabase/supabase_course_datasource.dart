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
}
