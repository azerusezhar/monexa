import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monexa/screens/transaction/transaction_detail_screen.dart';
import 'package:monexa/models/transaction.dart';
import 'package:monexa/widgets/transaction/transaction_filter_sheet.dart';
import 'package:monexa/widgets/transaction/transaction_list.dart';

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
  bool isFiltering = false;

  // Month filtering
  DateTime _selectedDate = DateTime.now();
  bool _showAllMonths = false;
  String get _selectedMonth =>
      _showAllMonths
          ? 'All Time'
          : '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}';

  // Helper method to get month name
  String _getMonthName(int month) {
    return [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][month - 1];
  }

  // Filter options
  final List<String> filterByOptions = ['income', 'expense'];
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

      // Set up the base query
      var query = supabase
          .from('transactions')
          .select('*')
          .eq('user_id', userId);

      // Apply date filters if not showing all months
      if (!_showAllMonths) {
        final DateTime startOfMonth = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          1,
        );
        final DateTime endOfMonth = DateTime(
          _selectedDate.year,
          _selectedDate.month + 1,
          0,
          23,
          59,
          59,
        );

        query = query
            .gte('date', startOfMonth.toIso8601String())
            .lte('date', endOfMonth.toIso8601String());
      }

      // Execute query with sorting
      final response = await query.order('date', ascending: false);

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) {
        return TransactionFilterSheet(
          initialFilter: selectedFilter,
          initialSort: selectedSort,
          initialSelectedCategories: selectedCategories,
          filterByOptions: filterByOptions,
          sortByOptions: sortByOptions,
          onApplyFilters: (filter, sort, categories) {
            setState(() {
              selectedFilter = filter;
              selectedSort = sort;
              selectedCategories = categories;
            });
            applyFilters();
          },
        );
      },
    );
  }

  // Show month picker dialog
  void _showMonthPicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5, // Set fixed height
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Month',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Year selector - only show if not in "All" mode
                    if (!_showAllMonths)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  // Decrease year
                                  _selectedDate = DateTime(
                                    _selectedDate.year - 1,
                                    _selectedDate.month,
                                    1,
                                  );
                                  Navigator.pop(context);
                                  _showMonthPicker(
                                    context,
                                  ); // Reopen with new year
                                });
                              },
                              child: const Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_selectedDate.year}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  // Increase year
                                  _selectedDate = DateTime(
                                    _selectedDate.year + 1,
                                    _selectedDate.month,
                                    1,
                                  );
                                  Navigator.pop(context);
                                  _showMonthPicker(
                                    context,
                                  ); // Reopen with new year
                                });
                              },
                              child: const Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: Colors.grey),
              // All option
              ListTile(
                title: const Text(
                  'All Time',
                  style: TextStyle(
                    color: Color(0xFF7F3DFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                trailing:
                    _showAllMonths
                        ? const Icon(
                          Icons.check_circle,
                          color: Color(0xFF7F3DFF),
                        )
                        : null,
                onTap: () {
                  setState(() {
                    _showAllMonths = true;
                  });
                  Navigator.pop(context);
                  // Reload transactions with all months
                  setState(() {
                    transactions = fetchTransactions();
                  });
                  applyFilters();
                },
              ),
              const Divider(color: Colors.grey),
              // Month options
              Expanded(
                child: ListView.builder(
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected =
                        !_showAllMonths && month == _selectedDate.month;

                    return ListTile(
                      title: Text(
                        _getMonthName(month),
                        style: TextStyle(
                          color:
                              isSelected
                                  ? const Color(0xFF7F3DFF)
                                  : Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing:
                          isSelected
                              ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF7F3DFF),
                              )
                              : null,
                      onTap: () {
                        setState(() {
                          _showAllMonths = false;
                          _selectedDate = DateTime(
                            _selectedDate.year,
                            month,
                            1,
                          );
                        });
                        Navigator.pop(context);
                        // Reload transactions with selected month
                        setState(() {
                          transactions = fetchTransactions();
                        });
                        applyFilters();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
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
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: InkWell(
          onTap: () => _showMonthPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedMonth,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white60,
                  size: 20,
                ),
              ],
            ),
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
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                onChanged: filterTransactions,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
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

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                transactions = fetchTransactions();
              });
              await transactions;
              applyFilters();
            },
            color: const Color(0xFF7F3DFF),
            backgroundColor: Colors.grey[900],
            child: TransactionList(
              transactions: transactionData,
              groupTransactionsByDate: groupTransactionsByDate,
              onTransactionTap: (transaction) {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (context, animation, secondaryAnimation) =>
                            TransactionDetailScreen(
                              transactionId: transaction.id,
                            ),
                    transitionsBuilder: (
                      context,
                      animation,
                      secondaryAnimation,
                      child,
                    ) {
                      var curve = Curves.easeInOut;
                      var curveTween = CurveTween(curve: curve);
                      var fadeAnimation = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(animation.drive(curveTween));
                      return FadeTransition(
                        opacity: fadeAnimation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                ).then((result) {
                  // Refresh the list if a transaction was deleted or edited
                  if (result == true) {
                    setState(() {
                      transactions = fetchTransactions();
                    });
                    applyFilters();
                  }
                });
              },
            ),
          );
        },
      ),
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
            child: Row(
              children: [
                // Circle for icon
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 40,
                  width: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(height: 14, width: 100, color: Colors.white),
                      const SizedBox(height: 8),
                      Container(height: 10, width: 150, color: Colors.white),
                    ],
                  ),
                ),

                // Amount
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 14,
                  width: 60,
                  color: Colors.white,
                ),
              ],
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wallet_outlined,
              color: Colors.purpleAccent[100],
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No transactions found",
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              selectedFilter != 'all'
                  ? "Try changing your filter selection"
                  : "Start adding your income and expenses",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          if (selectedFilter != 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
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
              icon: const Icon(Icons.filter_list_off),
              label: const Text(
                "Clear Filters",
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[900]?.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, color: Colors.red[300], size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            "Failed to load transactions",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "There was an error connecting to the server",
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text("Try Again"),
          ),
        ],
      ),
    );
  }
}
