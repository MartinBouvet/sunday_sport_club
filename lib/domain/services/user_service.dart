import '../../data/repositories/user_repository.dart';
import '../../data/models/user.dart';
import '../../domain/services/notification_service.dart';

class UserService {
  final UserRepository _userRepository = UserRepository();
  final NotificationService _notificationService = NotificationService();

  // Get user by ID
  Future<User?> getUserById(String userId) async {
    return await _userRepository.getUser(userId);
  }

  // Update user profile information
  Future<void> updateUserProfile(String userId, {
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
    if (!['mince', 'moyen', 'muscle'].contains(stage)) {
      throw ArgumentError('Invalid avatar stage. Must be one of: mince, moyen, muscle');
    }
    
    final user = await _userRepository.getUser(userId);
    if (user != null && user.avatarStage != stage) {
      await _userRepository.updateUser(userId, {'avatar_stage': stage});
      
      // Notify user about avatar evolution
      await _notificationService.sendAvatarEvolutionNotification(userId, stage);
    }
  }

  // Update user physical stats (weight, endurance, strength)
  Future<void> updateUserStats(String userId, {
    double? weight,
    int? endurance,
    int? strength,
  }) async {
    final Map<String, dynamic> userData = {};
    
    if (weight != null && weight > 0) userData['weight'] = weight;
    if (endurance != null && endurance > 0) userData['endurance'] = endurance;
    if (strength != null && strength > 0) userData['strength'] = strength;
    
    if (userData.isNotEmpty) {
      await _userRepository.updateUser(userId, userData);
    }
  }

  // Add experience points to user and handle level progression
  Future<Map<String, dynamic>> addExperiencePoints(String userId, int points) async {
    if (points <= 0) {
      throw ArgumentError('Experience points must be positive');
    }
    
    // Get current user to calculate new level
    final user = await _userRepository.getUser(userId);
    
    if (user == null) {
      throw Exception('User not found');
    }
    
    // Calculate new experience and level
    int currentExp = user.experiencePoints ?? 0;
    int newExp = currentExp + points;
    
    // Level calculation formula (adjust as needed)
    // This uses a simple formula where every 100 points = 1 level
    int currentLevel = user.level ?? 1;
    int newLevel = (newExp / 100).floor() + 1;
    
    bool leveledUp = newLevel > currentLevel;
    
    // Determine avatar stage based on level
    String currentAvatarStage = user.avatarStage ?? 'mince';
    String newAvatarStage = currentAvatarStage;
    
    // Logic for avatar progression
    if (newLevel >= 20 && currentAvatarStage != 'muscle') {
      newAvatarStage = 'muscle';
    } else if (newLevel >= 10 && currentAvatarStage == 'mince') {
      newAvatarStage = 'moyen';
    }
    
    bool avatarEvolved = newAvatarStage != currentAvatarStage;
    
    // Update user with new experience, level and avatar stage
    await _userRepository.updateUser(userId, {
      'experience_points': newExp,
      'level': newLevel,
      'avatar_stage': newAvatarStage,
    });
    
    // Send notifications if applicable
    if (leveledUp) {
      await _notificationService.sendLevelUpNotification(userId, newLevel);
    }
    
    if (avatarEvolved) {
      await _notificationService.sendAvatarEvolutionNotification(userId, newAvatarStage);
    }
    
    return {
      'leveledUp': leveledUp,
      'newLevel': newLevel,
      'avatarEvolved': avatarEvolved,
      'newAvatarStage': newAvatarStage,
      'addedPoints': points,
      'totalPoints': newExp,
    };
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
  
  // Get all users (admin only)
  Future<List<User>> getAllUsers() async {
    // This would need to be implemented in your repository
    // return await _userRepository.getAllUsers();
    return [];
  }
  
  // Get users filtered by status (active/inactive)
  Future<List<User>> getUsersByStatus(bool isActive) async {
    // This would need to be implemented in your repository
    // return await _userRepository.getUsersByStatus(isActive);
    return [];
  }
  
  // Check if user has completed daily challenges
  Future<bool> hasCompletedDailyChallenge(String userId) async {
    // This would need to be implemented with a challenge repository
    // final challengeRepository = ChallengeRepository();
    // return await challengeRepository.hasUserCompletedTodayChallenge(userId);
    return false;
  }
  
  // Calculate user ranking
  Future<int> calculateUserRanking(String userId) async {
    // This would calculate the user's position in the leaderboard
    // 1. Get all users sorted by experience points
    // 2. Find the index of the current user
    
    // Placeholder
    return 1;
  }
}