class RoutineExercise {
  final String exerciseId;
  final int sets;
  final int reps;
  final int restTime; // en secondes

  RoutineExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.restTime,
  });

  factory RoutineExercise.fromJson(Map<String, dynamic> json) {
    return RoutineExercise(
      exerciseId: json['exercise_id'],
      sets: json['sets'],
      reps: json['reps'],
      restTime: json['rest_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercise_id': exerciseId,
      'sets': sets,
      'reps': reps,
      'rest_time': restTime,
    };
  }

  RoutineExercise copyWith({
    String? exerciseId,
    int? sets,
    int? reps,
    int? restTime,
  }) {
    return RoutineExercise(
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      restTime: restTime ?? this.restTime,
    );
  }
}