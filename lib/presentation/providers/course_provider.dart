import 'package:flutter/material.dart';
import '../../data/models/course.dart';
import '../../data/repositories/course_repository.dart';

class CourseProvider extends ChangeNotifier {
  final CourseRepository _courseRepository = CourseRepository();

  List<Course> _availableCourses = [];
  List<Course> _upcomingCourses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Course> get availableCourses => _availableCourses;
  List<Course> get upcomingCourses => _upcomingCourses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> fetchAvailableCourses({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availableCourses = await _courseRepository.getAllCourses();

      // Filtrer par dates
      if (startDate != null) {
        _availableCourses =
            _availableCourses
                .where(
                  (course) =>
                      course.date.isAfter(startDate) ||
                      course.date.isAtSameMomentAs(startDate),
                )
                .toList();
      }

      if (endDate != null) {
        _availableCourses =
            _availableCourses
                .where(
                  (course) =>
                      course.date.isBefore(endDate) ||
                      course.date.isAtSameMomentAs(endDate),
                )
                .toList();
      }

      // Filtrer par type
      if (type != null && type != 'all') {
        _availableCourses =
            _availableCourses.where((course) => course.type == type).toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage =
          'Erreur lors de la récupération des cours: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUpcomingCourses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _upcomingCourses = await _courseRepository.getUpcomingCourses();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage =
          'Erreur lors de la récupération des prochains cours: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Course?> getCourse(String courseId) async {
    try {
      return await _courseRepository.getCourse(courseId);
    } catch (e) {
      _errorMessage =
          'Erreur lors de la récupération du cours: ${e.toString()}';
      notifyListeners();
      return null;
    }
  }
}
