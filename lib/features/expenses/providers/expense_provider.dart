import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../models/repayment_model.dart';
import '../../../core/database/database_helper.dart';

class ExpenseProvider with ChangeNotifier {
  // ── In-memory caches ──────────────────────────────────────────────────────
  List<ExpenseModel>   _expenses   = [];
  List<RepaymentModel> _repayments = [];

  List<ExpenseModel>   get expenses   => _expenses;
  List<RepaymentModel> get repayments => _repayments;

  List<String> get uniqueBeneficiaries {
    final set = <String>{};
    for (final e in _expenses) {
      final b = e.beneficiary;
      if (b != null && b.isNotEmpty) {
        set.add(b);
      }
    }
    return set.toList()..sort();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// All repayments that belong to a specific parent expense.
  List<RepaymentModel> repaymentsFor(String parentId) =>
      _repayments.where((r) => r.parentId == parentId).toList();

  /// Total amount repaid so far for a parent (derived from repayment records).
  double totalRepaidFor(String parentId) =>
      repaymentsFor(parentId).fold(0.0, (sum, r) => sum + r.amount);

  // ═══════════════════════════════════════════════════════════════════════════
  //  LOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch both expenses AND repayments from disk on app start.
  Future<void> loadExpenses() async {
    try {
      _expenses   = await DatabaseHelper.instance.getAllExpenses();
      _repayments = await DatabaseHelper.instance.getAllRepayments();
      notifyListeners();
    } catch (e) {
      debugPrint('DB Error Loading: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EXPENSE CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      await DatabaseHelper.instance.insertExpense(expense);
      _expenses = [expense, ..._expenses];
      notifyListeners();
    } catch (e) {
      debugPrint('DB Error Adding: $e');
      rethrow;
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await DatabaseHelper.instance.updateExpense(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        _expenses = [..._expenses];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('DB Error Updating: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await DatabaseHelper.instance.deleteExpense(id); // also deletes repayments
      _expenses.removeWhere((e) => e.id == id);
      _repayments.removeWhere((r) => r.parentId == id);
      _expenses   = [..._expenses];
      _repayments = [..._repayments];
      notifyListeners();
    } catch (e) {
      debugPrint('DB Error Deleting: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  REPAYMENT CRUD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Record a new payment event on [repayment.date].
  /// Also updates the parent expense's amountPaid + isCleared fields.
  Future<void> addRepayment(RepaymentModel repayment) async {
    try {
      // 1. Persist repayment record
      await DatabaseHelper.instance.insertRepayment(repayment);
      _repayments = [repayment, ..._repayments];

      // 2. Re-calculate amountPaid on the parent expense from ALL repayments
      final parentIdx = _expenses.indexWhere((e) => e.id == repayment.parentId);
      if (parentIdx != -1) {
        final parent = _expenses[parentIdx];
        final newAmountPaid = totalRepaidFor(repayment.parentId); // already includes new entry
        final nowCleared   = newAmountPaid >= parent.amount;

        final updated = parent.copyWith(
          amountPaid: newAmountPaid,
          isCleared:  nowCleared,
        );
        await DatabaseHelper.instance.updateExpense(updated);
        _expenses[parentIdx] = updated;
        _expenses = [..._expenses];
      }

      notifyListeners();
    } catch (e) {
      debugPrint('DB Error Adding Repayment: $e');
      rethrow;
    }
  }

  /// Delete a single repayment and recalculate the parent's amountPaid.
  Future<void> deleteRepayment(String repaymentId) async {
    try {
      final repayment = _repayments.firstWhere((r) => r.id == repaymentId);
      await DatabaseHelper.instance.deleteRepayment(repaymentId);
      _repayments.removeWhere((r) => r.id == repaymentId);
      _repayments = [..._repayments];

      // Recalculate parent
      final parentIdx = _expenses.indexWhere((e) => e.id == repayment.parentId);
      if (parentIdx != -1) {
        final parent       = _expenses[parentIdx];
        final newAmountPaid = totalRepaidFor(repayment.parentId);
        final nowCleared   = newAmountPaid >= parent.amount;
        final updated = parent.copyWith(
          amountPaid: newAmountPaid,
          isCleared:  nowCleared,
        );
        await DatabaseHelper.instance.updateExpense(updated);
        _expenses[parentIdx] = updated;
        _expenses = [..._expenses];
      }

      notifyListeners();
    } catch (e) {
      debugPrint('DB Error Deleting Repayment: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BENEFICIARY SETTLEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Settles all active loans and borrows for a specific beneficiary
  /// by creating a repayment that exactly covers the remaining balance.
  Future<void> settleWithBeneficiary(String beneficiary) async {
    try {
      final activeTx = _expenses.where((e) =>
          e.beneficiary == beneficiary &&
          (e.category == 'Loan' || e.category == 'Borrow') &&
          !e.isCleared).toList();

      for (final tx in activeTx) {
        final remaining = tx.remainingAmount;
        if (remaining > 0) {
          final repayment = RepaymentModel.create(
            parentId: tx.id,
            category: tx.category,
            amount: remaining,
            date: DateTime.now(),
          );
          await addRepayment(repayment); // This internally updates amountPaid and isCleared
        }
      }
    } catch (e) {
      debugPrint('DB Error Settling with Beneficiary: $e');
      rethrow;
    }
  }

  /// mathematically nets out Borrows against Loans for the same person.
  /// E.g. If you owe them 200 (Borrow) and they owe you 300 (Loan),
  /// it fully repays the Borrow, and applies 200 towards the Loan.
  Future<void> netSettleBeneficiary(String beneficiary) async {
    try {
      final activeLoans = _expenses.where((e) =>
          e.beneficiary == beneficiary && e.category == 'Loan' && !e.isCleared).toList();
      final activeBorrows = _expenses.where((e) =>
          e.beneficiary == beneficiary && e.category == 'Borrow' && !e.isCleared).toList();

      double sumLoans = activeLoans.fold(0.0, (sum, tx) => sum + tx.remainingAmount);
      double sumBorrows = activeBorrows.fold(0.0, (sum, tx) => sum + tx.remainingAmount);

      double overlap = sumLoans < sumBorrows ? sumLoans : sumBorrows;
      if (overlap <= 0) return; // Nothing to net out

      // Apply overlap to loans
      double remainingToApplyToLoans = overlap;
      for (final tx in activeLoans) {
        if (remainingToApplyToLoans <= 0) break;
        final amountToApply = tx.remainingAmount < remainingToApplyToLoans ? tx.remainingAmount : remainingToApplyToLoans;
        final repayment = RepaymentModel.create(
          parentId: tx.id,
          category: 'Loan',
          amount: amountToApply,
          date: DateTime.now(),
        );
        await addRepayment(repayment);
        remainingToApplyToLoans -= amountToApply;
      }

      // Apply overlap to borrows
      double remainingToApplyToBorrows = overlap;
      for (final tx in activeBorrows) {
        if (remainingToApplyToBorrows <= 0) break;
        final amountToApply = tx.remainingAmount < remainingToApplyToBorrows ? tx.remainingAmount : remainingToApplyToBorrows;
        final repayment = RepaymentModel.create(
          parentId: tx.id,
          category: 'Borrow',
          amount: amountToApply,
          date: DateTime.now(),
        );
        await addRepayment(repayment);
        remainingToApplyToBorrows -= amountToApply;
      }
    } catch (e) {
      debugPrint('DB Error Net Settling: $e');
      rethrow;
    }
  }
}