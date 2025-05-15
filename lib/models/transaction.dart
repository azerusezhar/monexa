class Transaction {
  final String id;
  final double amount;
  final String type;
  final String category;
  final String description;
  final String date;

  const Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
  });
}