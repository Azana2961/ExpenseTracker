import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseScreen extends StatefulWidget {
  final DateTime? selectedDate;
  
  const ExpenseScreen({super.key, this.selectedDate});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final Color primaryTeal = const Color(0xFF2EC4B6);
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for Manual Entry
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  
  // Dynamic Categories State
  String _selectedCategory = 'Food';
  final List<String> _categories = ['Food', 'Transport', 'Laundry', 'Supplies', 'Bills', 'Other'];

  // Dynamic Quick Add State
  final List<Map<String, dynamic>> _quickAdds = [
    {'label': '🍳 Breakfast', 'amount': '240', 'category': 'Food', 'color': Colors.orange},
    {'label': '☕ Tea & Snack', 'amount': '80', 'category': 'Food', 'color': Colors.brown},
    {'label': '🛺 Rickshaw', 'amount': '100', 'category': 'Transport', 'color': Colors.blue},
    {'label': '👕 Laundry', 'amount': '150', 'category': 'Laundry', 'color': Colors.indigo},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- SAVE EXPENSE LOGIC ---
  void _saveExpense(String category, String amount, String description) {
    if (amount.isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully logged Rs $amount for $category!'),
        backgroundColor: primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    _amountController.clear();
    _descController.clear();
    FocusScope.of(context).unfocus();
  }

  // --- DIALOG: ADD NEW CATEGORY ---
  void _showAddCategoryDialog() {
    final TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(hintText: 'e.g., Gym, Gifts, Printouts'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedCategory = 'Food'); // Revert if cancelled
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white),
            onPressed: () {
              if (catController.text.isNotEmpty) {
                setState(() {
                  _categories.add(catController.text);
                  _selectedCategory = catController.text;
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // --- DIALOG: ADD NEW QUICK ADD SHORTCUT ---
  void _showAddQuickAddDialog() {
    final TextEditingController labelCtrl = TextEditingController();
    final TextEditingController amountCtrl = TextEditingController();
    String newCat = _categories.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('New Shortcut'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(hintText: 'Label (e.g., 🍔 Lunch)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Amount (Rs)', prefixText: 'Rs '),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: newCat,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((String c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => newCat = val!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white),
                onPressed: () {
                  if (labelCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                    setState(() {
                      _quickAdds.add({
                        'label': labelCtrl.text,
                        'amount': amountCtrl.text,
                        'category': newCat,
                        'color': Colors.teal, 
                      });
                    });
                  }
                  Navigator.pop(context);
                },
                child: const Text('Create'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime targetDate = widget.selectedDate ?? DateTime.now();
    final String formattedDate = DateFormat('EEEE, MMMM d').format(targetDate);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            const Text('Log Expense', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: QUICK ADD TEMPLATES ---
            const Text('Quick Add', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6, // Adjusted to fix RenderFlex overflow
              ),
              itemCount: _quickAdds.length + 1, 
              itemBuilder: (context, index) {
                if (index == _quickAdds.length) {
                  return _buildCreateNewQuickAddBtn();
                }
                final item = _quickAdds[index];
                return _buildQuickAddBtn(item['label'], item['amount'], item['category'], item['color']);
              },
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.black12),
            const SizedBox(height: 24),

            // --- SECTION 2: MANUAL ENTRY FORM ---
            const Text('Manual Entry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Amount Field
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text('Rs', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryTeal, width: 2),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? 'Please enter an amount' : null,
                  ),
                  const SizedBox(height: 16),

                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined, color: primaryTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryTeal, width: 2),
                      ),
                    ),
                    items: [..._categories, '+ Add New Category'].map((String category) {
                      return DropdownMenuItem(
                        value: category, 
                        child: Text(category, style: TextStyle(
                          color: category == '+ Add New Category' ? primaryTeal : Colors.black87,
                          fontWeight: category == '+ Add New Category' ? FontWeight.bold : FontWeight.normal,
                        ))
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue == '+ Add New Category') {
                        _showAddCategoryDialog();
                      } else {
                        setState(() => _selectedCategory = newValue!);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: Icon(Icons.notes, color: primaryTeal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryTeal, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _saveExpense(_selectedCategory, _amountController.text, _descController.text);
                        }
                      },
                      child: const Text('Save Expense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  // Regular Quick Add Button
  Widget _buildQuickAddBtn(String label, String amount, String category, Color color) {
    return InkWell(
      onTap: () => _saveExpense(category, amount, label),
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
              style: TextStyle(fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.8), fontSize: 13)
            ),
            const SizedBox(height: 4),
            Text(
              'Rs $amount', 
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w900, color: color)
            ),
          ],
        ),
      ),
    );
  }

  // Special Button to Add a New Shortcut
  Widget _buildCreateNewQuickAddBtn() {
    return InkWell(
      onTap: _showAddQuickAddDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.grey.shade600),
            const SizedBox(height: 4),
            Text(
              'New', 
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)
            ),
          ],
        ),
      ),
    );
  }
}