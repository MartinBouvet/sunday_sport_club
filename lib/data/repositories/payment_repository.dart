import '../datasources/supabase/supabase_payment_datasource.dart';
import '../models/payment.dart';

class PaymentRepository {
  final SupabasePaymentDatasource _datasource = SupabasePaymentDatasource();

  Future<List<Payment>> getUserPayments(String userId) async {
    try {
      final paymentsData = await _datasource.getUserPayments(userId);
      return paymentsData.map((data) => Payment.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<Payment?> getPayment(String paymentId) async {
    try {
      final paymentData = await _datasource.getPayment(paymentId);
      return Payment.fromJson(paymentData);
    } catch (e) {
      return null;
    }
  }

  Future<String> createPayment(Payment payment) async {
    return await _datasource.createPayment(payment.toJson());
  }

  Future<void> updatePaymentStatus(String paymentId, String status) async {
    await _datasource.updatePaymentStatus(paymentId, status);
  }

  Future<List<Payment>> getAllPayments() async {
    try {
      final paymentsData = await _datasource.getAllPayments();
      return paymentsData.map((data) => Payment.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }
}
