class ProgressTracking {
  final String id;
  final String userId;
  final DateTime date;
  final double? weight;
  final int? endurance;
  final int? strength;
  final String? notes;
  final Map<String, dynamic>? customMetrics;

  ProgressTracking({
    required this.id,
    required this.userId,
    required this.date,
    this.weight,
    this.endurance,
    this.strength,
    this.notes,
    this.customMetrics,
  });

  factory ProgressTracking.fromJson(Map<String, dynamic> json) {
    return ProgressTracking(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.parse(json['date']),
      weight: json['weight']?.toDouble(),
      endurance: json['endurance'],
      strength: json['strength'],
      notes: json['notes'],
      customMetrics: json['custom_metrics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'weight': weight,
      'endurance': endurance,
      'strength': strength,
      'notes': notes,
      'custom_metrics': customMetrics,
    };
  }

  ProgressTracking copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? weight,
    int? endurance,
    int? strength,
    String? notes,
    Map<String, dynamic>? customMetrics,
  }) {
    return ProgressTracking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      endurance: endurance ?? this.endurance,
      strength: strength ?? this.strength,
      notes: notes ?? this.notes,
      customMetrics: customMetrics ?? this.customMetrics,
    );
  }
}
