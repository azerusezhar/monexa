import 'package:flutter/material.dart';
import 'package:monexa/widget/chart_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monexa/widget/bottom_navigation.dart'; // Import BottomNavigation widget
import 'package:monexa/utils/formatters.dart'; // Import the formatters.dart file

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
  List<dynamic> _transactions = [];
  List<Map<String, dynamic>> _spendFrequencyData = [];
  bool _isLoading = true;
  String _selectedTimeFilter = "Today";
  final String _selectedMonth = "October";

  final Map<String, IconData> _categoryIcons = {
    'Shopping': Icons.shopping_bag_outlined,
    'Subscription': Icons.subscriptions_outlined,
    'Food': Icons.restaurant_outlined,
    'Default': Icons.wallet_outlined,
  };

  String? _fullName;
  String? _avatarUrl;

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

  // Define _fetchTransactions method
  Future<void> _fetchTransactions(String userId) async {
    final response = await supabase
        .from('transactions')
        .select()
        .eq('user_id', userId);

    double calculatedIncome = 0;
    double calculatedExpenses = 0;
    final List<dynamic> fetchedTransactions = response as List<dynamic>;

    for (var t in fetchedTransactions) {
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      if (t['type'] == 'income') {
        calculatedIncome += amount;
      } else if (t['type'] == 'expense') {
        calculatedExpenses += amount;
      }
    }

    if (!mounted) return;

    setState(() {
      _transactions = fetchedTransactions;
      _income = calculatedIncome;
      _expenses = calculatedExpenses;
      _accountBalance = _income - _expenses;
    });
  }

  // Define _fetchSpendFrequency method
  Future<void> _fetchSpendFrequency(String userId) async {
    final response = await supabase
        .from('transactions')
        .select('amount, date')
        .eq('user_id', userId)
        .eq('type', 'expense')
        .order('date');

    final List<dynamic> rawData = response as List<dynamic>;

    if (!mounted) return;

    setState(() {
      _spendFrequencyData =
          rawData.map((item) {
            final date = item['date'] as String? ?? 'Unknown Date';
            final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
            return {'date': date, 'amount': amount};
          }).toList();
    });
  }

  // Define _buildCustomAppBar method
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
          // Can add month picker here
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
                style: const TextStyle(color: Colors.white60, fontSize: 14),
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

  // Define _buildBalanceCard method
  Widget _buildBalanceCard() {
    return Center(
      child: Column(
        children: [
          const Text(
            'Account Balance',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _accountBalance.toRupiahFormat(), // Use the formatter here
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
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
            icon: Icons.arrow_downward,
            iconColor: Colors.white,
            backgroundColor: const Color(0xFF2ECC71),
            iconBackgroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Expenses',
            amount: _expenses,
            icon: Icons.arrow_upward,
            iconColor: Colors.white,
            backgroundColor: const Color(0xFFE74C3C),
            iconBackgroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // Define _buildStatCard method
  Widget _buildStatCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color iconBackgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBackgroundColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                amount.toRupiahFormat(), // Use the formatter here
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Define _buildSpendFrequencyChart method
  Widget _buildSpendFrequencyChart() {
    if (_spendFrequencyData.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          "No spend data available for chart.",
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    return SizedBox(
      height: 200,
      child: ChartWidget(data: _spendFrequencyData, lineColor: Colors.purple),
    );
  }

  // Define _buildTimeFilter method
  Widget _buildTimeFilter() {
    final filters = ["Today", "Week", "Month", "Year"];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedTimeFilter == filters[index];
          return ChoiceChip(
            label: Text(filters[index]),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedTimeFilter = filters[index];
                });
              }
            },
            backgroundColor: Colors.grey[800],
            selectedColor: Colors.purple,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
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
  // Define _buildRecentTransactionList method
  Widget _buildRecentTransactionList() {
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Text(
          "No transactions yet.",
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    final displayedTransactions = _transactions.take(4).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayedTransactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = displayedTransactions[index];
        final description = item['description'] as String? ?? 'No description';
        final category = item['category'] as String? ?? 'Other';
        final dateOrTime = item['date'] as String? ?? 'Unknown Date';
        final type = item['type'] as String?;
        final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;

        // Use the formatter for the amount
        final formattedAmount = amount.toRupiahFormat(); // Apply the formatter

        // Get the appropriate icon for the category
        IconData transactionIcon =
            _categoryIcons[category] ?? _categoryIcons['Default']!;
        Color iconContainerColor = Colors.grey.withOpacity(0.2);

        if (category == 'Shopping') {
          iconContainerColor = Colors.orange.withOpacity(0.2);
        } else if (category == 'Subscription') {
          iconContainerColor = Colors.blue.withOpacity(0.2);
        } else if (category == 'Food') {
          iconContainerColor = Colors.pink.withOpacity(0.2);
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconContainerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(transactionIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateOrTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              // Use the formatted amount here
              Text(
                '${type == 'income' ? '+' : '-'}$formattedAmount', // Use the formatted amount
                style: TextStyle(
                  color:
                      type == 'income'
                          ? const Color(0xFF2ECC71)
                          : const Color(0xFFE74C3C),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
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
          child: CircularProgressIndicator(color: Colors.purple),
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
            const SizedBox(height: 24),
            const Text(
              'Spend Frequency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            _buildSpendFrequencyChart(),
            const SizedBox(height: 24),
            _buildTimeFilter(),
            const SizedBox(height: 16),
            _buildRecentTransactionsHeader(),
            const SizedBox(height: 8),
            _buildRecentTransactionList(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 0),
    );
  }
}
