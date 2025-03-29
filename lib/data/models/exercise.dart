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
  final String? imageUrl;
  final String? videoUrl;

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
    this.imageUrl,
    this.videoUrl,
  });

  // Méthode pour créer un objet Exercise à partir d'une Map (JSON)
  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Exercice',
      description: json['description'] ?? 'Aucune description disponible',
      category: json['category'] ?? 'général',
      difficulty: json['difficulty'] ?? 'intermédiaire',
      durationSeconds: json['durationSeconds'] ?? 60,
      repetitions: json['repetitions'],
      sets: json['sets'],
      muscleGroup: json['muscleGroup'] ?? 'général',
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
    );
  }

  // Méthode pour convertir l'objet Exercise en Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'durationSeconds': durationSeconds,
      'repetitions': repetitions,
      'sets': sets,
      'muscleGroup': muscleGroup,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
    };
  }

  // Méthode pour créer une copie de l'objet avec des valeurs modifiées
  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? difficulty,
    int? durationSeconds,
    int? repetitions,
    int? sets,
    String? muscleGroup,
    String? imageUrl,
    String? videoUrl,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      repetitions: repetitions ?? this.repetitions,
      sets: sets ?? this.sets,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}