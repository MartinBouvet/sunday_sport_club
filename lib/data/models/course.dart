class Course {
  final String id;
  final String title;
  final String description;
  final String type; // 'individuel' ou 'collectif'
  final DateTime date;
  final String startTime;
  final String endTime;
  final int capacity;
  final int currentParticipants;
  final String status; // 'available', 'full', 'cancelled'
  final String coachId;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.currentParticipants,
    required this.status,
    required this.coachId,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    // Gestion de date avec ou sans heure
    DateTime parseDate() {
      try {
        if (json['date'] != null) {
          return DateTime.parse(json['date']);
        } else if (json['date_time'] != null) {
          return DateTime.parse(json['date_time']);
        } else {
          return DateTime.now();
        }
      } catch (e) {
        return DateTime.now();
      }
    }

    return Course(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'collectif',
      date: parseDate(),
      startTime: json['start_time']?.toString() ?? '00:00',
      endTime: json['end_time']?.toString() ?? '01:00',
      capacity: json['capacity'] ?? json['max_participants'] ?? 10,
      currentParticipants: json['current_participants'] ?? 0,
      status:
          json['status'] ??
          (json['is_cancelled'] == true ? 'cancelled' : 'available'),
      coachId: json['coach_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'date': date.toIso8601String(),
      'start_time': startTime,
      'end_time': endTime,
      'capacity': capacity,
      'current_participants': currentParticipants,
      'status': status,
      'coach_id': coachId,
    };
  }

  Course copyWith({
    String? id,
    String? title,
    String? description,
    String? type,
    DateTime? date,
    String? startTime,
    String? endTime,
    int? capacity,
    int? currentParticipants,
    String? status,
    String? coachId,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      capacity: capacity ?? this.capacity,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status ?? this.status,
      coachId: coachId ?? this.coachId,
    );
  }
}
