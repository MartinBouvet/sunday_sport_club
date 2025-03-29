import '../datasources/supabase/supabase_challenge_datasource.dart';
import '../models/daily_challenge.dart';
import '../models/user_challenge.dart';

class ChallengeRepository {
  final SupabaseChallengeDatasource _datasource = SupabaseChallengeDatasource();

  // Récupérer tous les défis
  Future<List<DailyChallenge>> getAllChallenges() async {
    try {
      final challengesData = await _datasource.getAllChallenges();
      if (challengesData.isEmpty) {
        // Retourne des données de démonstration si aucun défi n'est trouvé
        return _getMockChallenges();
      }
      return challengesData
          .map((data) => DailyChallenge.fromJson(data))
          .toList();
    } catch (e) {
      // En cas d'erreur, retourner des données de démonstration
      return _getMockChallenges();
    }
  }

  // Créer des défis de démonstration
  List<DailyChallenge> _getMockChallenges() {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    return [
      DailyChallenge(
        id: "challenge-1",
        title: "10 minutes de gainage",
        description:
            "Maintenez une position de planche pendant 10 minutes, répartis sur la journée.",
        experiencePoints: 15,
        date: yesterday,
        exerciseIds: ["ex-1", "ex-2"],
        difficulty: "facile",
      ),
      DailyChallenge(
        id: "challenge-2",
        title: "30 burpees en 5 minutes",
        description: "Réalisez 30 burpees complets en moins de 5 minutes.",
        experiencePoints: 25,
        date: today,
        exerciseIds: ["ex-3"],
        difficulty: "intermédiaire",
      ),
      DailyChallenge(
        id: "challenge-3",
        title: "100 pompes réparties",
        description:
            "Effectuez 100 pompes au cours de la journée, par séries de votre choix.",
        experiencePoints: 20,
        date: tomorrow,
        exerciseIds: ["ex-4"],
        difficulty: "difficile",
      ),
    ];
  }

  // Récupérer un défi spécifique
  Future<DailyChallenge?> getChallenge(String challengeId) async {
    try {
      final challengeData = await _datasource.getChallenge(challengeId);
      return DailyChallenge.fromJson(challengeData);
    } catch (e) {
      // Rechercher dans les défis de démonstration
      try {
        return _getMockChallenges().firstWhere((c) => c.id == challengeId);
      } catch (_) {
        return null;
      }
    }
  }

  // Récupérer le défi du jour
  Future<DailyChallenge?> getDailyChallenge(DateTime date) async {
    try {
      final challengeData = await _datasource.getDailyChallenge(date);
      if (challengeData != null) {
        return DailyChallenge.fromJson(challengeData);
      }

      // Si aucun défi n'est trouvé pour cette date, chercher dans les défis de démonstration
      final formattedDate = DateTime(date.year, date.month, date.day);
      final mockChallenges = _getMockChallenges();

      for (var challenge in mockChallenges) {
        final challengeDate = DateTime(
          challenge.date.year,
          challenge.date.month,
          challenge.date.day,
        );
        if (challengeDate.isAtSameMomentAs(formattedDate)) {
          return challenge;
        }
      }

      return null;
    } catch (e) {
      // En cas d'erreur, essayer de retourner un défi de démonstration pour cette date
      try {
        final formattedDate = DateTime(date.year, date.month, date.day);
        return _getMockChallenges().firstWhere((c) {
          final challengeDate = DateTime(c.date.year, c.date.month, c.date.day);
          return challengeDate.isAtSameMomentAs(formattedDate);
        });
      } catch (_) {
        return null;
      }
    }
  }

  // Créer un défi
  Future<String> createChallenge(DailyChallenge challenge) async {
    try {
      return await _datasource.createChallenge(challenge.toJson());
    } catch (e) {
      throw Exception('Erreur lors de la création du défi: $e');
    }
  }

  // Mettre à jour un défi
  Future<void> updateChallenge(
    String challengeId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _datasource.updateChallenge(challengeId, data);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du défi: $e');
    }
  }

  // Supprimer un défi
  Future<void> deleteChallenge(String challengeId) async {
    try {
      await _datasource.deleteChallenge(challengeId);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du défi: $e');
    }
  }

  // Récupérer les défis d'un utilisateur
  Future<List<UserChallenge>> getUserChallenges(String userId) async {
    try {
      final userChallengesData = await _datasource.getUserChallenges(userId);
      return userChallengesData
          .map((data) => UserChallenge.fromJson(data))
          .toList();
    } catch (e) {
      // En cas d'erreur, retourner des défis utilisateur de démonstration
      return _getMockUserChallenges(userId);
    }
  }

  // Créer des défis utilisateur de démonstration
  List<UserChallenge> _getMockUserChallenges(String userId) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    return [
      UserChallenge(
        id: "user-challenge-1",
        userId: userId,
        challengeId: "challenge-1",
        assignedDate: yesterday,
        status: "completed",
        completionDate: yesterday.add(const Duration(hours: 18)),
        experienceGained: 15,
      ),
      UserChallenge(
        id: "user-challenge-2",
        userId: userId,
        challengeId: "challenge-2",
        assignedDate: today,
        status: "pending",
      ),
    ];
  }

  // Assigner un défi à un utilisateur
  Future<String> assignChallengeToUser(UserChallenge userChallenge) async {
    try {
      return await _datasource.assignChallengeToUser(userChallenge.toJson());
    } catch (e) {
      throw Exception('Erreur lors de l\'assignation du défi: $e');
    }
  }

  // Mettre à jour le statut d'un défi utilisateur
  Future<void> updateUserChallengeStatus(
    String userChallengeId,
    String status,
  ) async {
    try {
      await _datasource.updateUserChallengeStatus(userChallengeId, status);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }
}
