import '../../data/repositories/user_repository.dart';
import '../../data/models/user.dart';

class BookingService {
  final UserRepository _userRepository = UserRepository();

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    return await _userRepository.getUser(userId);
  }

  // Update user profile
  Future<void> updateUserProfile(
    String userId, {
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? birthDate,
    String? gender,
    String? skinColor,
  }) async {
    final Map<String, dynamic> userData = {};

    if (firstName != null) userData['first_name'] = firstName;
    if (lastName != null) userData['last_name'] = lastName;
    if (phone != null) userData['phone'] = phone;
    if (birthDate != null) userData['birth_date'] = birthDate.toIso8601String();
    if (gender != null) userData['gender'] = gender;
    if (skinColor != null) userData['skin_color'] = skinColor;

    if (userData.isNotEmpty) {
      await _userRepository.updateUser(userId, userData);
    }
  }

  // Update user avatar stage
  Future<void> updateAvatarStage(String userId, String stage) async {
    await _userRepository.updateUser(userId, {'avatar_stage': stage});
  }

  // Update user stats (weight, endurance, strength)
  Future<void> updateUserStats(
    String userId, {
    double? weight,
    int? endurance,
    int? strength,
  }) async {
    final Map<String, dynamic> userData = {};

    if (weight != null) userData['weight'] = weight;
    if (endurance != null) userData['endurance'] = endurance;
    if (strength != null) userData['strength'] = strength;

    if (userData.isNotEmpty) {
      await _userRepository.updateUser(userId, userData);
    }
  }

  // Add experience points to user
  Future<void> addExperiencePoints(String userId, int points) async {
    // First get current user to calculate new level
    final user = await _userRepository.getUser(userId);

    if (user != null) {
      int currentExp = user.experiencePoints;
      int newExp = currentExp + points;

      // Simple level calculation (customize as needed)
      // For example: every 100 points = 1 level
      int newLevel = (newExp / 100).floor() + 1;

      // Update avatar stage based on level
      String avatarStage = user.avatarStage;
      if (newLevel >= 10 && avatarStage == 'mince') {
        avatarStage = 'moyen';
      } else if (newLevel >= 20 && avatarStage == 'moyen') {
        avatarStage = 'muscle';
      }

      // Update user with new experience, level and avatar stage
      await _userRepository.updateUser(userId, {
        'experience_points': newExp,
        'level': newLevel,
        'avatar_stage': avatarStage,
      });
    }
  }

  // Get top users for leaderboard
  Future<List<User>> getLeaderboard(int limit) async {
    // You would need to implement this in your repository
    // This is a placeholder that assumes you'll add this functionality

    // return await _userRepository.getTopUsersByExperience(limit);
    return [];
  }

  // Toggle user active status
  Future<void> toggleUserActiveStatus(String userId, bool isActive) async {
    await _userRepository.updateUser(userId, {'is_active': isActive});
  }
}
