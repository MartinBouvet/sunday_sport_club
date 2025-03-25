class UserChallenge {
  final String id;
  final String userId;
  final String challengeId;
  final DateTime assignedDate;
  final String status; // 'pending', 'completed', 'failed'
  final DateTime? completionDate;
  final int? experienceGained;

  UserChallenge({
    required this.id,
    required this.userId,
    required this.challengeId,
    required this.assignedDate,
    required this.status,
    this.completionDate,
    this.experienceGained,
  });

  factory UserChallenge.fromJson(Map<String, dynamic> json) {
    return UserChallenge(
      id: json['id'],
      userId: json['user_id'],
      challengeId: json['challenge_id'],
      assignedDate: DateTime.parse(json['assigned_date']),
      status: json['status'],
      completionDate:
          json['completion_date'] != null
              ? DateTime.parse(json['completion_date'])
              : null,
      experienceGained: json['experience_gained'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'challenge_id': challengeId,
      'assigned_date': assignedDate.toIso8601String(),
      'status': status,
      'completion_date': completionDate?.toIso8601String(),
      'experience_gained': experienceGained,
    };
  }

  UserChallenge copyWith({
    String? id,
    String? userId,
    String? challengeId,
    DateTime? assignedDate,
    String? status,
    DateTime? completionDate,
    int? experienceGained,
  }) {
    return UserChallenge(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      assignedDate: assignedDate ?? this.assignedDate,
      status: status ?? this.status,
      completionDate: completionDate ?? this.completionDate,
      experienceGained: experienceGained ?? this.experienceGained,
    );
  }
}
