import '../datasources/supabase/supabase_course_datasource.dart';
import '../models/course.dart';

class CourseRepository {
  final SupabaseCourseDatasource _datasource = SupabaseCourseDatasource();

  Future<List<Course>> getAllCourses() async {
    try {
      final coursesData = await _datasource.getAllCourses();
      return coursesData.map((data) => Course.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Course?> getCourse(String courseId) async {
    try {
      final courseData = await _datasource.getCourse(courseId);
      return Course.fromJson(courseData);
    } catch (e) {
      return null;
    }
  }

  Future<void> createCourse(Course course) async {
    await _datasource.createCourse(course.toJson());
  }

  Future<void> updateCourse(String courseId, Map<String, dynamic> data) async {
    await _datasource.updateCourse(courseId, data);
  }

  Future<void> deleteCourse(String courseId) async {
    await _datasource.deleteCourse(courseId);
  }
}
