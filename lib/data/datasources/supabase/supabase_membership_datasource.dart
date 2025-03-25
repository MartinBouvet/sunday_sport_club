import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseMembershipDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getUserMembershipCards(
    String userId,
  ) async {
    final response = await _client
        .from('membership_cards')
        .select()
        .eq('user_id', userId)
        .order('purchase_date', ascending: false);
    return response;
  }

  Future<Map<String, dynamic>> getMembershipCard(String cardId) async {
    final response =
        await _client
            .from('membership_cards')
            .select()
            .eq('id', cardId)
            .single();
    return response;
  }

  Future<String> createMembershipCard(Map<String, dynamic> cardData) async {
    final response =
        await _client.from('membership_cards').insert(cardData).select();
    return response[0]['id'];
  }

  Future<void> updateMembershipCard(
    String cardId,
    Map<String, dynamic> data,
  ) async {
    await _client.from('membership_cards').update(data).eq('id', cardId);
  }

  Future<void> deleteMembershipCard(String cardId) async {
    await _client.from('membership_cards').delete().eq('id', cardId);
  }

  Future<bool> decrementRemainingSession(String cardId) async {
    try {
      final result = await _client.rpc(
        'decrement_card_sessions',
        params: {'card_id_param': cardId},
      );
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveUserCards(String userId) async {
    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from('membership_cards')
        .select()
        .eq('user_id', userId)
        .gt('remaining_sessions', 0)
        .gt('expiry_date', now);
    return response;
  }
}
