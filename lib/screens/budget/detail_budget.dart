import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monexa/utils/transaction_category.dart';

// Primary color of the app
const kPrimaryColor = Color(0xFF7F3DFF);

class DetailBudgetPage extends StatefulWidget {
  final String? budgetId; // Optional - if we're passing the ID directly
  final String category;
  final int spent;
  final int limit;
  final Color categoryColor;
  final VoidCallback?
  onBudgetUpdated; // Callback for when budget is updated or deleted

  const DetailBudgetPage({
    super.key,
    this.budgetId,
    required this.category,
    required this.spent,
    required this.limit,
    required this.categoryColor,
    this.onBudgetUpdated,
  });

  @override
  State<DetailBudgetPage> createState() => _DetailBudgetPageState();
}

class _DetailBudgetPageState extends State<DetailBudgetPage> {
  bool _isDeleting = false;
  late final SupabaseClient supabase;
  int _spent = 0;
  int _limit = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    supabase = Supabase.instance.client;
    _spent = widget.spent;
    _limit = widget.limit;
    fetchBudgetDetails();
  }

  Future<void> fetchBudgetDetails() async {
    if (widget.budgetId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the budget from Supabase
      final budget =
          await supabase
              .from('budgets')
              .select('*')
              .eq('id', widget.budgetId!)
              .single();

      // Calculate spending for this budget
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Get transactions for this category
      var query = supabase
          .from('transactions')
          .select('amount')
          .eq('user_id', user.id)
          .eq('category', widget.category)
          .eq('type', 'expense');

      // Apply date filter based on budget's month_year
      final monthYear = budget['month_year'];
      if (monthYear != null) {
        final date = DateTime.parse(monthYear);
        final startOfMonth = DateTime(date.year, date.month, 1);
        final endOfMonth = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

        query = query
            .gte('date', startOfMonth.toIso8601String())
            .lte('date', endOfMonth.toIso8601String());
      }

      final transactions = await query;

      // Calculate total spent
      int totalSpent = 0;
      for (var transaction in transactions) {
        totalSpent += (transaction['amount'] as num).toInt();
      }

      if (mounted) {
        setState(() {
          _limit = budget['limit_amount'].toInt();
          _spent = totalSpent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budget details: $e')),
        );
      }
    }
  }

  Future<void> _deleteBudget() async {
    if (widget.budgetId == null) {
      Navigator.pop(context); // Just go back if no ID (shouldn't happen)
      return;
    }

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Delete Budget',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this budget? This action cannot be undone.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red[300]),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      // Delete the budget from Supabase
      await supabase
          .from('budgets')
          .delete()
          .eq(
            'id',
            widget.budgetId!,
          ); // Using ! since we already checked it's not null

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget deleted successfully')),
        );

        // Call the callback to refresh the budget list
        if (widget.onBudgetUpdated != null) {
          widget.onBudgetUpdated!();
        }

        // Go back to the budget list
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting budget: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverLimit = _spent > _limit;
    final categoryInfo = TransactionCategory.fromName(widget.category);

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Detail Budget',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon:
                _isDeleting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _isDeleting ? null : _deleteBudget,
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
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7F3DFF),
                  strokeWidth: 3,
                ),
              )
              : RefreshIndicator(
                color: const Color(0xFF7F3DFF),
                backgroundColor: Colors.grey[900],
                onRefresh: fetchBudgetDetails,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Category
                      Hero(
                        tag: 'budget_card_${widget.category}',
                        child: Material(
                          type: MaterialType.transparency,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2C2C2E),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      categoryInfo.icon,
                                      color: widget.categoryColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.category,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Remaining
                      const Text(
                        'Remaining',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isOverLimit
                            ? 'Rp0'
                            : currencyFormat.format(_limit - _spent),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Progress Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _spent > _limit ? 1 : _spent / _limit,
                            minHeight: 8,
                            backgroundColor: Colors.white30,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverLimit
                                  ? Colors.redAccent
                                  : widget.categoryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Error Message
                      if (isOverLimit)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "You've exceed the limit",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Show budget details
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Budget Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDetailRow('Category', widget.category),
                            _buildDetailRow(
                              'Budget Limit',
                              currencyFormat.format(_limit),
                            ),
                            _buildDetailRow(
                              'Spent',
                              currencyFormat.format(_spent),
                            ),
                            _buildDetailRow(
                              'Remaining',
                              isOverLimit
                                  ? 'Rp0'
                                  : currencyFormat.format(_limit - _spent),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 100,
                      ), // Add extra space at the bottom for scrolling
                      // Edit Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EditBudgetPage(
                                        budgetId: widget.budgetId,
                                        category: widget.category,
                                        limit: _limit,
                                        categoryColor: widget.categoryColor,
                                        onBudgetUpdated: () {
                                          fetchBudgetDetails();
                                          if (widget.onBudgetUpdated != null) {
                                            widget.onBudgetUpdated!();
                                          }
                                        },
                                      ),
                                ),
                              );
                            },
                            child: const Text(
                              "Edit",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bottom Indicator
                      Center(
                        child: Container(
                          width: 120,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class EditBudgetPage extends StatefulWidget {
  final String? budgetId;
  final String category;
  final int limit;
  final Color categoryColor;
  final VoidCallback? onBudgetUpdated;

  const EditBudgetPage({
    super.key,
    this.budgetId,
    required this.category,
    required this.limit,
    required this.categoryColor,
    this.onBudgetUpdated,
  });

  @override
  State<EditBudgetPage> createState() => _EditBudgetPageState();
}

class _EditBudgetPageState extends State<EditBudgetPage> {
  final TextEditingController amountController = TextEditingController();
  final amountPreview = ValueNotifier<String>('0');
  bool _receiveAlert = true;
  double _alertThreshold = 0.8;
  bool _isSaving = false;
  late final SupabaseClient supabase;

  @override
  void initState() {
    super.initState();
    // Initialize with existing budget limit
    amountController.text = NumberFormat.decimalPattern(
      'id',
    ).format(widget.limit);
    amountController.addListener(_formatCurrency);
    // Initialize preview with current value
    amountPreview.value = amountController.text;
    supabase = Supabase.instance.client;
  }

  @override
  void dispose() {
    amountController.removeListener(_formatCurrency);
    amountController.dispose();
    amountPreview.dispose();
    super.dispose();
  }

  void _formatCurrency() {
    String digitsOnly = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      amountController.value = const TextEditingValue(text: '');
      // Update preview
      amountPreview.value = '0';
      return;
    }

    final number = int.tryParse(digitsOnly);
    if (number == null) return;

    final formatted = NumberFormat.decimalPattern('id').format(number);

    amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    // Update preview
    amountPreview.value = formatted;
  }

  Future<void> _updateBudget() async {
    if (widget.budgetId == null) {
      Navigator.pop(context); // Just go back if no ID (shouldn't happen)
      return;
    }

    // Validate inputs
    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a budget amount')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Parse the amount from the formatted string
      final amountString = amountController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final amount = double.parse(amountString);

      // Update the budget in Supabase
      await supabase
          .from('budgets')
          .update({'limit_amount': amount})
          .eq(
            'id',
            widget.budgetId!,
          ); // Using ! since we already checked it's not null

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget updated successfully')),
        );

        // Call the callback to refresh the budget list
        if (widget.onBudgetUpdated != null) {
          widget.onBudgetUpdated!();
        }

        // Go back to the budget detail screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating budget: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Budget',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header with amount preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: const BoxDecoration(color: kPrimaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "How much do you want to spend?",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Rp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: amountPreview,
                        builder:
                            (context, value, _) => Text(
                              value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      ),
                    ),
                  ],
                ),
                // Show category
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        TransactionCategory.fromName(widget.category).icon,
                        color: widget.categoryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Budget for ${widget.category}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Form section
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: const BoxDecoration(
                color: Color(0xFF151515),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hidden amount field
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Amount'),
                    ),
                    const SizedBox(height: 24),
                    // Category (non-editable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              TransactionCategory.fromName(
                                widget.category,
                              ).icon,
                              color: widget.categoryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Receive Alert",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Receive alert when it reaches some point.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _receiveAlert,
                          onChanged: (value) {
                            setState(() {
                              _receiveAlert = value;
                            });
                          },
                          activeColor: Colors.white,
                          activeTrackColor: kPrimaryColor,
                          inactiveTrackColor: const Color(0xFF1C1C1E),
                          inactiveThumbColor: Colors.white,
                        ),
                      ],
                    ),
                    if (_receiveAlert) ...[
                      const SizedBox(height: 24),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: kPrimaryColor,
                              inactiveTrackColor: Colors.grey.withOpacity(0.3),
                              thumbColor: Colors.white,
                              overlayColor: kPrimaryColor.withOpacity(0.2),
                              trackHeight: 8,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                              ),
                            ),
                            child: Slider(
                              value: _alertThreshold,
                              min: 0.1,
                              max: 1.0,
                              divisions: 9,
                              onChanged: (value) {
                                setState(() {
                                  _alertThreshold = value;
                                });
                              },
                            ),
                          ),
                          Positioned(
                            left:
                                (_alertThreshold *
                                    (MediaQuery.of(context).size.width - 80)) +
                                16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "${(_alertThreshold * 100).round()}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Continue button at the bottom
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF151515),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isSaving ? null : _updateBudget,
                child:
                    _isSaving
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Text(
                          "Continue",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
