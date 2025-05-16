import 'package:flutter/material.dart';
import 'package:monexa/screens/budget/budget.dart';
import 'package:monexa/screens/dashboard/dashboard_screen.dart';
import 'package:monexa/screens/profiles/profiles_screen.dart';
import 'package:monexa/screens/transaction/transaction_screen.dart';
import 'package:monexa/screens/transaction/add_income_screen.dart';
import 'package:monexa/screens/transaction/add_expense_screen.dart';
import 'package:monexa/widgets/bottom_navigation.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  final List<Widget> _pages = [
    const DashboardScreen(),
    const EnhancedTransactionsPage(),
    const BudgetPage(),
    const ProfilePage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onIndexChanged(int index) {
    setState(() {
      _currentIndex = index;
      // Use animateToPage for smooth transition between pages
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _navigateToAddIncome() {
    // Navigate to add income page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddIncomeScreen(),
      ),
    );
  }

  void _navigateToAddExpense() {
    // Navigate to add expense page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      extendBody: true, // Important for proper bottom nav appearance
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onIndexChanged: _onIndexChanged,
        onAddIncome: _navigateToAddIncome,
        onAddExpense: _navigateToAddExpense,
      ),
    );
  }
}



// Placeholder for AddIncomePage
class AddIncomePage extends StatelessWidget {
  const AddIncomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Income'),
        backgroundColor: Colors.green.shade500,
      ),
      body: const Center(child: Text('Add Income Form')),
    );
  }
}

// Placeholder for AddExpensePage
class AddExpensePage extends StatelessWidget {
  const AddExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: Colors.red.shade500,
      ),
      body: const Center(child: Text('Add Expense Form')),
    );
  }
}