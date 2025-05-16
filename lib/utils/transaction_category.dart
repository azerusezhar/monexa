import 'package:flutter/material.dart';

class TransactionCategory {
  final String name;
  final String label;
  final IconData icon;
  final Color color;

  const TransactionCategory({
    required this.name,
    required this.label,
    required this.icon,
    required this.color,
  });

  /// Kategori Pendapatan (Income)
  static final List<TransactionCategory> incomeCategories = [
    TransactionCategory(
      name: 'salary',
      label: 'Gaji',
      icon: Icons.attach_money,
      color: Colors.green.shade700,
    ),
    TransactionCategory(
      name: 'freelance',
      label: 'Freelance',
      icon: Icons.work,
      color: Colors.lightGreen,
    ),
    TransactionCategory(
      name: 'bonus',
      label: 'Bonus',
      icon: Icons.card_giftcard,
      color: Colors.amber,
    ),
    TransactionCategory(
      name: 'investment',
      label: 'Investment',
      icon: Icons.show_chart,
      color: Colors.indigo,
    ),
    TransactionCategory(
      name: 'gift',
      label: 'Gift',
      icon: Icons.card_giftcard,
      color: Colors.purple,
    ),
    TransactionCategory(
      name: 'refund',
      label: 'Refund',
      icon: Icons.undo,
      color: Colors.teal,
    ),
    TransactionCategory(
      name: 'other_income',
      label: 'Other Income',
      icon: Icons.more_horiz,
      color: Colors.grey.shade600,
    ),
  ];

  /// Kategori Pengeluaran (Expense)
  static final List<TransactionCategory> expenseCategories = [
    TransactionCategory(
      name: 'food',
      label: 'Food',
      icon: Icons.fastfood,
      color: Colors.orange,
    ),
    TransactionCategory(
      name: 'transportation',
      label: 'Transportation',
      icon: Icons.directions_bus,
      color: Colors.blue.shade700,
    ),
    TransactionCategory(
      name: 'shopping',
      label: 'Shopping',
      icon: Icons.shopping_cart,
      color: Colors.green.shade800,
    ),
    TransactionCategory(
      name: 'entertainment',
      label: 'Entertainment',
      icon: Icons.movie,
      color: Colors.purple.shade400,
    ),
    TransactionCategory(
      name: 'bills',
      label: 'Bills',
      icon: Icons.receipt,
      color: Colors.red.shade700,
    ),
    TransactionCategory(
      name: 'rent',
      label: 'Rent',
      icon: Icons.home,
      color: Colors.brown.shade400,
    ),
    TransactionCategory(
      name: 'education',
      label: 'Education',
      icon: Icons.school,
      color: Colors.indigo.shade600,
    ),
    TransactionCategory(
      name: 'health',
      label: 'Health',
      icon: Icons.medical_services,
      color: Colors.deepPurple.shade300,
    ),
    TransactionCategory(
      name: 'clothing',
      label: 'Clothing',
      icon: Icons.checkroom,
      color: Colors.cyan.shade600,
    ),
    TransactionCategory(
      name: 'travel',
      label: 'Travel',
      icon: Icons.flight_takeoff,
      color: Colors.teal.shade600,
    ),
    TransactionCategory(
      name: 'debt_payment',
      label: 'Debt Payment',
      icon: Icons.money_off,
      color: Colors.blueGrey,
    ),
    TransactionCategory(
      name: 'subscription',
      label: 'Subscription',
      icon: Icons.subscriptions,
      color: Colors.pink.shade300,
    ),
    TransactionCategory(
      name: 'charity',
      label: 'Charity',
      icon: Icons.volunteer_activism,
      color: Colors.green.shade900,
    ),
    TransactionCategory(
      name: 'others',
      label: 'Others',
      icon: Icons.more_horiz,
      color: Colors.grey,
    ),
  ];

  /// Semua kategori (gabungan income + expense)
  static final List<TransactionCategory> allCategories = [
    ...incomeCategories,
    ...expenseCategories,
  ];

  /// Cari kategori berdasarkan nama
  static TransactionCategory fromName(String name) {
    // First try exact match
    final normalizedName = name.toLowerCase().trim();

    // Map some common names to their standardized form
    final nameMapping = {
      'shopping': 'shopping',
      'food': 'food',
      'transportation': 'transportation',
      'health': 'health',
      'entertainment': 'entertainment',
      'housing': 'rent',
      'utilities': 'bills',
      'education': 'education',
      'personal': 'others',
      'others': 'others',
      'other': 'others',
    };

    // Get the standardized name if it exists in the mapping
    final standardName = nameMapping[normalizedName] ?? normalizedName;

    return allCategories.firstWhere(
      (cat) => cat.name.toLowerCase() == standardName,
      orElse:
          () => TransactionCategory(
            name: name,
            label: name
                .split('_')
                .map(
                  (word) =>
                      word.isNotEmpty
                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                          : '',
                )
                .join(' '),
            icon: Icons.category,
            color: Colors.purple,
          ),
    );
  }
}
