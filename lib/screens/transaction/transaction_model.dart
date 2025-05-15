class Transaction {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String category;
  final String description;
  final DateTime date;
  final DateTime createdAt;
  final String? attachmentUrl;

  const Transaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    required this.createdAt,
    this.attachmentUrl,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      amount:
          (map['amount'] is int
              ? (map['amount'] as int).toDouble()
              : map['amount']) ??
          0.0,
      type: map['type'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      createdAt: map['created_at'] ?? '',
      attachmentUrl: map['attachment_url'] ?? '',
    );
  }
}
