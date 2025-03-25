class MembershipCard {
  final String id;
  final String userId;
  final String type; // 'individuel' ou 'collectif'
  final int totalSessions;
  final int remainingSessions;
  final DateTime purchaseDate;
  final DateTime expiryDate;
  final double price;
  final String paymentStatus; // 'pending', 'completed', 'failed'

  MembershipCard({
    required this.id,
    required this.userId,
    required this.type,
    required this.totalSessions,
    required this.remainingSessions,
    required this.purchaseDate,
    required this.expiryDate,
    required this.price,
    required this.paymentStatus,
  });

  factory MembershipCard.fromJson(Map<String, dynamic> json) {
    return MembershipCard(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      totalSessions: json['total_sessions'],
      remainingSessions: json['remaining_sessions'],
      purchaseDate: DateTime.parse(json['purchase_date']),
      expiryDate: DateTime.parse(json['expiry_date']),
      price: json['price'].toDouble(),
      paymentStatus: json['payment_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'total_sessions': totalSessions,
      'remaining_sessions': remainingSessions,
      'purchase_date': purchaseDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'price': price,
      'payment_status': paymentStatus,
    };
  }

  MembershipCard copyWith({
    String? id,
    String? userId,
    String? type,
    int? totalSessions,
    int? remainingSessions,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    double? price,
    String? paymentStatus,
  }) {
    return MembershipCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      totalSessions: totalSessions ?? this.totalSessions,
      remainingSessions: remainingSessions ?? this.remainingSessions,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      price: price ?? this.price,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }
}
