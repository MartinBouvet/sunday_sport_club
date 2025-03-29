import 'package:flutter/foundation.dart';
import 'routine.dart';

class UserRoutine {
  final String id;
  final String userId;
  final String routineId;
  final DateTime assignedDate;
  final String status; // 'pending', 'in_progress', 'completed', 'validated'
  final DateTime? completionDate;
  final String? validatedBy;
  final int? experienceGained;
  final String? feedback;
  final Routine? routine; // Relation avec la routine

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
    this.routine,
  });

  factory UserRoutine.fromJson(Map<String, dynamic> json) {
    try {
      String userId = json['user_id'] ?? json['profile_id'] ?? '';
      String routineId = json['routine_id'] ?? '';

      DateTime assignedDate;
      try {
        assignedDate =
            json['assigned_date'] != null
                ? DateTime.parse(json['assigned_date'])
                : DateTime.now();
      } catch (e) {
        debugPrint('Erreur date assignedDate: $e');
        assignedDate = DateTime.now();
      }

      DateTime? completionDate;
      if (json['completion_date'] != null) {
        try {
          completionDate = DateTime.parse(json['completion_date']);
        } catch (e) {
          debugPrint('Erreur date completionDate: $e');
        }
      }

      // Récupération de la routine associée
      Routine? routine;
      if (json['routines'] != null) {
        try {
          routine = Routine.fromJson(json['routines']);
        } catch (e) {
          debugPrint('Erreur parsing routine associée: $e');
        }
      }

      return UserRoutine(
        id: json['id'] ?? '',
        userId: userId,
        routineId: routineId,
        assignedDate: assignedDate,
        status: json['status'] ?? 'pending',
        completionDate: completionDate,
        validatedBy: json['validated_by'],
        experienceGained: json['experience_gained'],
        feedback: json['feedback'],
        routine: routine,
      );
    } catch (e) {
      debugPrint('ERREUR parsing UserRoutine: $e');
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
}
