class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final DateTime? birthDate;
  final String gender;
  final String skinColor;
  final bool isActive;
  final String role;
  final int level;
  final int experiencePoints;
  final String avatarStage;
  final double? weight;
  final int endurance;
  final int strength;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.birthDate,
    required this.gender,
    required this.skinColor,
    required this.isActive,
    required this.role,
    required this.level,
    required this.experiencePoints,
    required this.avatarStage,
    this.weight,
    required this.endurance,
    required this.strength,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      birthDate:
          json['birth_date'] != null
              ? DateTime.parse(json['birth_date'])
              : null,
      gender: json['gender'] ?? 'homme',
      skinColor: json['skin_color'] ?? 'blanc',
      isActive: json['is_active'] ?? true,
      role: json['role'] ?? 'user',
      level: json['level'] ?? 1,
      experiencePoints: json['experience_points'] ?? 0,
      avatarStage: json['avatar_stage'] ?? 'mince',
      weight: json['weight']?.toDouble(),
      endurance: json['endurance'] ?? 1,
      strength: json['strength'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'skin_color': skinColor,
      'is_active': isActive,
      'role': role,
      'level': level,
      'experience_points': experiencePoints,
      'avatar_stage': avatarStage,
      'weight': weight,
      'endurance': endurance,
      'strength': strength,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? birthDate,
    String? gender,
    String? skinColor,
    bool? isActive,
    String? role,
    int? level,
    int? experiencePoints,
    String? avatarStage,
    double? weight,
    int? endurance,
    int? strength,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      skinColor: skinColor ?? this.skinColor,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      level: level ?? this.level,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      avatarStage: avatarStage ?? this.avatarStage,
      weight: weight ?? this.weight,
      endurance: endurance ?? this.endurance,
      strength: strength ?? this.strength,
    );
  }
}
