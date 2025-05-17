import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Sesuaikan path sesuai struktur projekmu
import '../../utils/transaction_category.dart';
import '../../utils/formatters.dart';
import '../../screens/main_container.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? selectedCategory;
  bool isRepeat = false;
  XFile? _attachment;
  final ImagePicker _picker = ImagePicker();

  final descriptionController = TextEditingController();
  final amountController = TextEditingController();

  final List<TransactionCategory> categories =
      TransactionCategory.incomeCategories;

  final amountPreview = ValueNotifier<String>('0');

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _attachment = image;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _formatCurrency() {
    String digitsOnly = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      amountController.value = const TextEditingValue(text: '');
      return;
    }

    final number = int.tryParse(digitsOnly);
    if (number == null) return;

    final formatted = AppFormatters.formatToIdrCurrency(number.toDouble());

    amountController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    // Update preview
    amountPreview.value = formatted.replaceAll('Rp', '').trim();
  }

  Future<void> _submitForm(SupabaseClient supabase) async {
    if (_formKey.currentState!.validate()) {
      final userId = supabase.auth.currentUser!.id;

      String? attachmentUrl;

      if (_attachment != null) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = _attachment!.path;

        // Upload attachment to Supabase
        final _ = await supabase.storage
            .from('transaction-attachments')
            .upload('income-attachments/$userId/$fileName', File(filePath));

        attachmentUrl = supabase.storage
            .from('transaction-attachments')
            .getPublicUrl('income-attachments/$userId/$fileName');
      }

      final amount =
          double.tryParse(
            amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0;

      // Insert transaction data into the database
      final response = await supabase.from('transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': 'income',
        'category': selectedCategory ?? 'other_income',
        'description': descriptionController.text,
        'date': DateTime.now().toIso8601String(),
        'attachment_url': attachmentUrl,
      });

      debugPrint("Insert response: $response");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Income added successfully')),
        );

        // Navigate to the dashboard screen using direct navigation
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainContainer()),
          (route) => false,
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    amountController.addListener(_formatCurrency);
  }

  @override
  void dispose() {
    amountController.removeListener(_formatCurrency);
    amountController.dispose();
    descriptionController.dispose();
    amountPreview.dispose(); // Dispose notifikasi
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: const Color(0xff00A86B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Add Income",
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
          // Header dengan preview jumlah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            decoration: const BoxDecoration(color: Color(0xff00A86B)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How much?',
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
              ],
            ),
          ),

          // Form Section
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              decoration: const BoxDecoration(
                color: Color(0xff151515),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Amount'),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Category'),
                        value: selectedCategory,
                        dropdownColor: Colors.grey[900],
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value ?? 'others';
                          });
                        },
                        items:
                            categories.map((category) {
                              return DropdownMenuItem(
                                value: category.name,
                                child: Row(
                                  children: [
                                    Icon(
                                      category.icon,
                                      size: 16,
                                      color: category.color,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      category.label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: _inputDecoration('Description'),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickImageFromCamera,
                        child:
                            _attachment == null
                                ? Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade700,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.attach_file,
                                          color: Colors.white70,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Add attachment',
                                          style: TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                : ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    File(_attachment!.path),
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 16),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Column(
                      //       crossAxisAlignment: CrossAxisAlignment.start,
                      //       children: [
                      //         const Text(
                      //           'Repeat',
                      //           style: TextStyle(fontSize: 16, color: Colors.white),
                      //         ),
                      //         Text(
                      //           'Repeat transaction',
                      //           style: TextStyle(color: Colors.white60),
                      //         ),
                      //       ],
                      //     ),
                      //     Switch(
                      //       value: isRepeat,
                      //       onChanged: (value) => setState(() => isRepeat = value),
                      //       activeColor: Colors.white,
                      //       activeTrackColor: Color(0xFF7F3DFF),
                      //       inactiveThumbColor: Color(0xffFCFCFC),
                      //       inactiveTrackColor: Color(0xff292B2D),
                      //     ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tombol Simpan
          Container(
            padding: const EdgeInsets.all(16),
            color: Color(0xff151515),
            child: ElevatedButton(
              onPressed: () => _submitForm(supabase),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF7F3DFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Center(
                child: Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
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
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
