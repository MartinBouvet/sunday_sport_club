import 'package:flutter/material.dart';
import '../../data/models/course.dart';
import '../../data/models/booking.dart';
import '../../data/models/membership_card.dart';
import '../../data/repositories/course_repository.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/membership_repository.dart';

class BookingService {
  final CourseRepository _courseRepository = CourseRepository();
  final BookingRepository _bookingRepository = BookingRepository();
  final MembershipRepository _membershipRepository = MembershipRepository();

  // Récupérer tous les cours disponibles
  Future<List<Course>> getAvailableCourses() async {
    try {
      return await _courseRepository.getAllCourses();
    } catch (e) {
      debugPrint('Erreur getAvailableCourses: $e');
      return [];
    }
  }

  // Récupérer les cours filtrés par période et type
  Future<List<Course>> getFilteredCourses({
    DateTime? startDate,
    DateTime? endDate,
    String? type,
  }) async {
    try {
      List<Course> courses = await _courseRepository.getAllCourses();

      // Filtrer par dates
      if (startDate != null) {
        courses =
            courses
                .where(
                  (course) =>
                      course.date.isAfter(startDate) ||
                      course.date.isAtSameMomentAs(startDate),
                )
                .toList();
      }

      if (endDate != null) {
        courses =
            courses
                .where(
                  (course) =>
                      course.date.isBefore(endDate) ||
                      course.date.isAtSameMomentAs(endDate),
                )
                .toList();
      }

      // Filtrer par type
      if (type != null && type != 'all') {
        courses = courses.where((course) => course.type == type).toList();
      }

      return courses;
    } catch (e) {
      debugPrint('Erreur getFilteredCourses: $e');
      return [];
    }
  }

  // Récupérer les cartes d'abonnement d'un utilisateur
  Future<List<MembershipCard>> getUserCards(String userId) async {
    try {
      return await _membershipRepository.getUserMembershipCards(userId);
    } catch (e) {
      debugPrint('Erreur getUserCards: $e');
      return [];
    }
  }

  // Récupérer les cartes d'abonnement valides pour un cours spécifique
  Future<List<MembershipCard>> getValidCardsForCourse(
    String userId,
    Course course,
  ) async {
    try {
      final allCards = await getUserCards(userId);
      final now = DateTime.now();

      // Filtrer les cartes valides (non expirées et avec des séances restantes)
      return allCards.where((card) {
        final bool hasRemainingSession = card.remainingSessions > 0;
        final bool notExpired = card.expiryDate.isAfter(now);

        // Vérifier que le type de carte correspond au type de cours
        // Les cartes collectives peuvent être utilisées pour les deux types de cours
        // Les cartes individuelles seulement pour les cours individuels
        final bool validType =
            card.type == 'collectif' || card.type == course.type;

        return hasRemainingSession && notExpired && validType;
      }).toList();
    } catch (e) {
      debugPrint('Erreur getValidCardsForCourse: $e');
      return [];
    }
  }

  // Créer une réservation
  Future<bool> createBooking({
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

      // Créer l'objet de réservation
      final booking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        courseId: courseId,
        bookingDate: DateTime.now(),
        status: 'confirmed',
        membershipCardId: membershipCardId,
      );

      // Enregistrer la réservation
      await _bookingRepository.createBooking(booking);

      // Décrémenter le nombre de séances sur la carte
      await _membershipRepository.decrementRemainingSession(membershipCardId);

      return true;
    } catch (e) {
      debugPrint('Erreur createBooking: $e');
      return false;
    }
  }

  // Récupérer les réservations d'un utilisateur
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      return await _bookingRepository.getUserBookings(userId);
    } catch (e) {
      debugPrint('Erreur getUserBookings: $e');
      return [];
    }
  }

  // Annuler une réservation
  Future<bool> cancelBooking(String bookingId) async {
    try {
      // Obtenir les détails de la réservation
      final booking = await _bookingRepository.getBooking(bookingId);
      if (booking == null) {
        throw Exception('Réservation introuvable');
      }

      // Mettre à jour le statut de la réservation
      await _bookingRepository.updateBooking(bookingId, {
        'status': 'cancelled',
      });

      // Re-créditer la séance si la réservation est annulée au moins 24h avant
      if (booking.membershipCardId != null) {
        final course = await _courseRepository.getCourse(booking.courseId);
        if (course != null) {
          final now = DateTime.now();
          final courseDateTime = DateTime(
            course.date.year,
            course.date.month,
            course.date.day,
            int.parse(course.startTime.split(':')[0]),
            int.parse(course.startTime.split(':')[1]),
          );

          final cancellationDeadline = courseDateTime.subtract(
            const Duration(hours: 24),
          );

          if (now.isBefore(cancellationDeadline)) {
            // Mettre à jour le nombre de séances restantes (+1)
            final card = await _membershipRepository.getMembershipCard(
              booking.membershipCardId!,
            );
            if (card != null) {
              await _membershipRepository.updateMembershipCard(
                booking.membershipCardId!,
                {'remaining_sessions': card.remainingSessions + 1},
              );
            }
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Erreur cancelBooking: $e');
      return false;
    }
  }
}
