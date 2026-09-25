import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../../setup/providers/settings_provider.dart';
import '../models/expense_model.dart';

class ExpenseScreen extends StatefulWidget {
  final DateTime? initialDate;

  const ExpenseScreen({super.key, this.initialDate});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final Color primaryTeal = const Color(0xFF2EC4B6);
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _beneficiaryController = TextEditingController();

  String _selectedCategory = 'Food';
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    _beneficiaryController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense(
    String category,
    String amountStr,
    String description,
    String beneficiary,
  ) async {
    if (amountStr.isEmpty) return;

    final double? amount = double.tryParse(amountStr);
    if (amount == null) return; // Prevent saving if amount is invalid

    final targetDate = _selectedDate;

    // RULE FOR DEBTS: 
    // - Borrow means you owe someone (unpaid debt). It starts as false (isCleared = false) to show the RED ring.
    // - Loan means you gave someone money. It starts as false (isCleared = false) to show the GREEN ring.
    bool initialClearedStatus = true;
    if (category == 'Borrow' || category == 'Loan') {
      initialClearedStatus = false;
    }

    // 1. Create the Database Record
    final newExpense = ExpenseModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID based on exact millisecond
      date: targetDate,
      label: description.isNotEmpty ? description : category, // Fallback to category if no desc
      amount: amount,
      category: category,
      isCleared: initialClearedStatus, // Applies the Borrow/Loan logic
      beneficiary: beneficiary.trim().isEmpty ? null : beneficiary.trim(),
    );

    try {
      // 2. AWAIT the Provider to save to SQLite and update memory!
      await Provider.of<ExpenseProvider>(
        context,
        listen: false,
      ).addExpense(newExpense);

      if (!mounted) return;

      // Unfocus keyboard and clear inputs FIRST
      _amountController.clear();
      _descController.clear();
      _beneficiaryController.clear();
      FocusScope.of(context).unfocus();

      // Clear any existing popups so they don't get stuck in a queue
      ScaffoldMessenger.of(context).clearSnackBars();

      final bool isSpecial = category == 'Borrow' || category == 'Loan';
      final Color snackColor = isSpecial ? (category == 'Loan' ? Colors.green.shade700 : Colors.red.shade700) : primaryTeal;

      // Show the new premium Top-Snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSpecial ? '$category Logged!' : 'Successfully logged Rs $amountStr for $category!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          backgroundColor: snackColor,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1200), // Extremely fast (1.2 seconds)
          dismissDirection: DismissDirection.up, // Allows you to swipe it away upwards
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 180, // Pushes it securely to the top
            left: 20,
            right: 20,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // Pill shape
          elevation: 6,
        ),
      );
    } catch (e) {
      // 3. Catch silent background crashes!
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Database Error! Please UNINSTALL the app from your device and reinstall to clear the cache.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read live categories and shortcuts from Provider
    final settings = context.watch<SettingsProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final List<String> categories = settings.categories;
    final List<Map<String, dynamic>> quickAdds = settings.quickAdds;
    final List<String> uniqueBeneficiaries = expenseProvider.uniqueBeneficiaries;

    // Safety check if current selected category was deleted from settings
    if (!categories.contains(_selectedCategory) && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    final String formattedDate = DateFormat('EEEE, MMMM d').format(_selectedDate);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Column(
          children: [
            const Text(
              'Log Expense',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              formattedDate,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (quickAdds.isNotEmpty) ...[
              const Text(
                'Quick Add',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: quickAdds.length,
                itemBuilder: (context, index) {
                  final item = quickAdds[index];
                  return _buildQuickAddBtn(
                    item['label'],
                    item['amount'].toString(),
                    item['category'],
                    Color(item['colorValue']),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.black12),
              const SizedBox(height: 24),
            ],

            const Text(
              'Manual Entry',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text(
                          'Rs',
                          style: TextStyle(
                            color: primaryTeal,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryTeal, width: 2),
                      ),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an amount' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(
                        Icons.category_outlined,
                        color: primaryTeal,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryTeal, width: 2),
                      ),
                    ),
                    items: categories.map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedCategory = newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  if (_selectedCategory == 'Loan' || _selectedCategory == 'Borrow') ...[
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return uniqueBeneficiaries;
                        }
                        return uniqueBeneficiaries.where((String option) {
                          return option
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (String selection) {
                        _beneficiaryController.text = selection;
                      },
                      fieldViewBuilder: (context, controller, focusNode,
                          onEditingComplete) {
                        // Keep our _beneficiaryController in sync with the internal controller
                        // if we want, or just use the internal one. Since Autocomplete creates
                        // its own controller if we don't pass one, we should map them.
                        // Wait, it's easier to just use the controller provided by fieldViewBuilder
                        // and assign it to our logic, but we need it in _saveExpense.
                        // So we listen to it, or just use it.
                        // Actually, we can just assign the controller's text in onEditingComplete,
                        // but it's safer to bind our _beneficiaryController as the text editing controller here.
                        // Actually Autocomplete in Flutter doesn't accept a controller parameter directly
                        // on the Autocomplete widget, it uses the one in fieldViewBuilder.
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          onChanged: (val) => _beneficiaryController.text = val,
                          decoration: InputDecoration(
                            labelText: 'Beneficiary / Person',
                            prefixIcon: Icon(Icons.person, color: primaryTeal),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryTeal, width: 2),
                            ),
                          ),
                          validator: (value) => value!.trim().isEmpty
                              ? 'Please enter a person name'
                              : null,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: Icon(Icons.notes, color: primaryTeal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryTeal, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _saveExpense(
                            _selectedCategory,
                            _amountController.text,
                            _descController.text,
                            _selectedCategory == 'Loan' || _selectedCategory == 'Borrow' ? _beneficiaryController.text : '',
                          );
                        }
                      },
                      child: const Text(
                        'Save Expense',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddBtn(
    String label,
    String amount,
    String category,
    Color color,
  ) {
    return InkWell(
      onTap: () => _saveExpense(category, amount, label, ''),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rs $amount',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }
}