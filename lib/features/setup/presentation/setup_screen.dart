import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../../../core/services/notification_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final Color primaryTeal = const Color(0xFF2EC4B6);
  
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _idealDailyController = TextEditingController();

  List<String> _categories = [];
  List<Map<String, dynamic>> _quickAdds = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SettingsProvider>(context, listen: false);
      setState(() {
        _budgetController.text = provider.monthlyBudget.toStringAsFixed(0);
        _idealDailyController.text = provider.idealDailySpend.toStringAsFixed(0);
        _categories = List.from(provider.categories);
        _quickAdds = List.from(provider.quickAdds);
      });
    });
  }

  void _saveData() {
    Provider.of<SettingsProvider>(context, listen: false).saveSettings(
      budget: double.tryParse(_budgetController.text) ?? 15000.0,
      ideal: double.tryParse(_idealDailyController.text) ?? 500.0,
      cats: _categories,
      quicks: _quickAdds,
    );
  }

  void _showCategoryEditorDialog() {
    final TextEditingController catController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New Category'),
        content: TextField(
          controller: catController,
          decoration: const InputDecoration(labelText: 'Category Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white),
            onPressed: () {
              final text = catController.text.trim();
              if (text.isNotEmpty && !_categories.contains(text)) {
                setState(() => _categories.add(text));
                _saveData();
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showManageCategoriesDialog() {
    // Use a local list copy that the dialog owns, synced back on every change
    List<String> dialogCats = List.from(_categories);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text('Manage Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: dialogCats.length,
                      itemBuilder: (context, index) {
                        final catName = dialogCats[index];
                        final isBuiltIn = catName == 'Loan' || catName == 'Borrow';

                        return ListTile(
                          title: Text(catName, style: TextStyle(fontWeight: isBuiltIn ? FontWeight.bold : FontWeight.normal)),
                          trailing: isBuiltIn
                              ? const Padding(padding: EdgeInsets.all(8.0), child: Icon(Icons.lock_outline, color: Colors.grey, size: 20))
                              : IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {
                                    if (dialogCats.length > 1) {
                                      setDialogState(() => dialogCats.removeAt(index));
                                      setState(() => _categories = List.from(dialogCats));
                                      _saveData();
                                    }
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    onTap: () {
                      Navigator.pop(dialogContext);
                      _showCategoryEditorDialog();
                    },
                    leading: Icon(Icons.add_circle, color: primaryTeal),
                    title: Text('Create New Category', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal)),
                  ),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
          );
        },
      ),
    );
  }

  void _showQuickAddEditorDialog({int? index}) {
    final Map<String, dynamic>? item = index != null ? _quickAdds[index] : null;

    final TextEditingController labelCtrl = TextEditingController(text: item?['label'] ?? '');
    final TextEditingController amountCtrl = TextEditingController(text: item?['amount']?.toString() ?? '');
    // Fallback to first available category safely
    final List<String> availableCats = _categories.isNotEmpty ? _categories : ['Other'];
    String newCat = (item != null && availableCats.contains(item['category']))
        ? item['category']
        : availableCats.first;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(index != null ? 'Edit Shortcut' : 'New Shortcut'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label')),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (Rs)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: newCat,
                  items: availableCats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white),
                    onPressed: () {
                      final label = labelCtrl.text.trim();
                      final amount = amountCtrl.text.trim();
                      if (label.isNotEmpty && amount.isNotEmpty) {
                        setState(() {
                          final newData = {
                            'label': label,
                            'amount': amount,
                            'category': newCat,
                            'colorValue': item != null ? item['colorValue'] : Colors.teal.toARGB32(),
                          };

                          if (index != null) {
                            _quickAdds[index] = newData;
                          } else {
                            _quickAdds.add(newData);
                          }
                        });
                        _saveData();
                        Navigator.pop(dialogContext);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  void _showManageQuickAddsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
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
                      itemBuilder: (ctx, index) {
                        final item = _quickAdds[index];
                        final color = Color(item['colorValue'] as int);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color.withValues(alpha: 0.2),
                            child: Icon(Icons.bolt, color: color, size: 16),
                          ),
                          title: Text(item['label']),
                          subtitle: Text('Rs ${item['amount']} • ${item['category']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.grey),
                            onPressed: () {
                              Navigator.pop(dialogContext);
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
                      Navigator.pop(dialogContext);
                      _showQuickAddEditorDialog();
                    },
                    leading: Icon(Icons.add_circle, color: primaryTeal),
                    title: Text('Create New Shortcut', style: TextStyle(fontWeight: FontWeight.bold, color: primaryTeal)),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
            ],
          );
        },
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
            const SizedBox(height: 12),
            ListTile(
              onTap: () {
                NotificationService().showTestNotification();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent!')),
                );
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Colors.blue.shade50,
              leading: const Icon(Icons.notifications_active, color: Colors.blue),
              title: const Text('Test Notification (Debug)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
              subtitle: const Text('Send a sample notification instantly'),
              trailing: const Icon(Icons.chevron_right, color: Colors.blue),
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