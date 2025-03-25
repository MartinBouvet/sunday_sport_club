import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabasePaymentDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getUserPayments(String userId) async {
    final response = await _client
        .from('payments')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);
    return response;
  }

  Future<Map<String, dynamic>> getPayment(String paymentId) async {
    final response =
        await _client.from('payments').select().eq('id', paymentId).single();
    return response;
  }

  Future<String> createPayment(Map<String, dynamic> paymentData) async {
    final response =
        await _client.from('payments').insert(paymentData).select();
    return response[0]['id'];
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    await _client
        .from('payments')
        .update({'status': status})
        .eq('id', paymentId);
  }

  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final response = await _client
        .from('payments')
        .select('*, profiles(first_name, last_name)')
        .order('date', ascending: false);
    return response;
  }

  Future<Map<String, dynamic>> getPaymentStatistics() async {
    // Statistiques mensuelles
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final lastMonthStart =
        DateTime(now.year, now.month - 1, 1).toIso8601String();
    final lastMonthEnd = DateTime(now.year, now.month, 0).toIso8601String();

    // Paiements du mois en cours
    final currentMonthPayments = await _client
        .from('payments')
        .select('amount, status')
        .gte('date', startOfMonth)
        .eq('status', 'completed');

    double currentMonthTotal = 0;
    for (var payment in currentMonthPayments) {
      currentMonthTotal += payment['amount'];
    }

    // Paiements du mois précédent
    final lastMonthPayments = await _client
        .from('payments')
        .select('amount, status')
        .gte('date', lastMonthStart)
        .lte('date', lastMonthEnd)
        .eq('status', 'completed');

    double lastMonthTotal = 0;
    for (var payment in lastMonthPayments) {
      lastMonthTotal += payment['amount'];
    }

    // Statistiques par type d'abonnement
    final membershipStats = await _client
        .from('payments')
        .select('type, amount')
        .eq('status', 'completed')
        .eq('type', 'membership');

    double membershipTotal = 0;
    for (var payment in membershipStats) {
      membershipTotal += payment['amount'];
    }

    // Statistiques pour les cours individuels
    final individualCourseStats = await _client
        .from('payments')
        .select('type, amount')
        .eq('status', 'completed')
        .eq('type', 'individual_course');

    double individualCourseTotal = 0;
    for (var payment in individualCourseStats) {
      individualCourseTotal += payment['amount'];
    }

    return {
      'current_month_total': currentMonthTotal,
      'last_month_total': lastMonthTotal,
      'month_over_month_change':
          lastMonthTotal > 0
              ? ((currentMonthTotal - lastMonthTotal) / lastMonthTotal) * 100
              : 0,
      'membership_total': membershipTotal,
      'individual_course_total': individualCourseTotal,
    };
  }
}
