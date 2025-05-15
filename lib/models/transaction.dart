class Transaction {
  final String id;
  final String userId;
  final double amount;
  final String type;
  final String category;
  final String description;
  final String date;
  final String createdAt;
  final String? attachmentUrl;

  Transaction({
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

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      userId: json['user_id'],
      amount: json['amount'].toDouble(),
      type: json['type'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      createdAt: json['created_at'] ?? '',
      attachmentUrl: json['attachment_url'],
    );
  }
}
