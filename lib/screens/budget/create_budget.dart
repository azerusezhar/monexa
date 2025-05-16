import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monexa/utils/transaction_category.dart';

// Primary color of the app
const kPrimaryColor = Color(0xFF7F3DFF);

class CreateBudgetPage extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onBudgetCreated;
  final String? preSelectedCategory;

  const CreateBudgetPage({
    super.key,
    required this.selectedDate,
    required this.onBudgetCreated,
    this.preSelectedCategory,
  });

  @override
  State<CreateBudgetPage> createState() => _CreateBudgetPageState();
}

class _CreateBudgetPageState extends State<CreateBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _categories = [
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

  late String _selectedCategory;
  bool _receiveAlert = false;
  double _alertThreshold = 0.8; // Changed to 80% default
  bool _isLoading = false;
  late final SupabaseClient supabase;

  // Amount input controllers
  final TextEditingController amountController = TextEditingController();
  final amountPreview = ValueNotifier<String>('0');

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.preSelectedCategory ?? 'shopping';
    amountController.addListener(_formatCurrency);
    supabase = Supabase.instance.client;
  }

  @override
  void dispose() {
    amountController.removeListener(_formatCurrency);
    amountController.dispose();
    amountPreview.dispose(); // Dispose the notifier
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

  Future<void> _createBudget() async {
    // Validate the form
    if (!_formKey.currentState!.validate()) {
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
      _isLoading = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not authenticated");

      // Parse the amount from the formatted string
      final amountString = amountController.text.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );
      final amount = double.parse(amountString);

      // Format the date for storing in the database
      final monthYear = DateFormat('yyyy-MM-dd').format(widget.selectedDate);

      // Create the budget in Supabase
      await supabase.from('budgets').insert({
        'user_id': user.id,
        'category': _selectedCategory,
        'limit_amount': amount,
        'month_year': monthYear,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget created successfully')),
        );

        // Call the callback to refresh the budget list
        widget.onBudgetCreated();

        // Go back to the budget list page without animation
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating budget: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          'Create Budget',
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
                // Show selected month/year
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Budget for ${DateFormat('MMMM yyyy').format(widget.selectedDate)}",
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
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFF151515),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hidden amount field that's not visible to user
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Amount'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = int.tryParse(
                            value.replaceAll(RegExp(r'[^0-9]'), ''),
                          );
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: _inputDecoration('Category'),
                        dropdownColor: const Color(0xFF1C1C1E),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        items:
                            _categories.map((category) {
                              final categoryInfo = TransactionCategory.fromName(
                                category,
                              );
                              return DropdownMenuItem(
                                value: category,
                                child: Row(
                                  children: [
                                    Icon(
                                      categoryInfo.icon,
                                      color: categoryInfo.color,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(categoryInfo.label),
                                  ],
                                ),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
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
                                inactiveTrackColor: Colors.grey.withOpacity(
                                  0.3,
                                ),
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
                                      (MediaQuery.of(context).size.width -
                                          80)) +
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
                onPressed: _isLoading ? null : _createBudget,
                child:
                    _isLoading
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
}
