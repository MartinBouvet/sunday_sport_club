import 'package:flutter/foundation.dart';

class UserRoutine {
  final String id;
  final String userId;
  final String routineId;
  final DateTime assignedDate;
  final String status; // 'assigned', 'in_progress', 'completed', 'validated'
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

  // lib/data/models/user_routine.dart
  factory UserRoutine.fromJson(Map<String, dynamic> json) {
    try {
      // Normaliser les noms de champs
      final String userId = json['user_id'] ?? json['profile_id'] ?? '';
      final String routineId = json['routine_id'] ?? '';

      // Assurer la conversion de date correcte
      DateTime assignedDate = DateTime.now();
      try {
        if (json['assigned_date'] != null) {
          assignedDate = DateTime.parse(json['assigned_date']);
        }
      } catch (_) {}

      return UserRoutine(
        id: json['id'] ?? '',
        userId: userId,
        routineId: routineId,
        assignedDate: assignedDate,
        status: json['status'] ?? 'pending',
        completionDate:
            json['completion_date'] != null
                ? DateTime.parse(json['completion_date'])
                : null,
        validatedBy: json['validated_by'],
        experienceGained: json['experience_gained'],
        feedback: json['feedback'],
      );
    } catch (e) {
      debugPrint('Erreur parsing UserRoutine: $e');
      return UserRoutine(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        userId: '',
        routineId: '',
        assignedDate: DateTime.now(),
        status: 'error',
      );
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'profile_id':
          userId, // Utiliser profile_id pour compatibilité avec la base de données
      'routine_id': routineId,
      'assigned_date': assignedDate.toIso8601String(),
      'status': status,
    };

    if (completionDate != null) {
      data['completion_date'] = completionDate!.toIso8601String();
    }
    if (validatedBy != null) {
      data['validated_by'] = validatedBy;
    }
    if (experienceGained != null) {
      data['experience_gained'] = experienceGained;
    }
    if (feedback != null) {
      data['feedback'] = feedback;
    }

    return data;
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

  @override
  String toString() {
    return 'UserRoutine{id: $id, userId: $userId, routineId: $routineId, status: $status}';
  }
}
