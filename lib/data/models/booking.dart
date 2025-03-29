class Booking {
  final String id;
  final String userId;
  final String courseId;
  final DateTime bookingDate;
  final String status; // 'confirmed', 'cancelled', 'completed'
  final String? membershipCardId;

  Booking({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.bookingDate,
    required this.status,
    this.membershipCardId,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['user_id'],
      courseId: json['course_id'],
      bookingDate: DateTime.parse(json['booking_date']),
      status: json['status'],
      membershipCardId: json['membership_card_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'course_id': courseId,
      'booking_date': bookingDate.toIso8601String(),
      'status': status,
      'membership_card_id': membershipCardId,
    };
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? courseId,
    DateTime? bookingDate,
    String? status,
    String? membershipCardId,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      bookingDate: bookingDate ?? this.bookingDate,
      status: status ?? this.status,
      membershipCardId: membershipCardId ?? this.membershipCardId,
    );
  }
}
