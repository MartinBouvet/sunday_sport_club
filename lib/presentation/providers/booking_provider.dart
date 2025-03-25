import 'package:flutter/material.dart';
import 'package:sunday_sport_club/data/models/booking.dart';
import 'package:sunday_sport_club/data/models/course.dart';
import 'package:sunday_sport_club/data/models/membership_card.dart';
import 'package:sunday_sport_club/data/repositories/booking_repository.dart';
import 'package:sunday_sport_club/data/repositories/course_repository.dart';
import 'package:sunday_sport_club/data/repositories/membership_repository.dart';
import 'package:sunday_sport_club/domain/services/booking_service.dart';
import 'package:sunday_sport_club/domain/services/notification_service.dart';
import 'package:sunday_sport_club/presentation/providers/user_provider.dart';

/// Provider responsable de la gestion des réservations de cours.
///
/// Gère la récupération des cours disponibles, la réservation de cours,
/// l'annulation de réservations, et le suivi de l'historique des réservations.
class BookingProvider extends ChangeNotifier {
  final BookingRepository _bookingRepository;
  final CourseRepository _courseRepository;
  final MembershipRepository _membershipRepository;
  final BookingService _bookingService;
  final NotificationService _notificationService;
  final UserProvider _userProvider;

  List<Course> _availableCourses = [];
  List<Booking> _userBookings = [];
  List<MembershipCard> _userMembershipCards = [];
  Course? _selectedCourse;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  /// Constructeur qui nécessite toutes les dépendances pour fonctionner
  BookingProvider({
    required BookingRepository bookingRepository,
    required CourseRepository courseRepository,
    required MembershipRepository membershipRepository,
    required BookingService bookingService,
    required NotificationService notificationService,
    required UserProvider userProvider,
  })  : _bookingRepository = bookingRepository,
        _courseRepository = courseRepository,
        _membershipRepository = membershipRepository,
        _bookingService = bookingService,
        _notificationService = notificationService,
        _userProvider = userProvider;

  // Getters
  List<Course> get availableCourses => _availableCourses;
  List<Booking> get userBookings => _userBookings;
  List<MembershipCard> get userMembershipCards => _userMembershipCards;
  Course? get selectedCourse => _selectedCourse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSuccess => _successMessage != null;

  /// Récupère les cours disponibles pour une période donnée
  Future<void> fetchAvailableCourses({
    required DateTime startDate,
    required DateTime endDate,
    String? type,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      _availableCourses = await _courseRepository.getAvailableCourses(
        startDate: startDate,
        endDate: endDate,
        type: type,
      );
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des cours: ${e.toString()}');
    }
  }

  /// Récupère les réservations d'un utilisateur
  Future<void> fetchUserBookings(String userId) async {
    _setLoading(true);
    _clearMessages();

    try {
      _userBookings = await _bookingRepository.getUserBookings(userId);
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des réservations: ${e.toString()}');
    }
  }

  /// Récupère les réservations de l'utilisateur actuel
  Future<void> fetchCurrentUserBookings() async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return;
    }

    await fetchUserBookings(user.id);
  }

  /// Récupère les carnets de coaching de l'utilisateur actuel
  Future<void> fetchUserMembershipCards() async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return;
    }

    _setLoading(true);
    _clearMessages();

    try {
      _userMembershipCards = await _membershipRepository.getUserMembershipCards(user.id);
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la récupération des carnets: ${e.toString()}');
    }
  }

  /// Définit le cours sélectionné pour la réservation
  void selectCourse(Course course) {
    _selectedCourse = course;
    notifyListeners();
  }

  /// Efface le cours sélectionné
  void clearSelectedCourse() {
    _selectedCourse = null;
    notifyListeners();
  }

  /// Récupère les détails d'un cours spécifique
  Future<Course?> fetchCourseDetails(String courseId) async {
    _setLoading(true);
    _clearMessages();

    try {
      final course = await _courseRepository.getCourseById(courseId);
      _setLoading(false);
      return course;
    } catch (e) {
      _setError('Erreur lors de la récupération des détails du cours: ${e.toString()}');
      return null;
    }
  }

  /// Crée une réservation pour un cours
  Future<bool> createBooking({
    required String courseId,
    required String membershipCardId,
  }) async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return false;
    }

    _setLoading(true);
    _clearMessages();

    try {
      // Vérifier si l'utilisateur a déjà réservé ce cours
      final hasExistingBooking = _userBookings.any((booking) => 
        booking.courseId == courseId && 
        booking.status != 'cancelled'
      );

      if (hasExistingBooking) {
        _setError('Vous avez déjà réservé ce cours');
        return false;
      }

      // Vérifier si le carnet a suffisamment de séances restantes
      final card = _userMembershipCards.firstWhere(
        (card) => card.id == membershipCardId,
        orElse: () => throw Exception('Carnet non trouvé'),
      );

      if (card.remainingSessions <= 0) {
        _setError('Carnet épuisé. Veuillez acheter un nouveau carnet');
        return false;
      }

      // Vérifier si le cours est disponible
      final course = await _courseRepository.getCourseById(courseId);
      if (course == null) {
        _setError('Cours non trouvé');
        return false;
      }

      if (course.isCancelled) {
        _setError('Ce cours a été annulé');
        return false;
      }

      if (course.dateTime.isBefore(DateTime.now())) {
        _setError('Ce cours est déjà passé');
        return false;
      }

      if (course.type == 'collectif' && 
          course.participants.length >= course.maxParticipants) {
        _setError('Ce cours est complet');
        return false;
      }

      // Créer la réservation
      final booking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        courseId: courseId,
        membershipCardId: membershipCardId,
        bookingDate: DateTime.now(),
        status: 'confirmed',
        isAttended: false,
      );

      // Enregistrer la réservation
      final createdBooking = await _bookingRepository.createBooking(booking);
      
      // Mettre à jour le carnet
      await _membershipRepository.updateMembershipCard(
        card.id,
        remainingSessions: card.remainingSessions - 1,
      );

      // Mettre à jour le cours
      final updatedParticipants = List<String>.from(course.participants)..add(user.id);
      await _courseRepository.updateCourse(
        course.id,
        participants: updatedParticipants,
      );

      // Mettre à jour les listes locales
      _userBookings.add(createdBooking);
      
      // Rafraîchir les carnets
      await fetchUserMembershipCards();
      
      // Envoyer une notification
      await _notificationService.sendBookingConfirmation(
        userId: user.id,
        courseTitle: course.title,
        courseDateTime: course.dateTime,
      );

      _setSuccess('Réservation effectuée avec succès');
      return true;
    } catch (e) {
      _setError('Erreur lors de la réservation: ${e.toString()}');
      return false;
    }
  }

  /// Annule une réservation existante
  Future<bool> cancelBooking(String bookingId) async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return false;
    }

    _setLoading(true);
    _clearMessages();

    try {
      // Récupérer la réservation
      final booking = _userBookings.firstWhere(
        (b) => b.id == bookingId,
        orElse: () => throw Exception('Réservation non trouvée'),
      );

      // Vérifier si la réservation est annulable
      final course = await _courseRepository.getCourseById(booking.courseId);
      if (course == null) {
        _setError('Cours non trouvé');
        return false;
      }

      // Vérifier le délai d'annulation (par exemple, 24h avant le cours)
      final cancellationDeadline = course.dateTime.subtract(const Duration(hours: 24));
      if (DateTime.now().isAfter(cancellationDeadline)) {
        _setError('Annulation impossible moins de 24h avant le cours');
        return false;
      }

      // Mettre à jour le statut de la réservation
      await _bookingRepository.updateBookingStatus(bookingId, 'cancelled');

      // Récupérer le carnet utilisé pour la réservation
      final card = await _membershipRepository.getMembershipCardById(booking.membershipCardId);
      if (card != null) {
        // Recréditer la séance sur le carnet
        await _membershipRepository.updateMembershipCard(
          card.id,
          remainingSessions: card.remainingSessions + 1,
        );
      }

      // Mettre à jour la liste des participants du cours
      if (course.participants.contains(user.id)) {
        final updatedParticipants = List<String>.from(course.participants)..remove(user.id);
        await _courseRepository.updateCourse(
          course.id,
          participants: updatedParticipants,
        );
      }

      // Mettre à jour les listes locales
      final bookingIndex = _userBookings.indexWhere((b) => b.id == bookingId);
      if (bookingIndex != -1) {
        _userBookings[bookingIndex] = Booking(
          id: booking.id,
          userId: booking.userId,
          courseId: booking.courseId,
          membershipCardId: booking.membershipCardId,
          bookingDate: booking.bookingDate,
          status: 'cancelled',
          isAttended: false,
        );
      }

      // Rafraîchir les carnets
      await fetchUserMembershipCards();

      _setSuccess('Réservation annulée avec succès');
      return true;
    } catch (e) {
      _setError('Erreur lors de l\'annulation: ${e.toString()}');
      return false;
    }
  }

  /// Marque la présence de l'utilisateur à un cours (fonctionnalité admin)
  Future<bool> markAttendance({
    required String bookingId,
    required bool isAttended,
  }) async {
    _setLoading(true);
    _clearMessages();

    try {
      await _bookingRepository.updateBookingAttendance(bookingId, isAttended);
      
      // Mettre à jour la liste locale
      final bookingIndex = _userBookings.indexWhere((b) => b.id == bookingId);
      if (bookingIndex != -1) {
        _userBookings[bookingIndex] = Booking(
          id: _userBookings[bookingIndex].id,
          userId: _userBookings[bookingIndex].userId,
          courseId: _userBookings[bookingIndex].courseId,
          membershipCardId: _userBookings[bookingIndex].membershipCardId,
          bookingDate: _userBookings[bookingIndex].bookingDate,
          status: _userBookings[bookingIndex].status,
          isAttended: isAttended,
        );
      }

      _setSuccess('Présence mise à jour avec succès');
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour de la présence: ${e.toString()}');
      return false;
    }
  }

  /// Récupère les statistiques de fréquentation des cours pour l'utilisateur actuel
  Future<Map<String, dynamic>> getUserAttendanceStats() async {
    final user = _userProvider.currentUser;
    if (user == null) {
      _setError('Aucun utilisateur connecté');
      return {};
    }

    _setLoading(true);
    _clearMessages();

    try {
      await fetchCurrentUserBookings();
      
      // Calculer les statistiques
      final totalBookings = _userBookings.length;
      final attendedBookings = _userBookings.where((b) => b.isAttended).length;
      final cancelledBookings = _userBookings.where((b) => b.status == 'cancelled').length;
      final attendanceRate = totalBookings > 0 
          ? (attendedBookings / (totalBookings - cancelledBookings)) * 100 
          : 0;

      _setLoading(false);
      
      return {
        'totalBookings': totalBookings,
        'attendedBookings': attendedBookings,
        'cancelledBookings': cancelledBookings,
        'attendanceRate': attendanceRate,
      };
    } catch (e) {
      _setError('Erreur lors du calcul des statistiques: ${e.toString()}');
      return {};
    }
  }

  // Méthodes utilitaires privées pour la gestion d'état
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