class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int requiredValue;
  final String achievementType; // 'progress', 'exercise_count', 'attendance', etc.
  final DateTime createdAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.requiredValue,
    required this.achievementType,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconName: json['icon_name'],
      requiredValue: json['required_value'],
      achievementType: json['achievement_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'required_value': requiredValue,
      'achievement_type': achievementType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    int? requiredValue,
    String? achievementType,
    DateTime? createdAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      requiredValue: requiredValue ?? this.requiredValue,
      achievementType: achievementType ?? this.achievementType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Achievement{id: $id, name: $name, type: $achievementType}';
  }
}