import 'package:flutter/foundation.dart';

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
    try {
      // Extraction sécurisée des données avec logging
      final String id = json['id']?.toString() ?? '';
      if (id.isEmpty) {
        debugPrint('WARNING: UserRoutine ID manquant dans: $json');
      }
      
      // Déterminer le nom correct de la colonne user_id
      String userId = '';
      if (json.containsKey('user_id')) {
        userId = json['user_id']?.toString() ?? '';
      } else if (json.containsKey('userid')) {
        userId = json['userid']?.toString() ?? '';
      } else if (json.containsKey('profile_id')) {
        userId = json['profile_id']?.toString() ?? '';
      }
      
      if (userId.isEmpty) {
        debugPrint('WARNING: UserID manquant dans UserRoutine: $json');
      }
      
      // Extraction du routineId, avec support pour différentes structures possibles
      String routineId = '';
      if (json.containsKey('routine_id')) {
        routineId = json['routine_id']?.toString() ?? '';
      } else if (json.containsKey('routineid')) {
        routineId = json['routineid']?.toString() ?? '';
      } else if (json.containsKey('routines') && json['routines'] is Map<String, dynamic>) {
        routineId = json['routines']['id']?.toString() ?? '';
      }
      
      if (routineId.isEmpty) {
        debugPrint('WARNING: RoutineID manquant dans UserRoutine: $json');
      }
      
      // Vérification et conversion des dates
      DateTime assignedDate;
      try {
        assignedDate = json['assigned_date'] != null 
            ? DateTime.parse(json['assigned_date']) 
            : DateTime.now();
      } catch (e) {
        debugPrint('WARNING: Format de date incorrect pour assigned_date: ${json['assigned_date']}');
        assignedDate = DateTime.now();
      }
      
      // Status avec valeur par défaut
      final String status = json['status']?.toString() ?? 'pending';
      
      // Date de complétion optionnelle
      DateTime? completionDate;
      if (json['completion_date'] != null) {
        try {
          completionDate = DateTime.parse(json['completion_date']);
        } catch (e) {
          debugPrint('WARNING: Format de date incorrect pour completion_date: ${json['completion_date']}');
        }
      }
      
      return UserRoutine(
        id: id,
        userId: userId,
        routineId: routineId,
        assignedDate: assignedDate,
        status: status,
        completionDate: completionDate,
        validatedBy: json['validated_by']?.toString(),
        experienceGained: json['experience_gained'] is int ? json['experience_gained'] : null,
        feedback: json['feedback']?.toString(),
      );
    } catch (e) {
      debugPrint('ERREUR lors du parsing UserRoutine: $e');
      // Fournir un objet minimal mais valide plutôt que de planter
      return UserRoutine(
        id: json['id']?.toString() ?? 'error-${DateTime.now().millisecondsSinceEpoch}',
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
      'user_id': userId,
      'routine_id': routineId,
      'assigned_date': assignedDate.toIso8601String(),
      'status': status,
    };
    
    if (completionDate != null) {
      data['completion_date'] = completionDate?.toIso8601String();
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