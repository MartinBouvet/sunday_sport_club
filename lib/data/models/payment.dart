class Payment {
  final String id;
  final String userId;
  final double amount;
  final DateTime date;
  final String paymentMethod; // 'card', 'cash', 'transfer'
  final String status; // 'pending', 'completed', 'failed', 'refunded'
  final String type; // 'membership', 'course', etc.
  final String? relatedItemId; // ID de l'élément associé (membership_card_id)
  final String? transactionId;
  final String? receipt;

  Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    required this.status,
    required this.type,
    this.relatedItemId,
    this.transactionId,
    this.receipt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      userId: json['user_id'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      paymentMethod: json['payment_method'],
      status: json['status'],
      type: json['type'],
      relatedItemId: json['related_item_id'],
      transactionId: json['transaction_id'],
      receipt: json['receipt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'status': status,
      'type': type,
      'related_item_id': relatedItemId,
      'transaction_id': transactionId,
      'receipt': receipt,
    };
  }

  Payment copyWith({
    String? id,
    String? userId,
    double? amount,
    DateTime? date,
    String? paymentMethod,
    String? status,
    String? type,
    String? relatedItemId,
    String? transactionId,
    String? receipt,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      type: type ?? this.type,
      relatedItemId: relatedItemId ?? this.relatedItemId,
      transactionId: transactionId ?? this.transactionId,
      receipt: receipt ?? this.receipt,
    );
  }
}