import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final Color primaryTeal = const Color(0xFF2EC4B6);
  
  final TextEditingController _budgetController = TextEditingController(text: '15000');
  final TextEditingController _idealDailyController = TextEditingController(text: '500');

  // 'Loan' is now a built-in category
  List<String> _categories = ['Food', 'Transport', 'Laundry', 'Supplies', 'Bills', 'Loan', 'Other'];
  List<Map<String, dynamic>> _quickAdds = [
    {'label': '🍳 Breakfast', 'amount': '240', 'category': 'Food', 'colorValue': Colors.orange.value},
    {'label': '☕ Tea & Snack', 'amount': '80', 'category': 'Food', 'colorValue': Colors.brown.value},
    {'label': '🛺 Rickshaw', 'amount': '100', 'category': 'Transport', 'colorValue': Colors.blue.value},
    {'label': '👕 Laundry', 'amount': '150', 'category': 'Laundry', 'colorValue': Colors.indigo.value},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final savedCats = prefs.getStringList('categories');
      if (savedCats != null) {
        _categories = savedCats;
        if (!_categories.contains('Loan')) _categories.add('Loan'); // Safety fallback
      }

      final savedQuick = prefs.getString('quickAdds');
      if (savedQuick != null) _quickAdds = List<Map<String, dynamic>>.from(json.decode(savedQuick));
      final savedBudget = prefs.getString('monthlyBudget');
      if (savedBudget != null) _budgetController.text = savedBudget;
      final savedIdeal = prefs.getString('idealDaily');
      if (savedIdeal != null) _idealDailyController.text = savedIdeal;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categories', _categories);
    await prefs.setString('quickAdds', json.encode(_quickAdds));
    await prefs.setString('monthlyBudget', _budgetController.text);
    await prefs.setString('idealDaily', _idealDailyController.text);
  }

  void _showManageCategoriesDialog() {
    final TextEditingController catController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Manage Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: TextField(controller: catController, decoration: const InputDecoration(hintText: 'New Category'))),
                      IconButton(
                        icon: Icon(Icons.add_circle, color: primaryTeal),
                        onPressed: () {
                          if (catController.text.isNotEmpty && !_categories.contains(catController.text)) {
                            setState(() => _categories.add(catController.text));
                            _saveData();
                            setDialogState(() {});
                            catController.clear();
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final catName = _categories[index];
                        final isBuiltIn = catName == 'Loan'; // Protect the Loan category

                        return ListTile(
                          title: Text(catName, style: TextStyle(fontWeight: isBuiltIn ? FontWeight.bold : FontWeight.normal)),
                          trailing: isBuiltIn
                              ? const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.lock_outline, color: Colors.grey, size: 20))
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    if (_categories.length > 1) {
                                      setState(() => _categories.removeAt(index));
                                      _saveData();
                                      setDialogState(() {});
                                    }
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
          );
        }
      ),
    );
  }

  void _showQuickAddEditorDialog({int? index}) {
    final Map<String, dynamic>? item = index != null ? _quickAdds[index] : null;

    final TextEditingController labelCtrl = TextEditingController(text: item?['label'] ?? '');
    final TextEditingController amountCtrl = TextEditingController(text: item?['amount'] ?? '');
    String newCat = (item != null && _categories.contains(item['category'])) ? item['category'] : _categories.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( 
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(index != null ? 'Edit Shortcut' : 'New Shortcut'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label')),
                const SizedBox(height: 12),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (Rs)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: newCat,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setDialogState(() => newCat = val!),
                ),
              ],
            ),
            actionsAlignment: index != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
            actions: [
              if (index != null)
                TextButton(
                  onPressed: () {
                    setState(() => _quickAdds.removeAt(index));
                    _saveData();
                    Navigator.pop(context);
                  }, 
                  child: const Text('Delete', style: TextStyle(color: Colors.red))
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white),
                    onPressed: () {
                      if (labelCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                        setState(() {
                          final newData = {
                            'label': labelCtrl.text,
                            'amount': amountCtrl.text,
                            'category': newCat,
                            'colorValue': item != null ? item['colorValue'] : Colors.teal.value, 
                          };
                          
                          if (index != null) {
                            _quickAdds[index] = newData;
                          } else {
                            _quickAdds.add(newData);
                          }
                        });
                        _saveData();
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              )
            ],
          );
        }
      ),
    );
  }

  void _showManageQuickAddsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Manage Shortcuts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _quickAdds.length,
                      itemBuilder: (context, index) {
                        final item = _quickAdds[index];
                        final color = Color(item['colorValue']);
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Icon(Icons.bolt, color: color, size: 16)),
                          title: Text(item['label']),
                          subtitle: Text('Rs ${item['amount']} • ${item['category']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () {
                              Navigator.pop(context);
                              _showQuickAddEditorDialog(index: index);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      _showQuickAddEditorDialog();
                    },
                    leading: Icon(Icons.add_circle, color: primaryTeal),
                    title: Text('Create New Shortcut', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Setup', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)), centerTitle: true, elevation: 0, backgroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Monthly Configurations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _budgetController,
              decoration: InputDecoration(
                labelText: 'Total Monthly Budget (Rs)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryTeal, width: 2)),
                prefixIcon: Icon(Icons.account_balance_wallet, color: primaryTeal),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _idealDailyController,
              decoration: InputDecoration(
                labelText: 'Ideal Daily Spend (Rs)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryTeal, width: 2)),
                prefixIcon: Icon(Icons.track_changes, color: primaryTeal),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.black12),
            const SizedBox(height: 24),

            const Text('App Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            ListTile(
              onTap: _showManageCategoriesDialog,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey.shade50,
              leading: Icon(Icons.category, color: primaryTeal),
              title: const Text('Manage Categories', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Add or remove expense categories'),
              trailing: const Icon(Icons.chevron_right),
            ),
            const SizedBox(height: 12),
            ListTile(
              onTap: _showManageQuickAddsDialog,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.grey.shade50,
              leading: Icon(Icons.bolt, color: Colors.orange.shade400),
              title: const Text('Manage Quick Adds', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Edit or add shortcut buttons'),
              trailing: const Icon(Icons.chevron_right),
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  _saveData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text('Settings Saved successfully!'), backgroundColor: primaryTeal),
                  );
                },
                child: const Text('Save Global Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}