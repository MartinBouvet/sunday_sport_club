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

  // Initialiser avec des cartes mock pour le développement
  void _initMockMembershipCards(String userId) {
    final now = DateTime.now();

    _userMembershipCards = [
      MembershipCard(
        id: 'card-1',
        userId: userId,
        type: 'individuel',
        totalSessions: 10,
        remainingSessions: 5,
        purchaseDate: now.subtract(const Duration(days: 30)),
        expiryDate: now.add(const Duration(days: 180)),
        price: 350.0,
        paymentStatus: 'completed',
      ),
      MembershipCard(
        id: 'card-2',
        userId: userId,
        type: 'collectif',
        totalSessions: 20,
        remainingSessions: 15,
        purchaseDate: now.subtract(const Duration(days: 15)),
        expiryDate: now.add(const Duration(days: 180)),
        price: 280.0,
        paymentStatus: 'completed',
      ),
    ];
  }

  Future<void> fetchAvailableCourses({
    required DateTime startDate,
    required DateTime endDate,
    String? type,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
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

  Future<void> fetchUserBookings(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      debugPrint("Fetching bookings for user: $userId");
      _userBookings = await _bookingRepository.getUserBookings(userId);
      debugPrint("Found ${_userBookings.length} bookings");
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
      _errorMessage =
          'Erreur lors de la récupération des réservations: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserMembershipCards(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _userMembershipCards = await _membershipRepository.getUserMembershipCards(
        userId,
      );

      // Si aucune carte n'est trouvée, utiliser des données de démonstration
      if (_userMembershipCards.isEmpty) {
        _initMockMembershipCards(userId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // En cas d'erreur, utiliser des données de démonstration
      _initMockMembershipCards(userId);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBooking({
    required String userId,
    required String courseId,
    required String membershipCardId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      debugPrint(
        "Creating booking: userId=$userId, courseId=$courseId, membershipCardId=$membershipCardId",
      );

      // Vérifier que le cours existe et a des places disponibles
      final course = await _courseRepository.getCourse(courseId);
      if (course == null) {
        throw Exception('Cours introuvable');
      }

      if (course.currentParticipants >= course.capacity) {
        throw Exception('Ce cours est complet');
      }

      // Vérifier que la carte d'abonnement est valide
      final card = await _membershipRepository.getMembershipCard(
        membershipCardId,
      );
      if (card == null) {
        throw Exception('Carte d\'abonnement introuvable');
      }

      if (card.remainingSessions <= 0) {
        throw Exception('Carte d\'abonnement épuisée');
      }

      final now = DateTime.now();
      if (card.expiryDate.isBefore(now)) {
        throw Exception('Carte d\'abonnement expirée');
      }

      // Vérifier que le type de carte correspond au type de cours
      if (card.type == 'individuel' && course.type != 'individuel') {
        throw Exception(
          'Cette carte ne permet pas de réserver ce type de cours',
        );
      }

      // Créer la réservation
      Booking booking = Booking(
        id: 'booking-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        courseId: courseId,
        bookingDate: DateTime.now(),
        status: 'confirmed',
        membershipCardId: membershipCardId,
      );

      // Appeler le repository pour créer la réservation
      final bookingId = await _bookingRepository.createBooking(booking);
      booking = booking.copyWith(id: bookingId);

      // Ajouter la réservation à la liste locale
      _userBookings.add(booking);

      // Mettre à jour les données locales
      await fetchUserMembershipCards(userId);
      await fetchAvailableCourses(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );

      _successMessage = 'Réservation créée avec succès';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error creating booking: $e");
      _errorMessage = 'Erreur lors de la réservation: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _bookingRepository.updateBooking(bookingId, {
        'status': 'cancelled',
      });

      // Mettre à jour la liste locale
      final index = _userBookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _userBookings[index] = _userBookings[index].copyWith(
          status: 'cancelled',
        );
      }

      _successMessage = 'Réservation annulée avec succès';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de l\'annulation: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setSelectedCourse(Course course) {
    _selectedCourse = course;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
