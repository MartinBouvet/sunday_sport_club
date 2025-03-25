class Exercise {
  final String id;
  final String name;
  final String description;
  final String category; // 'cardio', 'strength', 'flexibility', etc.
  final String difficulty; // 'beginner', 'intermediate', 'advanced'
  final int durationSeconds;
  final int? repetitions;
  final int? sets;
  final String? imageUrl;
  final String? videoUrl;
  final String muscleGroup; // 'legs', 'arms', 'core', 'full_body', etc.

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.durationSeconds,
    this.repetitions,
    this.sets,
    this.imageUrl,
    this.videoUrl,
    required this.muscleGroup,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      difficulty: json['difficulty'],
      durationSeconds: json['duration_seconds'],
      repetitions: json['repetitions'],
      sets: json['sets'],
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      muscleGroup: json['muscle_group'],
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
      'image_url': imageUrl,
      'video_url': videoUrl,
      'muscle_group': muscleGroup,
    };
  }

  Exercise copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? difficulty,
    int? durationSeconds,
    int? repetitions,
    int? sets,
    String? imageUrl,
    String? videoUrl,
    String? muscleGroup,
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
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      muscleGroup: muscleGroup ?? this.muscleGroup,
    );
  }
}
