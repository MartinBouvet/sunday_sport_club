import '../datasources/supabase/supabase_course_datasource.dart';
import '../models/course.dart';

class CourseRepository {
  final SupabaseCourseDatasource _datasource = SupabaseCourseDatasource();

  Future<List<Course>> getAllCourses() async {
    try {
      final coursesData = await _datasource.getAllCourses();
      if (coursesData.isEmpty) {
        // Données de démonstration pour le développement
        return _getMockCourses();
      }
      return coursesData.map((data) => Course.fromJson(data)).toList();
    } catch (e) {
      // En cas d'erreur, retourner des données de démonstration
      return _getMockCourses();
    }
  }

  List<Course> _getMockCourses() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final nextWeek = now.add(const Duration(days: 7));

    return [
      Course(
        id: "course-1",
        title: "MMA Technique",
        description:
            "Cours individuel pour perfectionner vos techniques de combat",
        type: "individuel",
        date: tomorrow,
        startTime: "14:00",
        endTime: "15:00",
        capacity: 1,
        currentParticipants: 0,
        status: "available",
        coachId: "coach-1",
      ),
      Course(
        id: "course-2",
        title: "Body Fighting",
        description:
            "Cours collectif intensif pour développer force et endurance",
        type: "collectif",
        date: tomorrow.add(const Duration(hours: 2)),
        startTime: "17:00",
        endTime: "18:00",
        capacity: 10,
        currentParticipants: 5,
        status: "available",
        coachId: "coach-1",
      ),
      Course(
        id: "course-3",
        title: "Cardio Boxing",
        description: "Séance cardio intense avec techniques de boxe",
        type: "collectif",
        date: nextWeek,
        startTime: "18:30",
        endTime: "19:30",
        capacity: 8,
        currentParticipants: 3,
        status: "available",
        coachId: "coach-1",
      ),
    ];
  }

  Future<Course?> getCourse(String courseId) async {
    try {
      final courseData = await _datasource.getCourse(courseId);
      return Course.fromJson(courseData);
    } catch (e) {
      // Si le cours n'est pas trouvé dans la base de données, cherchez dans les données mockées
      final mockCourses = _getMockCourses();
      return mockCourses.firstWhere(
        (course) => course.id == courseId,
        orElse: () => throw Exception('Course not found'),
      );
    }
  }

  // Implémentation des autres méthodes...
  Future<String> createCourse(Course course) async {
    return await _datasource.createCourse(course.toJson());
  }

  Future<void> updateCourse(String courseId, Map<String, dynamic> data) async {
    await _datasource.updateCourse(courseId, data);
  }

  Future<void> deleteCourse(String courseId) async {
    await _datasource.deleteCourse(courseId);
  }

  Future<List<Course>> getUpcomingCourses() async {
    try {
      final coursesData = await _datasource.getUpcomingCourses();
      return coursesData.map((data) => Course.fromJson(data)).toList();
    } catch (e) {
      return _getMockCourses();
    }
  }

  Future<List<Course>> getCoursesByType(String type) async {
    try {
      final coursesData = await _datasource.getCoursesByType(type);
      return coursesData.map((data) => Course.fromJson(data)).toList();
    } catch (e) {
      return _getMockCourses().where((course) => course.type == type).toList();
    }
  }

  // Ajout de la méthode manquante getRecentCourses
  Future<List<Course>> getRecentCourses(int maxCourses) async {
    try {
      // Si possible, utiliser le datasource
      try {
        final coursesData = await _datasource.getRecentCourses(maxCourses);
        return coursesData.map((data) => Course.fromJson(data)).toList();
      } catch (e) {
        // Si l'API n'existe pas, utiliser la méthode alternative
        final allCourses = await getAllCourses();
        final sortedCourses = List<Course>.from(allCourses)
          ..sort((a, b) => b.date.compareTo(a.date));
        return sortedCourses.take(maxCourses).toList();
      }
    } catch (e) {
      // En cas d'erreur, retourner les premiers cours mockés
      return _getMockCourses().take(maxCourses).toList();
    }
  }
}
