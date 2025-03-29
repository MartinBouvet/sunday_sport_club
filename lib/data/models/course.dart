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
    try {
      return Course(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        type: json['type']?.toString() ?? 'collectif',
        date:
            json['date_time'] != null
                ? DateTime.parse(json['date_time'])
                : DateTime.now(),
        startTime: _extractTime(json['date_time'], true),
        endTime: _calculateEndTime(json['date_time'], json['duration']),
        capacity: json['max_participants'] ?? 10,
        currentParticipants: json['current_participants'] ?? 0,
        status: json['is_cancelled'] == true ? 'cancelled' : 'available',
        coachId: json['coach_id']?.toString() ?? '',
      );
    } catch (e) {
      print("Error parsing Course: $e for data: $json");
      return Course(
        id: '',
        title: 'Erreur',
        description: '',
        type: 'collectif',
        date: DateTime.now(),
        startTime: '00:00',
        endTime: '01:00',
        capacity: 0,
        currentParticipants: 0,
        status: 'error',
        coachId: '',
      );
    }
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

  static String _extractTime(String? dateTime, bool isStart) {
    if (dateTime == null) return isStart ? '00:00' : '01:00';
    try {
      final dt = DateTime.parse(dateTime);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return isStart ? '00:00' : '01:00';
    }
  }

  static String _calculateEndTime(String? dateTime, dynamic duration) {
    if (dateTime == null) return '01:00';
    try {
      final dt = DateTime.parse(dateTime);
      final durationMinutes = duration is int ? duration : 60;
      final endTime = dt.add(Duration(minutes: durationMinutes));
      return "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '01:00';
    }
  }
}
