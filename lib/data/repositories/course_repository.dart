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

  Future<String> createCourse(Course course) async {
    return await _datasource.createCourse(course.toJson());
  }

  Future<void> updateCourse(String courseId, Map<String, dynamic> data) async {
    await _datasource.updateCourse(courseId, data);
  }

  Future<void> deleteCourse(String courseId) async {
    await _datasource.deleteCourse(courseId);
  }

  // Méthodes additionnelles pour les fonctionnalités spécifiques

  // Récupérer les cours à venir
  Future<List<Course>> getUpcomingCourses() async {
    try {
      final coursesData = await _datasource.getUpcomingCourses();
      return coursesData.map((data) => Course.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  // Récupérer les cours par type (individuel/collectif)
  Future<List<Course>> getCoursesByType(String type) async {
    try {
      final coursesData = await _datasource.getCoursesByType(type);
      return coursesData.map((data) => Course.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  // Rechercher des cours par mot-clé
  Future<List<Course>> searchCourses(String keyword) async {
    try {
      // Implémenter la recherche côté serveur si disponible
      // Sinon, filtrer côté client
      final coursesData = await _datasource.getAllCourses();
      final courses = coursesData.map((data) => Course.fromJson(data)).toList();
      
      if (keyword.isEmpty) return courses;
      
      return courses.where((course) => 
        course.title.toLowerCase().contains(keyword.toLowerCase()) ||
        course.description.toLowerCase().contains(keyword.toLowerCase())
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Vérifier les disponibilités d'un coach
  Future<List<Course>> getCoachCourses(String coachId) async {
    try {
      // Supposons que nous avons une méthode dans le datasource pour cela
      final coursesData = await _datasource.getCoursesByCoach(coachId);
      return coursesData.map((data) => Course.fromJson(data)).toList();
    } catch (e) {
      // Si la méthode n'existe pas, nous pouvons filtrer les résultats localement
      try {
        final allCourses = await getAllCourses();
        return allCourses.where((course) => course.coachId == coachId).toList();
      } catch (e) {
        return [];
      }
    }
  }

  // Vérifier si un utilisateur peut s'inscrire à un cours
  Future<bool> checkCourseAvailability(String courseId) async {
    try {
      final course = await getCourse(courseId);
      if (course == null) return false;
      
      final now = DateTime.now();
      final courseDateTime = DateTime(
        course.date.year, 
        course.date.month, 
        course.date.day,
        int.parse(course.startTime.split(':')[0]),
        int.parse(course.startTime.split(':')[1])
      );
      
      // Un cours est disponible s'il est dans le futur et n'est pas complet
      return courseDateTime.isAfter(now) && 
             course.currentParticipants < course.capacity &&
             course.status == 'available';
    } catch (e) {
      return false;
    }
  }
}