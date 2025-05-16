import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:monexa/utils/transaction_category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;
  Map<String, dynamic>? transactionData;

  // Controllers for editing
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  String? _selectedType;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    fetchTransactionDetails();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> fetchTransactionDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // Fetch transaction data from Supabase
      final response =
          await supabase
              .from('transactions')
              .select('*')
              .eq('id', widget.transactionId)
              .single();

      setState(() {
        transactionData = response;
        isLoading = false;

        // Initialize controllers with current data
        _amountController.text = response['amount'].toString();
        _descriptionController.text = response['description'] ?? '';
        _selectedCategory = response['category'];
        _selectedType = response['type'];
        _selectedDate = DateTime.parse(response['date']);
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transaction: $e')),
        );
      }
    }
  }

  Future<void> saveTransaction() async {
    if (!_validateInputs()) return;

    setState(() {
      isSaving = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // Prepare updated data
      final updatedData = {
        'amount': double.parse(_amountController.text),
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'type': _selectedType,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      };

      // Update transaction in Supabase
      await supabase
          .from('transactions')
          .update(updatedData)
          .eq('id', widget.transactionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction updated successfully')),
        );
        setState(() {
          isEditing = false;
          isSaving = false;
          fetchTransactionDetails(); // Refresh data
        });

        // Return true to indicate transaction was updated
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating transaction: $e')),
        );
      }
    }
  }

  bool _validateInputs() {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter an amount')));
      return false;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return false;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a transaction type')),
      );
      return false;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return false;
    }

    return true;
  }

  Future<void> deleteTransaction() async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Delete Transaction',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Are you sure you want to delete this transaction? This action cannot be undone.',
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
      isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // Delete transaction from Supabase
      await supabase
          .from('transactions')
          .delete()
          .eq('id', widget.transactionId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate delete happened
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting transaction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditing ? "Edit Transaction" : "Transaction Details",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A1A), Color(0xFF000000)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          if (!isEditing && !isLoading)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
          if (!isEditing && !isLoading)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: deleteTransaction,
            ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : transactionData == null
              ? Center(
                child: Text(
                  "Transaction not found",
                  style: TextStyle(color: Colors.grey[500]),
                ),
              )
              : RefreshIndicator(
                color: const Color(0xFF7F3DFF),
                backgroundColor: Colors.grey[900],
                onRefresh: () async {
                  await fetchTransactionDetails();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child:
                      isEditing ? _buildEditForm() : _buildTransactionDetails(),
                ),
              ),
      bottomNavigationBar:
          isEditing
              ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed:
                            isSaving
                                ? null
                                : () {
                                  setState(() {
                                    isEditing = false;

                                    // Reset controllers to original values
                                    _amountController.text =
                                        transactionData!['amount'].toString();
                                    _descriptionController.text =
                                        transactionData!['description'] ?? '';
                                    _selectedCategory =
                                        transactionData!['category'];
                                    _selectedType = transactionData!['type'];
                                    _selectedDate = DateTime.parse(
                                      transactionData!['date'],
                                    );
                                  });
                                },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            isSaving
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  "Save",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              )
              : null,
    );
  }

  Widget _buildTransactionDetails() {
    final category = TransactionCategory.fromName(transactionData!['category']);
    final isIncome =
        transactionData!['type'].toString().toLowerCase() == 'income';
    final amount = transactionData!['amount'].toDouble();
    final description = transactionData!['description'] ?? '';
    final date = transactionData!['date'];
    final attachmentUrl = transactionData!['attachment_url'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category and icon section
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, color: category.color, size: 36),
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
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isIncome
                              ? Colors.green.withOpacity(0.2)
                              : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isIncome ? "Income" : "Expense",
                      style: TextStyle(
                        color: isIncome ? Colors.green[400] : Colors.red[400],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 36),

        // Amount
        Text("Amount", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          "${isIncome ? '+' : '-'} ${_formatCurrency(amount)}",
          style: TextStyle(
            color: isIncome ? Colors.green[400] : Colors.red[400],
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 24),

        // Description
        Text(
          "Description",
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          description.isEmpty ? "No description" : description,
          style: TextStyle(
            color: description.isEmpty ? Colors.grey[700] : Colors.white,
            fontSize: 18,
          ),
        ),

        const SizedBox(height: 24),

        // Date
        Text("Date", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        const SizedBox(height: 8),
        Text(
          DateFormat('MMMM d, yyyy').format(DateTime.parse(date)),
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),

        if (attachmentUrl != null && attachmentUrl.toString().isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            "Attachment",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              // TODO: Implement attachment viewer
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Opening attachment: $attachmentUrl")),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purpleAccent.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attachment,
                    color: Colors.purpleAccent[100],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "View Receipt",
                      style: TextStyle(
                        color: Colors.purpleAccent[100],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.open_in_new,
                    color: Colors.purpleAccent[100],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Transaction ID
        Text(
          "Transaction ID",
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          transactionData!['id'].toString(),
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Transaction Type
        Text(
          "Transaction Type",
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTypeChip('income', 'Income'),
            const SizedBox(width: 12),
            _buildTypeChip('expense', 'Expense'),
            const SizedBox(width: 12),
            _buildTypeChip('transfer', 'Transfer'),
          ],
        ),

        const SizedBox(height: 24),

        // Amount
        Text("Amount", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.attach_money, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purpleAccent[100]!),
            ),
            hintText: 'Enter amount',
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
        ),

        const SizedBox(height: 24),

        // Category
        Text(
          "Category",
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showCategoryPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Row(
              children: [
                if (_selectedCategory != null) ...[
                  _getCategoryIcon(),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    _selectedCategory != null
                        ? TransactionCategory.fromName(_selectedCategory!).label
                        : "Select Category",
                    style: TextStyle(
                      color:
                          _selectedCategory != null
                              ? Colors.white
                              : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Description
        Text(
          "Description",
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.purpleAccent[100]!),
            ),
            hintText: 'Add description (optional)',
            hintStyle: TextStyle(color: Colors.grey[600]),
          ),
        ),

        const SizedBox(height: 24),

        // Date
        Text("Date", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showDatePicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[800]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? DateFormat('MMMM d, yyyy').format(_selectedDate!)
                        : "Select Date",
                    style: TextStyle(
                      color:
                          _selectedDate != null
                              ? Colors.white
                              : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Colors.purpleAccent.withOpacity(0.3)
                  : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border:
              isSelected
                  ? Border.all(color: Colors.purpleAccent, width: 1)
                  : Border.all(color: Colors.grey[800]!, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.purpleAccent : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _getCategoryIcon() {
    if (_selectedCategory == null) return const SizedBox();

    final category = TransactionCategory.fromName(_selectedCategory!);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(category.icon, color: category.color, size: 18),
    );
  }

  void _showCategoryPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            "Select Category",
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                // Income categories
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "INCOME",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...TransactionCategory.incomeCategories.map((category) {
                  return _buildCategoryTile(category);
                }),

                const SizedBox(height: 16),

                // Expense categories
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "EXPENSE",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...TransactionCategory.expenseCategories.map((category) {
                  return _buildCategoryTile(category);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTile(TransactionCategory category) {
    final isSelected = _selectedCategory == category.name;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: category.color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(category.icon, color: category.color),
      ),
      title: Text(
        category.label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          isSelected
              ? Icon(Icons.check_circle, color: Colors.purpleAccent[100])
              : null,
      onTap: () {
        setState(() {
          _selectedCategory = category.name;

          // Auto-set transaction type based on category
          if (TransactionCategory.incomeCategories.contains(category)) {
            _selectedType = 'income';
          } else if (TransactionCategory.expenseCategories.contains(category)) {
            _selectedType = 'expense';
          }
        });
        Navigator.pop(context);
      },
    );
  }

  void _showDatePicker() async {
    final initialDate = _selectedDate ?? DateTime.now();
    final firstDate = DateTime(initialDate.year - 1);
    final lastDate = DateTime(initialDate.year + 1);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.purpleAccent[100]!,
              onPrimary: Colors.white,
              surface: Colors.grey[850]!,
              onSurface: Colors.white,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.grey[900]),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
}
