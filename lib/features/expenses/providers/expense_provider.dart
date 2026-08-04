import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../../../core/database/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  // This is the active memory cache. It holds all transactions while the app is open.
  List<ExpenseModel> _expenses = [];

  // A getter to allow the UI to read the list
  List<ExpenseModel> get expenses => _expenses;

  // 1. INITIAL LOAD: Fetch everything from the hard drive when the app starts
  Future<void> loadExpenses() async {
    try {
      _expenses = await DatabaseHelper.instance.getAllExpenses();
      notifyListeners(); 
    } catch (e) {
      debugPrint("DB Error Loading: $e");
    }
  }

  // 2. ADD EXPENSE: Save to hard drive AND add to active memory
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await DatabaseHelper.instance.insertExpense(expense);
      _expenses = [expense, ..._expenses]; // Force memory refresh
      notifyListeners(); 
    } catch (e) {
      debugPrint("DB Error Adding: $e");
      rethrow; // Pass error to the UI
    }
  }

  // 3. UPDATE EXPENSE: Update the hard drive AND the memory
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await DatabaseHelper.instance.updateExpense(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        _expenses = [..._expenses]; // Force memory refresh
        notifyListeners();
      }
    } catch (e) {
      debugPrint("DB Error Updating: $e");
      rethrow;
    }
  }

  // 4. DELETE EXPENSE: Remove from hard drive AND memory
  Future<void> deleteExpense(String id) async {
    try {
      await DatabaseHelper.instance.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      _expenses = [..._expenses]; // Force memory refresh
      notifyListeners();
    } catch (e) {
      debugPrint("DB Error Deleting: $e");
      rethrow;
    }
  }
}