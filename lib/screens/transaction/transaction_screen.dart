import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monexa/utils/transaction_category.dart';

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

class AppFormatters {
  static String formatToIdrCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}

class EnhancedTransactionsPage extends StatefulWidget {
  const EnhancedTransactionsPage({super.key});

  @override
  _EnhancedTransactionsPageState createState() =>
      _EnhancedTransactionsPageState();
}

class _EnhancedTransactionsPageState extends State<EnhancedTransactionsPage> {
  late Future<List<Transaction>> transactions;
  List<Transaction> filteredTransactions = [];
  String searchQuery = '';
  String selectedFilter =
      'all'; // 'all', 'income', 'expense', or a specific category name
  String selectedSort = 'newest'; // 'highest', 'lowest', 'newest', 'oldest'
  String? selectedCategory;

  // Filter options
  final List<String> filterByOptions = ['income', 'expense', 'transfer'];
  final List<String> sortByOptions = ['highest', 'lowest', 'newest', 'oldest'];
  List<String> selectedCategories = [];

  @override
  void initState() {
    super.initState();
    transactions = fetchTransactions();
  }

  Future<List<Transaction>> fetchTransactions() async {
    try {
      final supabase = Supabase.instance.client;

      // Ensure user is authenticated
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch transactions from Supabase
      final response = await supabase
          .from('transactions')
          .select('*')
          .eq('user_id', userId)
          .order('date', ascending: false);

      // Convert response to Transaction objects
      List<Transaction> transactionList =
          response
              .map<Transaction>((data) => Transaction.fromJson(data))
              .toList();

      // If no transactions, add a default transaction for demonstration
      if (transactionList.isEmpty) {
        transactionList = [
          Transaction(
            id: '1',
            userId: userId,
            amount: 0,
            type: 'expense',
            category: 'others',
            description: 'No transactions yet',
            date: DateTime.now().toIso8601String().split('T')[0],
            createdAt: DateTime.now().toIso8601String(),
          ),
        ];
      }

      return transactionList;
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  void filterTransactions(String query) {
    setState(() {
      searchQuery = query;
    });

    applyFilters();
  }

  void applyFilters() {
    // First get the base list
    transactions.then((list) {
      List<Transaction> filtered = List.from(list);

      // Apply search query filter if any
      if (searchQuery.isNotEmpty) {
        filtered =
            filtered.where((transaction) {
              return transaction.description.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ||
                  transaction.category.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  );
            }).toList();
      }

      // Apply type filter
      if (selectedFilter != 'all') {
        filtered =
            filtered
                .where((t) => t.type.toLowerCase() == selectedFilter)
                .toList();
      }

      // Apply category filter
      if (selectedCategories.isNotEmpty) {
        filtered =
            filtered
                .where((t) => selectedCategories.contains(t.category))
                .toList();
      }

      // Apply sorting
      switch (selectedSort) {
        case 'highest':
          filtered.sort((a, b) => b.amount.compareTo(a.amount));
          break;
        case 'lowest':
          filtered.sort((a, b) => a.amount.compareTo(b.amount));
          break;
        case 'newest':
          filtered.sort(
            (a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)),
          );
          break;
        case 'oldest':
          filtered.sort(
            (a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)),
          );
          break;
      }

      setState(() {
        filteredTransactions = filtered;
      });
    });
  }

  void resetFilters() {
    setState(() {
      selectedFilter = 'all';
      selectedSort = 'newest';
      selectedCategories = [];
    });

    applyFilters();
  }

  void showFilterBottomSheet() {
    // Local variables to track selections before applying
    String tempFilter = selectedFilter;
    String tempSort = selectedSort;
    List<String> tempCategories = List.from(selectedCategories);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border.all(
                  color: Colors.purpleAccent.withOpacity(0.5),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and reset button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter Transaction",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempFilter = 'all';
                            tempSort = 'newest';
                            tempCategories = [];
                          });
                        },
                        child: Text(
                          "Reset",
                          style: TextStyle(
                            color: Colors.purpleAccent[100],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Filter By Section
                  const Text(
                    "Filter By",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:
                        filterByOptions.map((option) {
                          bool isSelected = tempFilter == option;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                tempFilter = isSelected ? 'all' : option;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.purpleAccent.withOpacity(0.3)
                                        : Colors.grey[900],
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: Colors.purpleAccent,
                                          width: 1,
                                        )
                                        : null,
                              ),
                              child: Text(
                                capitalizeFirstLetter(option),
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.purpleAccent
                                          : Colors.white,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Sort By Section
                  const Text(
                    "Sort By",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        sortByOptions.map((option) {
                          bool isSelected = tempSort == option;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                tempSort = option;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? Colors.purpleAccent.withOpacity(0.3)
                                        : Colors.grey[900],
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    isSelected
                                        ? Border.all(
                                          color: Colors.purpleAccent,
                                          width: 1,
                                        )
                                        : null,
                              ),
                              child: Text(
                                capitalizeFirstLetter(option),
                                style: TextStyle(
                                  color:
                                      isSelected
                                          ? Colors.purpleAccent
                                          : Colors.white,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Category Section
                  const Text(
                    "Category",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      // Show category selection dialog
                      _showCategorySelectionDialog(context, tempCategories, (
                        selected,
                      ) {
                        setModalState(() {
                          tempCategories = selected;
                        });
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.purpleAccent.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tempCategories.isEmpty
                                ? "Choose Category"
                                : "${tempCategories.length} Selected",
                            style: TextStyle(
                              color:
                                  tempCategories.isEmpty
                                      ? Colors.grey[500]
                                      : Colors.white,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                tempCategories.length.toString(),
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[500],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Apply filters and close sheet
                        setState(() {
                          selectedFilter = tempFilter;
                          selectedSort = tempSort;
                          selectedCategories = tempCategories;
                        });
                        applyFilters();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Apply",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCategorySelectionDialog(
    BuildContext context,
    List<String> currentSelection,
    Function(List<String>) onSelected,
  ) {
    List<String> tempSelection = List.from(currentSelection);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                "Select Categories",
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children:
                      TransactionCategory.allCategories.map((category) {
                        final isSelected = tempSelection.contains(
                          category.name,
                        );
                        return CheckboxListTile(
                          title: Text(
                            category.label,
                            style: const TextStyle(color: Colors.white),
                          ),
                          value: isSelected,
                          activeColor: Colors.purpleAccent,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                if (!tempSelection.contains(category.name)) {
                                  tempSelection.add(category.name);
                                }
                              } else {
                                tempSelection.remove(category.name);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onSelected(tempSelection);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Done",
                    style: TextStyle(color: Colors.purpleAccent),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, List<Transaction>> groupTransactionsByDate(
    List<Transaction> transactions,
  ) {
    final Map<String, List<Transaction>> grouped = {};

    for (var transaction in transactions) {
      final DateTime transactionDate = DateTime.parse(transaction.date);
      final DateTime now = DateTime.now();
      final DateTime yesterday = DateTime.now().subtract(
        const Duration(days: 1),
      );

      String dateKey;

      if (transactionDate.year == now.year &&
          transactionDate.month == now.month &&
          transactionDate.day == now.day) {
        dateKey = 'Today';
      } else if (transactionDate.year == yesterday.year &&
          transactionDate.month == yesterday.month &&
          transactionDate.day == yesterday.day) {
        dateKey = 'Yesterday';
      } else {
        dateKey = DateFormat('MMMM d, yyyy').format(transactionDate);
      }

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }

      grouped[dateKey]!.add(transaction);
    }

    return grouped;
  }

  String capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Transactions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: showFilterBottomSheet,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[900]!.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: TextField(
                onChanged: filterTransactions,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search transactions...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Transaction>>(
        future: transactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoader();
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final transactionData =
              (searchQuery.isNotEmpty ||
                      selectedFilter != 'all' ||
                      selectedCategories.isNotEmpty)
                  ? filteredTransactions
                  : snapshot.data ?? [];

          if (transactionData.isEmpty) {
            return _buildEmptyState();
          }

          return _buildTransactionList(transactionData);
        },
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> transactions) {
    final groupedTransactions = groupTransactionsByDate(transactions);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final sectionTitle = groupedTransactions.keys.elementAt(index);
              return _buildTransactionSection(
                sectionTitle,
                groupedTransactions[sectionTitle]!,
              );
            }, childCount: groupedTransactions.length),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionSection(
    String sectionTitle,
    List<Transaction> transactions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Container(
                height: 24,
                width: 4,
                decoration: BoxDecoration(
                  color: Colors.purple[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                sectionTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              if (sectionTitle == "Today")
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "NEW",
                    style: TextStyle(
                      color: Colors.purple[200],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return _buildTransactionCard(transactions[index]);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    final category = TransactionCategory.fromName(transaction.category);
    final isIncome = transaction.type.toLowerCase() == 'income';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showTransactionDetails(transaction),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(category.icon, color: category.color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            category.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isIncome
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isIncome ? "INCOME" : "EXPENSE",
                              style: TextStyle(
                                color:
                                    isIncome
                                        ? Colors.green[300]
                                        : Colors.red[300],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        transaction.description,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isIncome ? '+' : '-'}${AppFormatters.formatToIdrCurrency(transaction.amount)}",
                      style: TextStyle(
                        color: isIncome ? Colors.green[300] : Colors.red[300],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'dd MMM yyyy',
                      ).format(DateTime.parse(transaction.date)),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    final category = TransactionCategory.fromName(transaction.category);
    final isIncome = transaction.type.toLowerCase() == 'income';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(category.icon, color: category.color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.description,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "Amount",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                "${isIncome ? '+' : '-'}${AppFormatters.formatToIdrCurrency(transaction.amount)}",
                style: TextStyle(
                  color: isIncome ? Colors.green[300] : Colors.red[300],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Transaction Type",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                capitalizeFirstLetter(transaction.type),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Text(
                "Transaction Date",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat(
                  'MMMM d, yyyy',
                ).format(DateTime.parse(transaction.date)),
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (transaction.attachmentUrl != null &&
                  transaction.attachmentUrl!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  "Attachment",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    // TODO: Implement attachment viewer
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Opening attachment: ${transaction.attachmentUrl}",
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attachment,
                          color: Colors.purple[300],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "View Receipt",
                          style: TextStyle(color: Colors.purple[300]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text(
                "Transaction ID",
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                transaction.id,
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Close",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Implement edit transaction
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Edit transaction feature coming soon",
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.purple[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Edit",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[850]!,
      highlightColor: Colors.grey[800]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            height: 80,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wallet_outlined, color: Colors.grey[600], size: 80),
          const SizedBox(height: 16),
          Text(
            "No transactions found",
            style: TextStyle(color: Colors.grey[500], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            selectedFilter != 'all'
                ? "Try changing your filter selection"
                : "Start adding your income and expenses",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (selectedFilter != 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                resetFilters();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Show All Transactions",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 48),
          const SizedBox(height: 16),
          Text(
            "Failed to load transactions",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                transactions = fetchTransactions();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Try Again"),
          ),
        ],
      ),
    );
  }
}
