import 'package:intl/intl.dart';

class ProfileAchievement {
  final String id;
  final String profileId;
  final String achievementId;
  final DateTime earnedDate;
  final int? progressValue;
  final bool isDisplayed;
  final DateTime? lastUpdated;

  ProfileAchievement({
    required this.id,
    required this.profileId,
    required this.achievementId,
    required this.earnedDate,
    this.progressValue,
    required this.isDisplayed,
    this.lastUpdated,
  });

  factory ProfileAchievement.fromJson(Map<String, dynamic> json) {
    return ProfileAchievement(
      id: json['id'],
      profileId: json['profile_id'],
      achievementId: json['achievement_id'],
      earnedDate: DateTime.parse(json['earned_date']),
      progressValue: json['progress_value'],
      isDisplayed: json['is_displayed'] ?? true,
      lastUpdated: json['last_updated'] != null 
          ? DateTime.parse(json['last_updated']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'achievement_id': achievementId,
      'earned_date': earnedDate.toIso8601String(),
      'progress_value': progressValue,
      'is_displayed': isDisplayed,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  ProfileAchievement copyWith({
    String? id,
    String? profileId,
    String? achievementId,
    DateTime? earnedDate,
    int? progressValue,
    bool? isDisplayed,
    DateTime? lastUpdated,
  }) {
    return ProfileAchievement(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      achievementId: achievementId ?? this.achievementId,
      earnedDate: earnedDate ?? this.earnedDate,
      progressValue: progressValue ?? this.progressValue,
      isDisplayed: isDisplayed ?? this.isDisplayed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  // Method to update progress value
  ProfileAchievement updateProgress(int newValue) {
    return copyWith(
      progressValue: newValue,
      lastUpdated: DateTime.now(),
    );
  }

  // Format earned date for display
  String get formattedEarnedDate {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(earnedDate);
  }

  @override
  String toString() {
    return 'ProfileAchievement{id: $id, profileId: $profileId, achievementId: $achievementId, earnedDate: $earnedDate}';
  }
}

// Make sure to import this at the top of the file
