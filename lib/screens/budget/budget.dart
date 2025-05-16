import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monexa/utils/formatters.dart';
import 'package:monexa/utils/transaction_category.dart';
import 'budget_card.dart';
import 'create_budget.dart';
import 'detail_budget.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> with TickerProviderStateMixin {
  late DateTime _selectedDate;
  bool _showAllMonths = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _allBudgets = []; // Master copy of all budgets
  late final SupabaseClient supabase;
  late TabController _tabController;
  final List<String> _filterOptions = ['All', 'Exceed', 'Safe', 'Warn'];
  String _currentFilter = 'All';

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

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    supabase = Supabase.instance.client;
    _tabController = TabController(length: _filterOptions.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {
          _currentFilter = _filterOptions[_tabController.index];
          _filterBudgets();
        });
      }
    });

    _fetchBudgets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBudgets() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final userId = user.id;

      var query = supabase.from('budgets').select('*').eq('user_id', userId);

      if (!_showAllMonths) {
        final monthYear = DateFormat(
          'yyyy-MM-dd',
        ).format(DateTime(_selectedDate.year, _selectedDate.month, 1));
        query = query.eq('month_year', monthYear);
      }

      // Execute query
      final response = await query;
      final budgets = List<Map<String, dynamic>>.from(response);

      // Calculate spending for each budget category
      await _calculateSpendingForBudgets(budgets, userId);

      if (!mounted) return;

      setState(() {
        _allBudgets = List.from(budgets);
        _isLoading = false;
      });

      // Apply the current filter
      _filterBudgets();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading budgets: $e')));
      }
    }
  }

  // Apply filters based on selected tab
  void _filterBudgets() {
    if (!mounted) return;

    if (_currentFilter == 'All') {
      setState(() {
        _budgets = List.from(_allBudgets);
      });
      return;
    }

    // Filter from the master list
    final filteredBudgets =
        _allBudgets.where((budget) {
          final spent = (budget['spent'] as num?)?.toDouble() ?? 0;
          final limit = (budget['limit_amount'] as num).toDouble();
          final ratio = spent / limit;

          switch (_currentFilter) {
            case 'Exceed':
              return ratio > 1.0;
            case 'Warn':
              return ratio >= 0.8 && ratio <= 1.0;
            case 'Safe':
              return ratio < 0.8;
            default:
              return true;
          }
        }).toList();

    if (!mounted) return;

    setState(() {
      _budgets = filteredBudgets;
    });
  }

  Future<void> _calculateSpendingForBudgets(
    List<Map<String, dynamic>> budgets,
    String userId,
  ) async {
    try {
      // Set up transactions query
      var transactionsQuery = supabase
          .from('transactions')
          .select('category, amount, type, date')
          .eq('user_id', userId)
          .eq('type', 'expense');

      // Apply date filtering if not showing all months
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

        transactionsQuery = transactionsQuery
            .gte('date', startOfMonth.toIso8601String())
            .lte('date', endOfMonth.toIso8601String());
      }

      // Get transactions
      final transactionsResponse = await transactionsQuery;
      final transactions = List<Map<String, dynamic>>.from(
        transactionsResponse,
      );

      // Calculate spending by category
      final Map<String, double> spendingByCategory = {};

      for (final transaction in transactions) {
        final category = transaction['category'] as String;
        final amount = (transaction['amount'] as num).toDouble();

        spendingByCategory[category] =
            (spendingByCategory[category] ?? 0) + amount;
      }

      // Update budgets with spending data
      for (final budget in budgets) {
        final category = budget['category'] as String;
        final spent = spendingByCategory[category] ?? 0;
        budget['spent'] = spent; // Add spent amount to budget data
      }
    } catch (e) {
      // Just log the error but continue with zero spending
      for (final budget in budgets) {
        budget['spent'] = 0.0;
      }
      print('Error calculating spending: $e');
    }
  }

  // New function to check if a budget exists for a given category in the selected month
  Future<bool> _checkBudgetExists(String category) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final monthYear = DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(_selectedDate.year, _selectedDate.month, 1));

      final response = await supabase
          .from('budgets')
          .select('id')
          .eq('user_id', user.id)
          .eq('category', category)
          .eq('month_year', monthYear);

      final budgets = List<Map<String, dynamic>>.from(response);
      return budgets.isNotEmpty;
    } catch (e) {
      print('Error checking if budget exists: $e');
      return false;
    }
  }

  // Show a dialog to select a category before creating a budget
  void _showCategorySelectionDialog(BuildContext context) {
    final categories = [
      'shopping',
      'food',
      'transportation',
      'health',
      'entertainment',
      'bills',
      'rent',
      'education',
      'travel',
      'clothing',
      'others',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Select Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final categoryInfo = TransactionCategory.fromName(category);

                    return FutureBuilder<bool>(
                      future: _checkBudgetExists(category),
                      builder: (context, snapshot) {
                        final exists = snapshot.data ?? false;

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              categoryInfo.icon,
                              color: categoryInfo.color,
                            ),
                          ),
                          title: Text(
                            categoryInfo.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing:
                              exists
                                  ? const Chip(
                                    label: Text(
                                      'Exists',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    backgroundColor: Colors.grey,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  )
                                  : const Icon(
                                    Icons.add_circle_outline,
                                    color: Color(0xFF7F3DFF),
                                  ),
                          onTap: () {
                            Navigator.pop(context);
                            if (exists) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'A budget for ${categoryInfo.label} already exists for this month',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => CreateBudgetPage(
                                        selectedDate: _selectedDate,
                                        preSelectedCategory: category,
                                        onBudgetCreated: () {
                                          // Safely fetch budgets after budget creation
                                          if (mounted) {
                                            _fetchBudgets();
                                          }
                                        },
                                      ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
    );
  }

  // Show month picker dialog with enhanced UI
  void _showMonthPicker(BuildContext context) async {
    final double sheetHeight = MediaQuery.of(context).size.height * 0.7;
    final DateTime now = DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Function to safely fetch budgets after navigation
            void safelyFetchBudgets() {
              // Use Future.microtask to ensure we're not calling setState after the widget is disposed
              Future.microtask(() {
                if (mounted) {
                  _fetchBudgets();
                }
              });
            }

            return Container(
              height: sheetHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Time Period',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Year selector - only show if not in "All" mode
                        if (!_showAllMonths)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF7F3DFF),
                                width: 1,
                              ),
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
                                    });
                                  },
                                  child: const Icon(
                                    Icons.arrow_left,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${_selectedDate.year}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      // Increase year (but don't go beyond current year+1)
                                      if (_selectedDate.year < now.year + 1) {
                                        _selectedDate = DateTime(
                                          _selectedDate.year + 1,
                                          _selectedDate.month,
                                          1,
                                        );
                                      }
                                    });
                                  },
                                  child: Icon(
                                    Icons.arrow_right,
                                    color:
                                        _selectedDate.year < now.year + 1
                                            ? Colors.white
                                            : Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Divider(color: Color(0xFF2C2C2E)),

                  // All time option
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            _showAllMonths
                                ? const Color(0xFF7F3DFF).withOpacity(0.2)
                                : const Color(0xFF2C2C2E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_view_month_outlined,
                        color: Color(0xFF7F3DFF),
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'All Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text(
                      'View budget data from all months',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing:
                        _showAllMonths
                            ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF7F3DFF),
                            )
                            : null,
                    onTap: () {
                      _showAllMonths = true;
                      Navigator.pop(context);
                      safelyFetchBudgets(); // Safely reload data
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(color: Color(0xFF2C2C2E)),
                  ),

                  // Current month quick selection
                  if (!(_selectedDate.year == now.year &&
                          _selectedDate.month == now.month) &&
                      !_showAllMonths)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.today,
                          color: Colors.blue,
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Current Month',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '${_getMonthName(now.month)} ${now.year}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _showAllMonths = false;
                          _selectedDate = DateTime(now.year, now.month, 1);
                        });
                        Navigator.pop(context);
                        safelyFetchBudgets(); // Safely reload data
                      },
                    ),

                  if (!(_selectedDate.year == now.year &&
                          _selectedDate.month == now.month) &&
                      !_showAllMonths)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(color: Color(0xFF2C2C2E)),
                    ),

                  const Padding(
                    padding: EdgeInsets.only(left: 20, top: 8, bottom: 8),
                    child: Text(
                      'SELECT MONTH',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // Month grid
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
                        final isSelected =
                            !_showAllMonths && month == _selectedDate.month;
                        final isCurrentMonth =
                            month == now.month &&
                            _selectedDate.year == now.year;

                        return InkWell(
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
                            safelyFetchBudgets(); // Safely reload data
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFF7F3DFF).withOpacity(0.2)
                                      : const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  isSelected
                                      ? Border.all(
                                        color: const Color(0xFF7F3DFF),
                                      )
                                      : isCurrentMonth
                                      ? Border.all(
                                        color: Colors.blue.withOpacity(0.5),
                                      )
                                      : null,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _getMonthName(month).substring(0, 3),
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? const Color(0xFF7F3DFF)
                                              : isCurrentMonth
                                              ? Colors.blue
                                              : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (isCurrentMonth && !isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7F3DFF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              safelyFetchBudgets(); // Safely reload data
                            },
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Budget',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 10,
              ), // Increased spacing between title and month
              InkWell(
                onTap: () => _showMonthPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical:
                        8, // Increased vertical padding for better touch area
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[800]!, const Color(0xFF2C2C2E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF7F3DFF).withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF7F3DFF),
                        size: 16, // Slightly larger icon
                      ),
                      const SizedBox(width: 8), // Increased spacing
                      Text(
                        _selectedMonth,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ), // Slightly larger text
                      ),
                      const SizedBox(width: 8), // Increased spacing
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white60,
                        size: 16, // Slightly larger icon
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Add budget button
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 24, // Slightly larger icon
              ),
              onPressed: () => _showCategorySelectionDialog(context),
              tooltip: 'Add new budget',
            ),
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
          preferredSize: const Size.fromHeight(
            65,
          ), // Increased height for filter bar
          child: Container(
            margin: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12, // Added bottom margin
              top: 6, // Added top margin
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                4.0,
              ), // Padding around the entire TabBar
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF7F3DFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                indicatorPadding: const EdgeInsets.symmetric(
                  horizontal: -12,
                  vertical: 2,
                ), // This creates space between indicator and tab edges
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12, // Smaller font size to prevent overflow
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 12, // Smaller font size to prevent overflow
                ),
                isScrollable: false,
                labelPadding: const EdgeInsets.symmetric(
                  horizontal:
                      1, // Reduced horizontal padding to prevent overflow
                ), // Reduced padding for more compact tabs
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                ), // Vertical padding around entire row
                tabAlignment: TabAlignment.fill,
                dividerColor: Colors.transparent, // Remove the bottom line
                tabs: [
                  Tab(
                    height: 40, // Ensure consistent height
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.all_inclusive, size: 12), // Smaller icon
                        SizedBox(width: 2),
                        Text('All'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 40, // Ensure consistent height
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 12,
                        ), // Smaller icon
                        SizedBox(width: 2),
                        Text('Exceed'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 40, // Ensure consistent height
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.check_circle_outline,
                          size: 12,
                        ), // Smaller icon
                        SizedBox(width: 2),
                        Text('Safe'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 40, // Ensure consistent height
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.error_outline, size: 12), // Smaller icon
                        SizedBox(width: 2),
                        Text('Warn'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7F3DFF),
                  strokeWidth: 3,
                ),
              )
              : Column(
                children: [
                  const SizedBox(height: 16),

                  // Summary section
                  if (!_isLoading && _budgets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _buildSummaryCards(),
                    ),

                  Expanded(
                    child:
                        _budgets.isEmpty
                            ? _buildEmptyState()
                            : Stack(
                              children: [
                                RefreshIndicator(
                                  onRefresh: () async {
                                    await _fetchBudgets();
                                  },
                                  color: const Color(0xFF7F3DFF),
                                  backgroundColor: Colors.grey[900],
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom:
                                          100, // Extra padding at bottom for FAB
                                    ),
                                    itemCount: _budgets.length,
                                    itemBuilder: (context, index) {
                                      final budget = _budgets[index];

                                      // Use the spent amount we calculated
                                      final spent =
                                          (budget['spent'] as num?)?.toInt() ??
                                          0;
                                      final limit =
                                          (budget['limit_amount'] as num)
                                              .toInt();

                                      // Get category info from utility
                                      final categoryInfo =
                                          TransactionCategory.fromName(
                                            budget['category'],
                                          );

                                      return BudgetCard(
                                        category: budget['category'],
                                        spent: spent,
                                        limit: limit,
                                        categoryColor: categoryInfo.color,
                                        onTap: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => DetailBudgetPage(
                                                    budgetId: budget['id'],
                                                    category:
                                                        budget['category'],
                                                    spent: spent,
                                                    limit: limit,
                                                    categoryColor:
                                                        categoryInfo.color,
                                                    onBudgetUpdated: () {
                                                      _fetchBudgets();
                                                    },
                                                  ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),

                                // Improved Create button for when budgets exist - shown within content
                                Positioned(
                                  bottom: 20,
                                  right: 20,
                                  child: Container(
                                    height: 60, // Fixed height
                                    width: 60, // Fixed width
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF7F3DFF),
                                          Color(0xFF6E35D9),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF7F3DFF,
                                          ).withOpacity(0.4),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(30),
                                        onTap: () {
                                          _showCategorySelectionDialog(context);
                                        },
                                        child: const Center(
                                          child: Icon(
                                            Icons.add,
                                            color: Colors.white,
                                            size: 28, // Larger icon
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                  ),
                ],
              ),
      // Only show extended FAB if no budgets exist
      floatingActionButton:
          _budgets.isEmpty
              ? Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7F3DFF).withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    _showCategorySelectionDialog(context);
                  },
                  backgroundColor: const Color(0xFF7F3DFF),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  icon: const Icon(Icons.add, color: Colors.white, size: 24),
                  label: const Text(
                    "Create Budget",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
              : null,
    );
  }

  // Budget summary cards
  Widget _buildSummaryCards() {
    double totalBudgetAmount = 0;
    double totalSpentAmount = 0;
    int exceededCount = 0;
    int warningCount = 0;

    for (final budget in _budgets) {
      final spent = (budget['spent'] as num?)?.toDouble() ?? 0;
      final limit = (budget['limit_amount'] as num).toDouble();

      totalBudgetAmount += limit;
      totalSpentAmount += spent;

      final ratio = spent / limit;
      if (ratio > 1.0) {
        exceededCount++;
      } else if (ratio >= 0.8) {
        warningCount++;
      }
    }

    final remainingAmount = totalBudgetAmount - totalSpentAmount;
    final usagePercentage =
        totalBudgetAmount > 0
            ? (totalSpentAmount / totalBudgetAmount * 100).round()
            : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C2C2E),
            Color.alphaBlend(
              const Color(0xFF7F3DFF).withOpacity(0.15),
              const Color(0xFF2C2C2E),
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _showAllMonths ? "All Time Budget" : "Monthly Budget",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F3DFF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${_budgets.length} Budget${_budgets.length != 1 ? 's' : ''}",
                  style: const TextStyle(
                    color: Color(0xFF7F3DFF),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Budget spent info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Budget Spent",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      totalSpentAmount.toRupiahFormat(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "of ${totalBudgetAmount.toRupiahFormat()}",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Budget remaining info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Budget Remaining",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      remainingAmount > 0
                          ? remainingAmount.toRupiahFormat()
                          : "Rp. 0",
                      style: TextStyle(
                        color: remainingAmount > 0 ? Colors.green : Colors.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$usagePercentage% of budget used",
                      style: TextStyle(
                        color:
                            usagePercentage >= 100
                                ? Colors.red
                                : usagePercentage >= 80
                                ? Colors.orange
                                : Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Status summary
              if (exceededCount > 0 || warningCount > 0)
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (exceededCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$exceededCount exceeded",
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      if (exceededCount > 0 && warningCount > 0)
                        const SizedBox(height: 4),
                      if (warningCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_outlined,
                              color: Colors.amber[700],
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$warningCount warning",
                              style: TextStyle(
                                color: Colors.amber[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value:
                  totalBudgetAmount > 0
                      ? (totalSpentAmount / totalBudgetAmount > 1.0
                          ? 1.0
                          : totalSpentAmount / totalBudgetAmount)
                      : 0.0,
              minHeight: 10,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                totalSpentAmount > totalBudgetAmount
                    ? Colors.red
                    : totalSpentAmount / totalBudgetAmount >= 0.8
                    ? Colors.orange
                    : const Color(0xFF7F3DFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get color based on category

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7F3DFF).withOpacity(0.1),
                  const Color(0xFF7F3DFF).withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7F3DFF).withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.purpleAccent[100],
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No budgets found",
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _showAllMonths
                  ? "You haven't created any budgets yet"
                  : "No budgets for ${_getMonthName(_selectedDate.month)} ${_selectedDate.year}",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              _showCategorySelectionDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7F3DFF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              "Create Budget",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
