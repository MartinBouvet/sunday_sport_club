import '../datasources/supabase/supabase_membership_datasource.dart';
import '../models/membership_card.dart';

class MembershipRepository {
  final SupabaseMembershipDatasource _datasource =
      SupabaseMembershipDatasource();

  Future<List<MembershipCard>> getUserMembershipCards(String userId) async {
    try {
      final cardsData = await _datasource.getUserMembershipCards(userId);
      return cardsData.map((data) => MembershipCard.fromJson(data)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<MembershipCard?> getMembershipCard(String cardId) async {
    try {
      final cardData = await _datasource.getMembershipCard(cardId);
      return MembershipCard.fromJson(cardData);
    } catch (e) {
      return null;
    }
  }

  Future<String> createMembershipCard(MembershipCard card) async {
    return await _datasource.createMembershipCard(card.toJson());
  }

  Future<void> updateMembershipCard(
    String cardId,
    Map<String, dynamic> data,
  ) async {
    await _datasource.updateMembershipCard(cardId, data);
  }

  Future<void> deleteMembershipCard(String cardId) async {
    await _datasource.deleteMembershipCard(cardId);
  }

  Future<bool> decrementRemainingSession(String cardId) async {
    return await _datasource.decrementRemainingSession(cardId);
  }
}
