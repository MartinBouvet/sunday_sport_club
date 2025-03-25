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
    return Routine(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      difficulty: json['difficulty'],
      estimatedDurationMinutes: json['estimated_duration_minutes'],
      exerciseIds: List<String>.from(json['exercise_ids']),
      exerciseDetails: json['exercise_details'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      isPublic: json['is_public'],
    );
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
}