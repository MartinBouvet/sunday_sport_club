class UserRoutine {
  final String id;
  final String userId;
  final String routineId;
  final DateTime assignedDate;
  final String status; // 'pending', 'in_progress', 'completed', 'validated'
  final DateTime? completionDate;
  final String? validatedBy; // ID du coach qui a validé la routine
  final int? experienceGained;
  final String? feedback;

  UserRoutine({
    required this.id,
    required this.userId,
    required this.routineId,
    required this.assignedDate,
    required this.status,
    this.completionDate,
    this.validatedBy,
    this.experienceGained,
    this.feedback,
  });

  factory UserRoutine.fromJson(Map<String, dynamic> json) {
    return UserRoutine(
      id: json['id'],
      userId: json['user_id'],
      routineId: json['routine_id'],
      assignedDate: DateTime.parse(json['assigned_date']),
      status: json['status'],
      completionDate: json['completion_date'] != null ? DateTime.parse(json['completion_date']) : null,
      validatedBy: json['validated_by'],
      experienceGained: json['experience_gained'],
      feedback: json['feedback'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'routine_id': routineId,
      'assigned_date': assignedDate.toIso8601String(),
      'status': status,
      'completion_date': completionDate?.toIso8601String(),
      'validated_by': validatedBy,
      'experience_gained': experienceGained,
      'feedback': feedback,
    };
  }

  UserRoutine copyWith({
    String? id,
    String? userId,
    String? routineId,
    DateTime? assignedDate,
    String? status,
    DateTime? completionDate,
    String? validatedBy,
    int? experienceGained,
    String? feedback,
  }) {
    return UserRoutine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      routineId: routineId ?? this.routineId,
      assignedDate: assignedDate ?? this.assignedDate,
      status: status ?? this.status,
      completionDate: completionDate ?? this.completionDate,
      validatedBy: validatedBy ?? this.validatedBy,
      experienceGained: experienceGained ?? this.experienceGained,
      feedback: feedback ?? this.feedback,
    );
  }
}