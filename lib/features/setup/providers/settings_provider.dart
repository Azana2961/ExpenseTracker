import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SettingsProvider with ChangeNotifier {
  double _monthlyBudget = 15000.0;
  List<String> _categories = ['Food', 'Transport', 'Laundry', 'Supplies', 'Bills', 'Loan', 'Borrow', 'Other'];
  List<Map<String, dynamic>> _quickAdds = [
    {'label': '🍳 Breakfast', 'amount': '240', 'category': 'Food', 'colorValue': Colors.orange.value},
    {'label': '☕ Tea & Snack', 'amount': '80', 'category': 'Food', 'colorValue': Colors.brown.value},
    {'label': '🛺 Rickshaw', 'amount': '100', 'category': 'Transport', 'colorValue': Colors.blue.value},
    {'label': '👕 Laundry', 'amount': '150', 'category': 'Laundry', 'colorValue': Colors.indigo.value},
  ];

  double get monthlyBudget => _monthlyBudget;
  List<String> get categories => _categories;
  List<Map<String, dynamic>> get quickAdds => _quickAdds;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _monthlyBudget = double.tryParse(prefs.getString('monthlyBudget') ?? '15000') ?? 15000.0;

    final savedCats = prefs.getStringList('categories');
    if (savedCats != null) {
      _categories = savedCats;
      if (!_categories.contains('Loan')) _categories.add('Loan');
      if (!_categories.contains('Borrow')) _categories.add('Borrow');
    }

    final savedQuick = prefs.getString('quickAdds');
    if (savedQuick != null) {
      _quickAdds = List<Map<String, dynamic>>.from(json.decode(savedQuick));
    }
    notifyListeners();
  }

  Future<void> saveSettings({
    required double budget,
    required List<String> cats,
    required List<Map<String, dynamic>> quicks,
  }) async {
    _monthlyBudget = budget;
    _categories = cats;
    _quickAdds = quicks;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('monthlyBudget', budget.toString());
    await prefs.setStringList('categories', cats);
    await prefs.setString('quickAdds', json.encode(quicks));

    notifyListeners(); 
  }
}