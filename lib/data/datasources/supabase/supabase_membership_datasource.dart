import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/supabase_client.dart';

class SupabaseMembershipDatasource {
  final SupabaseClient _client = supabase;

  Future<List<Map<String, dynamic>>> getUserMembershipCards(
    String userId,
  ) async {
    try {
      final response = await _client
          .from('membership_cards')
          .select()
          .eq('user_id', userId)
          .order('purchase_date', ascending: false);
      return response;
    } catch (e) {
      debugPrint("Error fetching membership cards: $e");
      // Retourner des cartes mock pour le développement
      return _getMockCards(userId);
    }
  }

  List<Map<String, dynamic>> _getMockCards(String userId) {
    final now = DateTime.now();
    return [
      {
        'id': 'card-1',
        'user_id': userId,
        'type': 'individuel',
        'total_sessions': 10,
        'remaining_sessions': 5,
        'purchase_date':
            now.subtract(const Duration(days: 45)).toIso8601String(),
        'expiry_date': now.add(const Duration(days: 90)).toIso8601String(),
        'price': 350.0,
        'payment_status': 'completed',
      },
      {
        'id': 'card-2',
        'user_id': userId,
        'type': 'collectif',
        'total_sessions': 20,
        'remaining_sessions': 15,
        'purchase_date':
            now.subtract(const Duration(days: 15)).toIso8601String(),
        'expiry_date': now.add(const Duration(days: 180)).toIso8601String(),
        'price': 280.0,
        'payment_status': 'completed',
      },
    ];
  }

  Future<Map<String, dynamic>> getMembershipCard(String cardId) async {
    try {
      final response =
          await _client
              .from('membership_cards')
              .select()
              .eq('id', cardId)
              .single();
      return response;
    } catch (e) {
      // Retourner une carte mock pour le développement
      if (cardId.startsWith('card-')) {
        final now = DateTime.now();
        return {
          'id': cardId,
          'user_id': 'mock-user',
          'type': cardId == 'card-1' ? 'individuel' : 'collectif',
          'total_sessions': 10,
          'remaining_sessions': 5,
          'purchase_date':
              now.subtract(const Duration(days: 30)).toIso8601String(),
          'expiry_date': now.add(const Duration(days: 180)).toIso8601String(),
          'price': 350.0,
          'payment_status': 'completed',
        };
      }
      debugPrint("Error fetching membership card: $e");
      throw Exception('Carte introuvable');
    }
  }

  Future<String> createMembershipCard(Map<String, dynamic> cardData) async {
    try {
      final response =
          await _client.from('membership_cards').insert(cardData).select();
      return response[0]['id'];
    } catch (e) {
      debugPrint("Error creating membership card: $e");
      // Pour le développement, retourner un ID fictif
      return 'card-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> updateMembershipCard(
    String cardId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _client.from('membership_cards').update(data).eq('id', cardId);
    } catch (e) {
      debugPrint("Error updating membership card: $e");
      // Pour le développement, ignorer l'erreur
    }
  }

  Future<void> deleteMembershipCard(String cardId) async {
    try {
      await _client.from('membership_cards').delete().eq('id', cardId);
    } catch (e) {
      debugPrint("Error deleting membership card: $e");
      // Pour le développement, ignorer l'erreur
    }
  }

  Future<bool> decrementRemainingSession(String cardId) async {
    try {
      // Simuler un succès en mode développement pour les cartes mock
      if (cardId.startsWith('card-')) {
        debugPrint("Mocking decrement for card: $cardId");
        return true;
      }

      await _client.rpc(
        'decrement_card_sessions',
        params: {'card_id_param': cardId},
      );
      return true;
    } catch (e) {
      debugPrint("Error decrementing card sessions: $e");
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveUserCards(String userId) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('membership_cards')
          .select()
          .eq('user_id', userId)
          .gt('remaining_sessions', 0)
          .gt('expiry_date', now);
      return response;
    } catch (e) {
      debugPrint("Error fetching active cards: $e");
      return _getMockCards(userId)
          .where(
            (card) =>
                card['remaining_sessions'] > 0 &&
                DateTime.parse(card['expiry_date']).isAfter(DateTime.now()),
          )
          .toList();
    }
  }
}
