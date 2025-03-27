import 'package:flutter/foundation.dart';

class Routine {
  final String id;
  final String name;
  final String description;
  final String difficulty;
  final int estimatedDurationMinutes;
  final List<String> exerciseIds;
  final Map<String, dynamic>? exerciseDetails; // Répétitions, sets pour chaque exercice
  final String createdBy; // ID du coach qui a créé la routine
  final DateTime createdAt;
  final bool isPublic;

  Routine({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.estimatedDurationMinutes,
    required this.exerciseIds,
    this.exerciseDetails,
    required this.createdBy,
    required this.createdAt,
    required this.isPublic,
  });

  factory Routine.fromJson(Map<String, dynamic> json) {
    try {
      // Extraction avec gestion des valeurs nulles
      final String id = json['id']?.toString() ?? '';
      if (id.isEmpty) {
        debugPrint('WARNING: Routine ID manquant dans: $json');
      }

      final String name = json['name']?.toString() ?? 'Routine sans nom';
      final String description = json['description']?.toString() ?? '';
      final String difficulty = json['difficulty']?.toString() ?? 'intermédiaire';
      
      // Conversion sécurisée pour les valeurs numériques
      int estimatedDurationMinutes = 30; // Valeur par défaut
      try {
        if (json['estimated_duration_minutes'] != null) {
          estimatedDurationMinutes = int.tryParse(json['estimated_duration_minutes'].toString()) ?? 30;
        }
      } catch (e) {
        debugPrint('Erreur lors de la conversion de la durée: $e');
      }
      
      // Gestion sécurisée des listes
      List<String> exerciseIds = [];
      if (json['exercise_ids'] != null) {
        if (json['exercise_ids'] is List) {
          exerciseIds = List<String>.from(
            (json['exercise_ids'] as List).map((e) => e?.toString() ?? '')
          ).where((id) => id.isNotEmpty).toList();
        } else {
          debugPrint('WARNING: exercise_ids n\'est pas une liste: ${json['exercise_ids']}');
        }
      }
      
      // Extraction sécurisée des détails d'exercice
      Map<String, dynamic>? exerciseDetails;
      if (json['exercise_details'] != null) {
        try {
          exerciseDetails = Map<String, dynamic>.from(json['exercise_details']);
        } catch (e) {
          debugPrint('Erreur lors de la conversion des détails d\'exercice: $e');
        }
      }
      
      // Extraction sécurisée du createdBy
      final String createdBy = json['created_by']?.toString() ?? '';
      
      // Conversion sécurisée de la date de création
      DateTime createdAt;
      try {
        createdAt = json['created_at'] != null 
            ? DateTime.parse(json['created_at']) 
            : DateTime.now();
      } catch (e) {
        debugPrint('WARNING: Format de date incorrect pour created_at: ${json['created_at']}');
        createdAt = DateTime.now();
      }
      
      // Extraction booléenne
      bool isPublic = false;
      if (json['is_public'] != null) {
        if (json['is_public'] is bool) {
          isPublic = json['is_public'];
        } else {
          // Tentative de conversion de chaîne ou de nombre en booléen
          final String boolStr = json['is_public'].toString().toLowerCase();
          isPublic = boolStr == 'true' || boolStr == '1';
        }
      }

      return Routine(
        id: id,
        name: name,
        description: description,
        difficulty: difficulty,
        estimatedDurationMinutes: estimatedDurationMinutes,
        exerciseIds: exerciseIds,
        exerciseDetails: exerciseDetails,
        createdBy: createdBy,
        createdAt: createdAt,
        isPublic: isPublic,
      );
    } catch (e) {
      debugPrint('ERREUR lors du parsing Routine: $e');
      debugPrint('Données problématiques: $json');
      
      // Retourner un objet minimal mais valide plutôt que de planter
      return Routine(
        id: json['id']?.toString() ?? 'error-${DateTime.now().millisecondsSinceEpoch}',
        name: json['name']?.toString() ?? 'Routine sans nom',
        description: 'Erreur de chargement',
        difficulty: 'intermédiaire',
        estimatedDurationMinutes: 30,
        exerciseIds: [],
        createdBy: '',
        createdAt: DateTime.now(),
        isPublic: false,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'estimated_duration_minutes': estimatedDurationMinutes,
      'exercise_ids': exerciseIds,
      'exercise_details': exerciseDetails,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'is_public': isPublic,
    };
  }

  Routine copyWith({
    String? id,
    String? name,
    String? description,
    String? difficulty,
    int? estimatedDurationMinutes,
    List<String>? exerciseIds,
    Map<String, dynamic>? exerciseDetails,
    String? createdBy,
    DateTime? createdAt,
    bool? isPublic,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      estimatedDurationMinutes: estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      exerciseDetails: exerciseDetails ?? this.exerciseDetails,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
    );
  }
  
  @override
  String toString() {
    return 'Routine{id: $id, name: $name, difficulty: $difficulty}';
  }
}