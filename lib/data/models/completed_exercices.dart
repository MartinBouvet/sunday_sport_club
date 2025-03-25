class CompletedExercise {
  final String id;
  final String userId;
  final String exerciseId;
  final String? routineId;
  final String? challengeId;
  final DateTime completedDate;
  final int actualSets;
  final int actualReps;
  final int? actualDurationSeconds;
  final double? weight; // Optional weight used (in kg)
  final int? difficultyRating; // User's rating of difficulty (1-5)
  final String? notes;

  CompletedExercise({
    required this.id,
    required this.userId,
    required this.exerciseId,
    this.routineId,
    this.challengeId,
    required this.completedDate,
    required this.actualSets,
    required this.actualReps,
    this.actualDurationSeconds,
    this.weight,
    this.difficultyRating,
    this.notes,
  });

  factory CompletedExercise.fromJson(Map<String, dynamic> json) {
    return CompletedExercise(
      id: json['id'],
      userId: json['user_id'],
      exerciseId: json['exercise_id'],
      routineId: json['routine_id'],
      challengeId: json['challenge_id'],
      completedDate: DateTime.parse(json['completed_date']),
      actualSets: json['actual_sets'],
      actualReps: json['actual_reps'],
      actualDurationSeconds: json['actual_duration_seconds'],
      weight: json['weight']?.toDouble(),
      difficultyRating: json['difficulty_rating'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'exercise_id': exerciseId,
      'routine_id': routineId,
      'challenge_id': challengeId,
      'completed_date': completedDate.toIso8601String(),
      'actual_sets': actualSets,
      'actual_reps': actualReps,
      'actual_duration_seconds': actualDurationSeconds,
      'weight': weight,
      'difficulty_rating': difficultyRating,
      'notes': notes,
    };
  }

  CompletedExercise copyWith({
    String? id,
    String? userId,
    String? exerciseId,
    String? routineId,
    String? challengeId,
    DateTime? completedDate,
    int? actualSets,
    int? actualReps,
    int? actualDurationSeconds,
    double? weight,
    int? difficultyRating,
    String? notes,
  }) {
    return CompletedExercise(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      exerciseId: exerciseId ?? this.exerciseId,
      routineId: routineId ?? this.routineId,
      challengeId: challengeId ?? this.challengeId,
      completedDate: completedDate ?? this.completedDate,
      actualSets: actualSets ?? this.actualSets,
      actualReps: actualReps ?? this.actualReps,
      actualDurationSeconds: actualDurationSeconds ?? this.actualDurationSeconds,
      weight: weight ?? this.weight,
      difficultyRating: difficultyRating ?? this.difficultyRating,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'CompletedExercise{id: $id, userId: $userId, exerciseId: $exerciseId, completedDate: $completedDate}';
  }
}