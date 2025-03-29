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
      _userBookings = await _bookingRepository.getUserBookings(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
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
      // Vérifier que le cours existe et a des places disponibles
      final courseIndex = _availableCourses.indexWhere((c) => c.id == courseId);
      if (courseIndex == -1) {
        throw Exception('Cours introuvable');
      }

      final course = _availableCourses[courseIndex];
      if (course.currentParticipants >= course.capacity) {
        throw Exception('Ce cours est complet');
      }

      // Vérifier que la carte d'abonnement est valide
      final cardIndex = _userMembershipCards.indexWhere(
        (c) => c.id == membershipCardId,
      );
      if (cardIndex == -1) {
        throw Exception('Carte d\'abonnement introuvable');
      }

      final card = _userMembershipCards[cardIndex];
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

      // Créer la nouvelle réservation
      final booking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        courseId: courseId,
        bookingDate: DateTime.now(),
        status: 'confirmed',
        membershipCardId: membershipCardId,
      );

      // Enregistrer la réservation
      final bookingId = await _bookingRepository.createBooking(booking);

      // Mettre à jour les données locales
      // Ajouter la réservation à la liste
      final newBooking = booking.copyWith(id: bookingId);
      _userBookings.add(newBooking);

      // Mettre à jour la carte d'abonnement
      _userMembershipCards[cardIndex] = MembershipCard(
        id: card.id,
        userId: card.userId,
        type: card.type,
        totalSessions: card.totalSessions,
        remainingSessions: card.remainingSessions - 1,
        purchaseDate: card.purchaseDate,
        expiryDate: card.expiryDate,
        price: card.price,
        paymentStatus: card.paymentStatus,
      );

      // Mettre à jour le cours
      _availableCourses[courseIndex] = Course(
        id: course.id,
        title: course.title,
        description: course.description,
        type: course.type,
        date: course.date,
        startTime: course.startTime,
        endTime: course.endTime,
        capacity: course.capacity,
        currentParticipants: course.currentParticipants + 1,
        status: course.status,
        coachId: course.coachId,
      );

      _successMessage = 'Réservation effectuée avec succès';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
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
      // Pour le développement, simuler une annulation réussie
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
}
