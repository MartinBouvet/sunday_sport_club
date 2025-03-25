import '../../data/repositories/user_repository.dart';
import '../../data/models/progress_tracking.dart';

class ProgressService {
  final UserRepository _userRepository = UserRepository();

  // Enregistrer progression
  Future<void> recordProgress(
    String userId, {
    required double weight,
    required int endurance,
    required int strength,
    String? notes,
  }) async {
    // Mise à jour stats utilisateur
    await _userRepository.updateUser(userId, {
      'weight': weight,
      'endurance': endurance,
      'strength': strength,
    });
  }

  // Obtenir historique progression
  Future<List<ProgressTracking>> getProgressHistory(String userId) async {
    // Retourne liste vide (implémenter avec vrai repository plus tard)
    return [];
  }

  // Obtenir dernière progression
  Future<ProgressTracking?> getLatestProgress(String userId) async {
    // Retourne null (implémenter avec vrai repository plus tard)
    return null;
  }

  // Mettre à jour avatar selon progression
  Future<void> updateAvatarBasedOnProgress(String userId) async {
    final user = await _userRepository.getUser(userId);

    if (user != null) {
      String avatarStage = 'mince';

      // Logique avatar basée sur force
      if (user.strength >= 20) {
        avatarStage = 'muscle';
      } else if (user.strength >= 10) {
        avatarStage = 'moyen';
      }

      // Mise à jour si différent
      if (user.avatarStage != avatarStage) {
        await _userRepository.updateUser(userId, {'avatar_stage': avatarStage});
      }
    }
  }
}
