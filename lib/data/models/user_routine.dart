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

  factory UserRoutine.fromJson(Map<String, dynamic> json) {
    debugPrint('Processing UserRoutine JSON: ${json.keys}');
    
    try {
      // Extraction de l'ID
      final String id = json['id']?.toString() ?? '';
      if (id.isEmpty) {
        debugPrint('WARNING: UserRoutine ID is missing');
      }
      
      // Extraction de l'ID utilisateur (vérifier les différentes clés possibles)
      String userId = '';
      if (json.containsKey('user_id')) {
        userId = json['user_id']?.toString() ?? '';
      } else if (json.containsKey('profile_id')) {
        userId = json['profile_id']?.toString() ?? '';
      }
      
      if (userId.isEmpty) {
        debugPrint('WARNING: UserID is missing in UserRoutine');
      }
      
      // Extraction du routineId avec support pour les données imbriquées
      String routineId = '';
      if (json.containsKey('routine_id')) {
        routineId = json['routine_id']?.toString() ?? '';
      } else if (json.containsKey('routines') && json['routines'] != null) {
        // Si les données de routine sont imbriquées (jointure)
        final routines = json['routines'];
        if (routines is Map<String, dynamic>) {
          routineId = routines['id']?.toString() ?? '';
          debugPrint('Found nested routine ID: $routineId');
        }
      }
      
      if (routineId.isEmpty) {
        debugPrint('WARNING: RoutineID is missing in UserRoutine data');
      }
      
      // Conversion sécurisée des dates
      DateTime assignedDate;
      try {
        assignedDate = json['assigned_date'] != null 
            ? DateTime.parse(json['assigned_date'].toString()) 
            : DateTime.now();
      } catch (e) {
        debugPrint('WARNING: Invalid date format for assigned_date: ${json['assigned_date']}');
        assignedDate = DateTime.now();
      }
      
      // Statut avec normalisation pour s'assurer qu'il correspond aux valeurs attendues
      String status = 'assigned'; // default value
      if (json['status'] != null) {
        String rawStatus = json['status'].toString().toLowerCase();
        
        // Normalisation des statuts
        if (rawStatus.contains('assign') || rawStatus.contains('assigné')) {
          status = 'assigned';
        } else if (rawStatus.contains('progress') || rawStatus.contains('en cours')) {
          status = 'in_progress';
        } else if (rawStatus.contains('completé') || rawStatus.contains('terminé')) {
          status = 'completed';
        } else if (rawStatus.contains('validé')) {
          status = 'validated';
        } else {
          status = rawStatus; // keep as is if no match
        }
        
        debugPrint('Normalized status from "${json['status']}" to "$status"');
      }
      
      // Date de complétion optionnelle
      DateTime? completionDate;
      if (json['completion_date'] != null) {
        try {
          completionDate = DateTime.parse(json['completion_date'].toString());
        } catch (e) {
          debugPrint('WARNING: Invalid date format for completion_date: ${json['completion_date']}');
        }
      }
      
      // Construction de l'objet
      return UserRoutine(
        id: id,
        userId: userId,
        routineId: routineId,
        assignedDate: assignedDate,
        status: status,
        completionDate: completionDate,
        validatedBy: json['validated_by']?.toString(),
        experienceGained: json['experience_gained'] is int 
            ? json['experience_gained'] 
            : json['experience_gained'] != null 
                ? int.tryParse(json['experience_gained'].toString()) 
                : null,
        feedback: json['feedback']?.toString(),
      );
    } catch (e, stackTrace) {
      debugPrint('ERROR parsing UserRoutine: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Problematic JSON: $json');
      
      // Retourner un objet minimal mais valide plutôt que de planter
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
      'profile_id': userId, // Utiliser profile_id pour compatibilité avec la base de données
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