class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final int experiencePoints;
  final DateTime date;
  final List<String> exerciseIds;
  final String difficulty;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.experiencePoints,
    required this.date,
    required this.exerciseIds,
    required this.difficulty,
  });

  factory DailyChallenge.fromJson(Map<String, dynamic> json) {
    return DailyChallenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      experiencePoints: json['experience_points'],
      date: DateTime.parse(json['date']),
      exerciseIds: List<String>.from(json['exercise_ids']),
      difficulty: json['difficulty'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'experience_points': experiencePoints,
      'date': date.toIso8601String(),
      'exercise_ids': exerciseIds,
      'difficulty': difficulty,
    };
  }

  DailyChallenge copyWith({
    String? id,
    String? title,
    String? description,
    int? experiencePoints,
    DateTime? date,
    List<String>? exerciseIds,
    String? difficulty,
  }) {
    return DailyChallenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      date: date ?? this.date,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}