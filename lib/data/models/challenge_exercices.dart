class ChallengeExercise {
  final String id;
  final String challengeId;
  final String exerciseId;
  final int sets;
  final int reps;
  final int? durationSeconds;
  final String? specialInstructions;
  final int sortOrder;

  ChallengeExercise({
    required this.id,
    required this.challengeId,
    required this.exerciseId,
    required this.sets,
    required this.reps,
    this.durationSeconds,
    this.specialInstructions,
    required this.sortOrder,
  });

  factory ChallengeExercise.fromJson(Map<String, dynamic> json) {
    return ChallengeExercise(
      id: json['id'],
      challengeId: json['challenge_id'],
      exerciseId: json['exercise_id'],
      sets: json['sets'],
      reps: json['reps'],
      durationSeconds: json['duration_seconds'],
      specialInstructions: json['special_instructions'],
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challenge_id': challengeId,
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'duration_seconds': durationSeconds,
      'special_instructions': specialInstructions,
      'sort_order': sortOrder,
    };
  }

  ChallengeExercise copyWith({
    String? id,
    String? challengeId,
    String? exerciseId,
    int? sets,
    int? reps,
    int? durationSeconds,
    String? specialInstructions,
    int? sortOrder,
  }) {
    return ChallengeExercise(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  String toString() {
    return 'ChallengeExercise{id: $id, challengeId: $challengeId, exerciseId: $exerciseId}';
  }
}