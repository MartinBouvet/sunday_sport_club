import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseBookingDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    final response = await _client
        .from('bookings')
        .select('*, courses(*)')
        .eq('user_id', userId)
        .order('booking_date', ascending: false);
    return response;
  }

  Future<List<Map<String, dynamic>>> getCourseBookings(String courseId) async {
    final response = await _client
        .from('bookings')
        .select('*, profiles(*)')
        .eq('course_id', courseId);
    return response;
  }

  Future<Map<String, dynamic>> getBooking(String bookingId) async {
    final response =
        await _client
            .from('bookings')
            .select('*, courses(*), profiles(*)')
            .eq('id', bookingId)
            .single();
    return response;
  }

  Future<String> createBooking(Map<String, dynamic> bookingData) async {
    // Commencer une transaction pour incrémenter le nombre de participants
    try {
      // 1. Insérer la réservation
      final bookingResponse =
          await _client.from('bookings').insert(bookingData).select();

      final bookingId = bookingResponse[0]['id'];
      final courseId = bookingData['course_id'];

      // 2. Incrémenter le nombre de participants au cours
      await _client.rpc(
        'increment_course_participants',
        params: {'course_id_param': courseId},
      );

      // 3. Si un ID de carte est fourni, décrémenter les sessions restantes
      if (bookingData['membership_card_id'] != null) {
        await _client.rpc(
          'decrement_card_sessions',
          params: {'card_id_param': bookingData['membership_card_id']},
        );
      }

      return bookingId;
    } catch (e) {
      throw Exception('Erreur lors de la création de la réservation: $e');
    }
  }

  Future<void> updateBooking(
    String bookingId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('bookings').update(data).eq('id', bookingId);
  }

  Future<void> deleteBooking(String bookingId) async {
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
  }
}
