class Exercise {
  final String id;
  final String name;
  final String description;
  final String category;
  final String difficulty;
  final int durationSeconds;
  final int? repetitions;
  final int? sets;
  final String muscleGroup;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.durationSeconds,
    this.repetitions,
    this.sets,
    required this.muscleGroup,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Exercice sans nom',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'intermédiaire',
      durationSeconds: json['duration_seconds'] ?? 60,
      repetitions: json['repetitions'],
      sets: json['sets'],
      muscleGroup: json['muscle_group'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'duration_seconds': durationSeconds,
      'repetitions': repetitions,
      'sets': sets,
      'muscle_group': muscleGroup,
    };
  }
}