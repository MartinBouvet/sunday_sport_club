import '../datasources/supabase/supabase_booking_datasource.dart';
import '../models/booking.dart';

class BookingRepository {
  final SupabaseBookingDatasource _datasource = SupabaseBookingDatasource();

  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final bookingsData = await _datasource.getUserBookings(userId);
      return bookingsData.map((data) => Booking.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Booking>> getCourseBookings(String courseId) async {
    try {
      final bookingsData = await _datasource.getCourseBookings(courseId);
      return bookingsData.map((data) => Booking.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Booking?> getBooking(String bookingId) async {
    try {
      final bookingData = await _datasource.getBooking(bookingId);
      return Booking.fromJson(bookingData);
    } catch (e) {
      return null;
    }
  }

  Future<String> createBooking(Booking booking) async {
    try {
      // Créer la réservation
      final bookingId = await _datasource.createBooking(booking.toJson());

      // Réduire le nombre de séances sur la carte d'abonnement si fournie
      if (booking.membershipCardId != null) {
        final membershipRepository = MembershipRepository();
        await membershipRepository.decrementRemainingSession(
          booking.membershipCardId!,
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
    await _datasource.updateBooking(bookingId, data);
  }

  Future<void> deleteBooking(String bookingId) async {
    await _datasource.deleteBooking(bookingId);
  }
}
