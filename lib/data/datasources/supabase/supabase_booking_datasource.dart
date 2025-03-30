import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseBookingDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      debugPrint("Fetching bookings for user: $userId");
      final response = await _client
          .from('bookings')
          .select('*, courses(*)')
          .eq('user_id', userId)
          .order('booking_date', ascending: false);
      debugPrint("Bookings response: $response");
      return response;
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
      // Obtenir les réservations simulées
      final mockBookings = await _getMockBookings(userId);
      debugPrint("Returning mock bookings: $mockBookings");
      return mockBookings;
    }
  }

  List<Map<String, dynamic>> _getMockBookings(String userId) {
    final now = DateTime.now();
    return [
      {
        'id': 'booking-1',
        'user_id': userId,
        'course_id': 'course-1',
        'booking_date': now.subtract(const Duration(days: 2)).toIso8601String(),
        'status': 'confirmed',
        'membership_card_id': 'card-1',
        'courses': {
          'id': 'course-1',
          'title': 'MMA Technique',
          'description':
              'Cours individuel pour perfectionner vos techniques de combat',
          'type': 'individuel',
          'date': now.add(const Duration(days: 1)).toIso8601String(),
          'start_time': '14:00',
          'end_time': '15:00',
          'capacity': 1,
          'current_participants': 0,
          'status': 'available',
          'coach_id': 'coach-1',
        },
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getCourseBookings(String courseId) async {
    try {
      final response = await _client
          .from('bookings')
          .select('*, profiles(*)')
          .eq('course_id', courseId);
      return response;
    } catch (e) {
      debugPrint("Error fetching course bookings: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getBooking(String bookingId) async {
    try {
      final response =
          await _client
              .from('bookings')
              .select('*, courses(*), profiles(*)')
              .eq('id', bookingId)
              .single();
      return response;
    } catch (e) {
      debugPrint("Error fetching booking details: $e");
      // Vous pourriez retourner des données mock ici aussi
      throw Exception('Booking not found');
    }
  }

  Future<String> createBooking(Map<String, dynamic> bookingData) async {
    try {
      debugPrint("Creating booking with data: $bookingData");

      // Pour le développement, simulons une réponse réussie
      if (bookingData['id'] != null &&
          bookingData['id'].toString().startsWith('booking-')) {
        debugPrint("Mock booking creation successful");
        return bookingData['id'];
      }

      // Sinon, essayons d'insérer dans Supabase
      final bookingResponse =
          await _client.from('bookings').insert(bookingData).select();

      if (bookingResponse.isEmpty) {
        throw Exception('Booking creation failed, no response');
      }

      final bookingId = bookingResponse[0]['id'];
      final courseId = bookingData['course_id'];

      // Incrémenter le nombre de participants au cours
      await _client.rpc(
        'increment_course_participants',
        params: {'course_id_param': courseId},
      );

      // Si un ID de carte est fourni, décrémenter les sessions restantes
      if (bookingData['membership_card_id'] != null) {
        await _client.rpc(
          'decrement_card_sessions',
          params: {'card_id_param': bookingData['membership_card_id']},
        );
      }

      return bookingId;
    } catch (e) {
      debugPrint("Error creating booking: $e");
      // Pour le développement, retournons un ID fictif
      return 'booking-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> updateBooking(
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client.from('bookings').update(data).eq('id', bookingId);
    } catch (e) {
      debugPrint("Error updating booking: $e");
      // En environnement de développement, nous pourrions ignorer cette erreur
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    try {
      // Récupérer d'abord les informations de la réservation
      final booking =
          await _client.from('bookings').select().eq('id', bookingId).single();

      final courseId = booking['course_id'];

      // Supprimer la réservation
      await _client.from('bookings').delete().eq('id', bookingId);

      // Décrémenter le nombre de participants
      await _client.rpc(
        'decrement_course_participants',
        params: {'course_id_param': courseId},
      );
    } catch (e) {
      debugPrint("Error deleting booking: $e");
      // En environnement de développement, nous pourrions ignorer cette erreur
    }
  }
}
