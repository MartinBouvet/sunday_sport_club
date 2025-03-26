import '../../data/models/course.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/course_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/membership_repository.dart';

class CourseService {
  final CourseRepository _courseRepository = CourseRepository();
  final BookingRepository _bookingRepository = BookingRepository();
  final MembershipRepository _membershipRepository = MembershipRepository();

  // Récupérer tous les cours disponibles
  Future<List<Course>> getAvailableCourses({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    try {
      List<Course> courses = await _courseRepository.getAllCourses();
      
      // Filtrer par dates si nécessaire
      if (startDate != null) {
        courses = courses.where((course) => course.date.isAfter(startDate) || 
                                          course.date.isAtSameMomentAs(startDate)).toList();
      }
      
      if (endDate != null) {
        courses = courses.where((course) => course.date.isBefore(endDate) || 
                                          course.date.isAtSameMomentAs(endDate)).toList();
      }
      
      // Filtrer par type si nécessaire
      if (type != null) {
        courses = courses.where((course) => course.type == type).toList();
      }
      
      return courses;
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les détails d'un cours spécifique
  Future<Course> getCourseDetails(String courseId) async {
    try {
      final course = await _courseRepository.getCourse(courseId);
      if (course == null) {
        throw Exception('Cours introuvable');
      }
      return course;
    } catch (e) {
      rethrow;
    }
  }

  // Réserver un cours
  Future<bool> bookCourse({
    required String userId,
    required String courseId,
    required String membershipCardId,
  }) async {
    try {
      // Vérifier que le cours existe et a des places disponibles
      final course = await _courseRepository.getCourse(courseId);
      if (course == null) {
        throw Exception('Cours introuvable');
      }
      
      if (course.currentParticipants >= course.capacity) {
        throw Exception('Ce cours est complet');
      }
      
      // Vérifier que la carte d'abonnement est valide
      final card = await _membershipRepository.getMembershipCard(membershipCardId);
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
        throw Exception('Cette carte ne permet pas de réserver ce type de cours');
      }
      
      // Créer la réservation
      final booking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        courseId: courseId,
        bookingDate: DateTime.now(),
        status: 'confirmed',
        membershipCardId: membershipCardId,
      );
      
      await _bookingRepository.createBooking(booking);
      
      // Décrémenter le nombre de séances restantes sur la carte
      await _membershipRepository.decrementRemainingSession(membershipCardId);
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Annuler une réservation
  Future<bool> cancelBooking(String bookingId) async {
    try {
      // Vérifier que la réservation existe
      final booking = await _bookingRepository.getBooking(bookingId);
      if (booking == null) {
        throw Exception('Réservation introuvable');
      }
      
      // Vérifier que le cours n'a pas déjà eu lieu
      final course = await _courseRepository.getCourse(booking.courseId);
      if (course == null) {
        throw Exception('Cours introuvable');
      }
      
      final now = DateTime.now();
      if (course.date.isBefore(now)) {
        throw Exception('Impossible d\'annuler une réservation pour un cours déjà passé');
      }
      
      // Mettre à jour le statut de la réservation
      await _bookingRepository.updateBooking(bookingId, {'status': 'cancelled'});
      
      // Re-créditer la séance sur la carte d'abonnement si la réservation est annulée au moins 24h avant
      final courseDateTime = DateTime(
        course.date.year, course.date.month, course.date.day,
        int.parse(course.startTime.split(':')[0]), 
        int.parse(course.startTime.split(':')[1])
      );
      
      final cancellationDeadline = courseDateTime.subtract(const Duration(hours: 24));
      
      if (now.isBefore(cancellationDeadline) && booking.membershipCardId != null) {
        // Mettre à jour le nombre de séances restantes (+1)
        final card = await _membershipRepository.getMembershipCard(booking.membershipCardId!);
        if (card != null) {
          await _membershipRepository.updateMembershipCard(
            booking.membershipCardId!,
            {'remaining_sessions': card.remainingSessions + 1}
          );
        }
      }
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les réservations d'un utilisateur
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      return await _bookingRepository.getUserBookings(userId);
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les cours à venir
  Future<List<Course>> getUpcomingCourses() async {
    try {
      final courses = await _courseRepository.getUpcomingCourses();
      return courses;
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les cours par type
  Future<List<Course>> getCoursesByType(String type) async {
    try {
      return await _courseRepository.getCoursesByType(type);
    } catch (e) {
      rethrow;
    }
  }

  // Marquer un booking comme complété (après le cours)
  Future<bool> markBookingAsCompleted(String bookingId) async {
    try {
      await _bookingRepository.updateBooking(bookingId, {'status': 'completed'});
      return true;
    } catch (e) {
      rethrow;
    }
  }
}