import 'package:flutter/material.dart';
import 'package:monexa/widgets/donut_chart_widget.dart'; // Import the new donut chart widget
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monexa/utils/formatters.dart'; // Import the formatters.dart file
import 'package:monexa/models/transaction.dart'; // Import Transaction model
import 'package:monexa/widgets/transaction/transaction_card.dart'; // Import TransactionCard widget
import 'package:monexa/screens/transaction/transaction_detail_screen.dart'; // Import TransactionDetailScreen
import 'package:monexa/screens/transaction/transaction_screen.dart'; // Import Transaction screen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final SupabaseClient supabase;
  double _accountBalance = 0;
  double _income = 0;
  double _expenses = 0;
  List<Transaction> _transactions = [];
  List<Map<String, dynamic>> _spendFrequencyData = [];
  bool _isLoading = true;

  // Replace hardcoded month with DateTime
  DateTime _selectedDate = DateTime.now();
  bool _showAllMonths = false; // Add flag for showing all months
  String get _selectedMonth =>
      _showAllMonths
          ? 'All Time'
          : '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}';

  String? _fullName;
  String? _avatarUrl;

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

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    _fetchUserDataAndMetrics();
  }

  // Define _fetchUserDataAndMetrics method
  Future<void> _fetchUserDataAndMetrics() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final userId = user.id;

      // Fetch profile
      final profile =
          await supabase.from('profiles').select().eq('id', userId).single();

      setState(() {
        _fullName = profile['full_name'];
        _avatarUrl = profile['avatar_url'];
      });

      // Fetch transactions
      await _fetchTransactions(userId);
      await _fetchSpendFrequency(userId);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update _fetchTransactions to handle All option
  Future<void> _fetchTransactions(String userId) async {
    final _ = await supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    // Apply date filtering only if not showing all months
    final query = supabase.from('transactions').select().eq('user_id', userId);

    if (!_showAllMonths) {
      // Get start and end of selected month
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

      // Apply date filters
      final response = await query
          .gte('date', startOfMonth.toIso8601String())
          .lte('date', endOfMonth.toIso8601String())
          .order('created_at', ascending: false);

      await _processTransactions(response as List<dynamic>);
    } else {
      // Get all transactions without date filter
      final response = await query.order('created_at', ascending: false);
      await _processTransactions(response as List<dynamic>);
    }
  }

  // Helper to process transactions data
  Future<void> _processTransactions(List<dynamic> fetchedTransactions) async {
    double calculatedIncome = 0;
    double calculatedExpenses = 0;
    final List<Transaction> parsedTransactions = [];

    for (var t in fetchedTransactions) {
      final transaction = Transaction.fromJson(t);
      parsedTransactions.add(transaction);

      final amount = transaction.amount;
      if (transaction.type == 'income') {
        calculatedIncome += amount;
      } else if (transaction.type == 'expense') {
        calculatedExpenses += amount;
      }
    }

    if (!mounted) return;

    setState(() {
      _transactions = parsedTransactions;
      _income = calculatedIncome;
      _expenses = calculatedExpenses;
      _accountBalance = _income - _expenses;
    });
  }

  // Update _fetchSpendFrequency to handle All option
  Future<void> _fetchSpendFrequency(String userId) async {
    final query = supabase
        .from('transactions')
        .select('amount, type, date')
        .eq('user_id', userId);

    if (!_showAllMonths) {
      // Get start and end of selected month
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

      // Fetch transactions for the selected month
      final response = await query
          .gte('date', startOfMonth.toIso8601String())
          .lte('date', endOfMonth.toIso8601String())
          .order('date');

      await _processSpendFrequency(response as List<dynamic>);
    } else {
      // Get all transactions without date filter
      final response = await query.order('date');
      await _processSpendFrequency(response as List<dynamic>);
    }
  }

  // Helper to process spend frequency data
  Future<void> _processSpendFrequency(List<dynamic> rawData) async {
    if (!mounted) return;

    // Group data by transaction type (income vs expense)
    Map<String, double> typeData = {'Income': 0, 'Expense': 0};

    for (var item in rawData) {
      final type = item['type'] as String? ?? 'expense';
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

      if (type.toLowerCase() == 'income') {
        typeData['Income'] = (typeData['Income'] ?? 0) + amount;
      } else if (type.toLowerCase() == 'expense') {
        typeData['Expense'] = (typeData['Expense'] ?? 0) + amount;
      }
    }

    // Convert grouped data to the format needed for visualization
    List<Map<String, dynamic>> formattedData = [];

    typeData.forEach((key, value) {
      formattedData.add({
        'type': key,
        'amount': value,
        'date':
            DateTime.now()
                .toString(), // Not used for this visualization but kept for compatibility
      });
    });

    setState(() {
      _spendFrequencyData = formattedData;
    });
  }

  // Update _buildCustomAppBar to add month selection
  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            _fullName != null
                ? CircleAvatar(
                  backgroundImage: NetworkImage(_avatarUrl!),
                  radius: 18,
                )
                : const CircleAvatar(
                  child: Icon(Icons.person, color: Colors.purple),
                ),
      ),
      title: InkWell(
        onTap: () {
          // Show month picker
          _showMonthPicker(context);
        },
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
                style: const TextStyle(color: Colors.white, fontSize: 14),
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
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_outlined,
            color: Colors.white,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  // Update _showMonthPicker to include All option
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
                  _fetchUserDataAndMetrics(); // Reload data for all months
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
                        _fetchUserDataAndMetrics(); // Reload data for the new month
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

  // Define _buildBalanceCard method
  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7F3DFF), Color(0xFF5B16D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Account Balance',
            style: TextStyle(color: Colors.white70, fontSize: 20),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _accountBalance),
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                value.toRupiahFormat(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Define _buildStatCard method
  Widget _buildStatCard({
    required String title,
    required double amount,
    required Color backgroundColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: amount),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Text(
                value.toRupiahFormat(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Define _buildIncomeExpenseRow method
  Widget _buildIncomeExpenseRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Income',
            amount: _income,
            backgroundColor: const Color(0xFF2ECC71),
            icon: Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Expenses',
            amount: _expenses,
            backgroundColor: const Color(0xFFE74C3C),
            icon: Icons.arrow_upward,
          ),
        ),
      ],
    );
  }

  // Define _buildSpendFrequencyChart method
  Widget _buildSpendFrequencyChart() {
    if (_spendFrequencyData.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          "No financial data available for chart.",
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    // Calculate the total amount of all transactions
    final totalAmount = _spendFrequencyData.fold<double>(
      0,
      (sum, item) => sum + ((item['amount'] as num?)?.toDouble() ?? 0.0),
    );

    // Define fixed colors for income and expense
    final Map<String, Color> categoryColors = {
      'Income': const Color(0xFF2ECC71), // Green
      'Expense': const Color(0xFFE74C3C), // Red
    };

    // Prepare chart data with calculated percentages
    final List<Map<String, dynamic>> chartData = [];

    double incomeAmount = 0;
    double expenseAmount = 0;

    // Extract income and expense values
    for (var item in _spendFrequencyData) {
      final type = item['type'] as String? ?? 'Expense';
      final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

      if (type == 'Income') {
        incomeAmount = amount;
      } else if (type == 'Expense') {
        expenseAmount = amount;
      }
    }

    // Calculate percentages
    final double incomePercentage =
        totalAmount > 0 ? (incomeAmount / totalAmount * 100) : 0;
    final double expensePercentage =
        totalAmount > 0 ? (expenseAmount / totalAmount * 100) : 0;

    // Add to chart data
    chartData.add({
      'label': 'Income',
      'amount': incomeAmount,
      'percentage': incomePercentage.toStringAsFixed(1),
      'color': categoryColors['Income'],
    });

    chartData.add({
      'label': 'Expense',
      'amount': expenseAmount,
      'percentage': expensePercentage.toStringAsFixed(1),
      'color': categoryColors['Expense'],
    });

    final formattedTotal = totalAmount.toRupiahFormat();

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                DonutChartWidget(
                  segments:
                      _spendFrequencyData.map((item) {
                        // Make sure each segment has the right color based on type
                        final type = item['type'] as String? ?? 'Expense';
                        return {
                          ...item,
                          'color':
                              categoryColors[type] ?? const Color(0xFF7F3DFF),
                        };
                      }).toList(),
                  centerText: formattedTotal,
                ),
                // Animated ring effect
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7F3DFF).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend for the chart - Income vs Expense with overflow protection
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children:
              chartData.map((item) {
                final color = item['color'] as Color?;
                return Container(
                  constraints: const BoxConstraints(
                    minWidth: 100,
                    maxWidth: 160,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color ?? Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['label'] as String? ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(item['amount'] as double).toRupiahFormat()} (${item['percentage']}%)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  // Define _buildRecentTransactionsHeader method
  Widget _buildRecentTransactionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        TextButton(
          onPressed: () {
            // Navigate to all transactions
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EnhancedTransactionsPage(),
              ),
            );
          },
          child: const Text(
            'See All',
            style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Define _buildRecentTransactionList method
  Widget _buildRecentTransactionList() {
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              "No transactions yet",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your transactions will appear here",
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final displayedTransactions = _transactions.take(4).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayedTransactions.length,
      itemBuilder: (context, index) {
        final transaction = displayedTransactions[index];

        return TransactionCard(
          transaction: transaction,
          onTap: () {
            // Navigate to transaction detail screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        TransactionDetailScreen(transactionId: transaction.id),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: _buildCustomAppBar(),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF7F3DFF),
            strokeWidth: 3,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildCustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildIncomeExpenseRow(),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Income and Expense Analysis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSpendFrequencyChart(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildRecentTransactionsHeader(),
            const SizedBox(height: 12),
            _buildRecentTransactionList(),
          ],
        ),
      ),
    );
  }
}
