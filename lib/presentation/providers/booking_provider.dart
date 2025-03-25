import 'package:flutter/material.dart';
import '../../data/models/booking.dart';
import '../../data/models/course.dart';
import '../../data/models/membership_card.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/course_repository.dart';
import '../../data/repositories/membership_repository.dart';

class BookingProvider extends ChangeNotifier {
  final BookingRepository _bookingRepository = BookingRepository();
  final CourseRepository _courseRepository = CourseRepository();
  final MembershipRepository _membershipRepository = MembershipRepository();

  List<Course> _availableCourses = [];
  List<Booking> _userBookings = [];
  List<MembershipCard> _userMembershipCards = [];
  Course? _selectedCourse;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  List<Course> get availableCourses => _availableCourses;
  List<Booking> get userBookings => _userBookings;
  List<MembershipCard> get userMembershipCards => _userMembershipCards;
  Course? get selectedCourse => _selectedCourse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  Future<void> fetchAvailableCourses({
    required DateTime startDate,
    required DateTime endDate,
    String? type,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      _availableCourses = await _courseRepository.getAllCourses();
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des cours: ${e.toString()}');
    }
  }

  Future<void> fetchUserBookings(String userId) async {
    _setLoading(true);
    _clearMessages();

    try {
      _userBookings = await _bookingRepository.getUserBookings(userId);
      _setLoading(false);
    } catch (e) {
      _setError(
        'Erreur lors de la récupération des réservations: ${e.toString()}',
      );
    }
  }

  Future<void> fetchUserMembershipCards(String userId) async {
    _setLoading(true);
    _clearMessages();

    try {
      _userMembershipCards = await _membershipRepository.getUserMembershipCards(
        userId,
      );
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des carnets: ${e.toString()}');
    }
  }

  void selectCourse(Course course) {
    _selectedCourse = course;
    notifyListeners();
  }

  void clearSelectedCourse() {
    _selectedCourse = null;
    notifyListeners();
  }

  Future<bool> createBooking({
    required String userId,
    required String courseId,
    required String membershipCardId,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      final booking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        courseId: courseId,
        bookingDate: DateTime.now(),
        status: 'confirmed',
        membershipCardId: membershipCardId,
      );

      await _bookingRepository.createBooking(booking);

      _userBookings.add(booking);
      _setSuccess('Réservation effectuée avec succès');
      return true;
    } catch (e) {
      _setError('Erreur lors de la réservation: ${e.toString()}');
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _bookingRepository.updateBooking(bookingId, {
        'status': 'cancelled',
      });

      // Mettre à jour localement
      final index = _userBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _userBookings[index] = _userBookings[index].copyWith(
          status: 'cancelled',
        );
      }

      _setSuccess('Réservation annulée avec succès');
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'annulation: ${e.toString()}');
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _successMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setSuccess(String message) {
    _successMessage = message;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
