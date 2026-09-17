import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../setup/providers/settings_provider.dart';
import '../../expenses/models/expense_model.dart';
import '../../expenses/models/repayment_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ─── Design Tokens ────────────────────────────────────────────────────────
  static const Color _primaryTeal = Color(0xFF2EC4B6);

  // ─── State ─────────────────────────────────────────────────────────────────
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _today();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dateLabel(DateTime date) {
    final today = _today();
    final yesterday = today.subtract(const Duration(days: 1));
    if (_isSameDay(date, today)) return 'Today';
    if (_isSameDay(date, yesterday)) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  // ─── Cash-flow helpers ─────────────────────────────────────────────────────

  /// Cash that physically LEFT your pocket on the origin date of [tx]:
  ///   Regular expense  → full amount
  ///   Loan (origin)    → full amount (cash went out immediately)
  ///   Borrow (origin)  → 0           (cash came IN on this day)
  ///
  /// Repayments are handled separately in the build() method.
  double _originCashFlow(ExpenseModel tx) {
    if (tx.category == 'Borrow') return 0.0; // received money
    return tx.amount;                        // Loan + all regular expenses
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':      return Icons.fastfood;
      case 'Transport': return Icons.directions_car;
      case 'Laundry':   return Icons.local_laundry_service;
      case 'Bills':     return Icons.receipt;
      case 'Loan':      return Icons.handshake_outlined;
      case 'Borrow':    return Icons.account_balance_wallet;
      case 'Supplies':  return Icons.shopping_cart;
      default:          return Icons.payments_outlined;
    }
  }

  // ─── Date Navigation ───────────────────────────────────────────────────────
  void _shiftDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  // ─── Dialogs / Bottom Sheets ───────────────────────────────────────────────
  void _showRecordPaymentSheet(
    BuildContext context,
    ExpenseModel tx,
    ExpenseProvider provider,
  ) {
    final payCtrl = TextEditingController();
    final isLoan = tx.category == 'Loan';
    final accentColor =
        isLoan ? Colors.green.shade700 : Colors.red.shade700;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title row
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          accentColor.withValues(alpha: 0.15),
                      child: Icon(_getCategoryIcon(tx.category),
                          color: accentColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Record Payment',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          Text(
                            tx.label,
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Summary card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: accentColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      _paymentRow('Original Amount',
                          'Rs ${tx.amount.toStringAsFixed(0)}',
                          Colors.black87),
                      const SizedBox(height: 8),
                      _paymentRow('Already Paid',
                          'Rs ${tx.amountPaid.toStringAsFixed(0)}',
                          Colors.grey.shade600),
                      const Divider(height: 20),
                      _paymentRow(
                        'Still Outstanding',
                        'Rs ${tx.remainingAmount.toStringAsFixed(0)}',
                        accentColor,
                        bold: true,
                      ),
                      if (tx.isPartiallyPaid) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: tx.amountPaid / tx.amount,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${((tx.amountPaid / tx.amount) * 100).toStringAsFixed(0)}% paid',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Amount input
                TextField(
                  controller: payCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'Payment Amount',
                    prefixText: 'Rs ',
                    prefixStyle: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: accentColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: accentColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          payCtrl.text =
                              tx.remainingAmount.toStringAsFixed(0);
                        },
                        child: Text(
                          'Pay Full',
                          style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final entered = double.tryParse(payCtrl.text);
                          if (entered == null || entered <= 0) return;
                          final capped =
                              entered.clamp(0.0, tx.remainingAmount);

                          // ✔️ Create a dated repayment record (TODAY = day cash moved)
                          final repayment = RepaymentModel.create(
                            parentId: tx.id,
                            category: tx.category,
                            amount: capped,
                            date: _today(), // always stamped to the actual day
                          );
                          provider.addRepayment(repayment);
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Confirm Payment',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _paymentRow(
    String label,
    String value,
    Color valueColor, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 15 : 13,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(
    BuildContext context,
    ExpenseModel tx,
    ExpenseProvider provider,
    SettingsProvider settings,
  ) {
    final labelCtrl = TextEditingController(text: tx.label);
    final amountCtrl =
        TextEditingController(text: tx.amount.toStringAsFixed(0));
    String selectedCat = tx.category;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Transaction',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: labelCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Label')),
              const SizedBox(height: 12),
              TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Amount (Rs)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue:
                    settings.categories.contains(selectedCat)
                        ? selectedCat
                        : settings.categories.first,
                items: settings.categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => selectedCat = v ?? selectedCat,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () {
                provider.deleteExpense(tx.id);
                Navigator.pop(ctx);
              },
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red)),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryTeal,
                      foregroundColor: Colors.white),
                  onPressed: () {
                    final newAmount =
                        double.tryParse(amountCtrl.text) ??
                            tx.amount;
                    if (labelCtrl.text.isNotEmpty && newAmount > 0) {
                      provider.updateExpense(tx.copyWith(
                        label: labelCtrl.text,
                        amount: newAmount,
                        category: selectedCat,
                      ));
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final provider     = context.watch<ExpenseProvider>();
    final allExpenses  = provider.expenses;
    final allRepayments = provider.repayments;  // ✔️ repayment records
    final settings     = context.watch<SettingsProvider>();

    final double monthlyBudget   = settings.monthlyBudget;
    final double idealDailySpend = settings.idealDailySpend;

    final DateTime today       = DateTime.now();
    final int daysInMonth      = DateUtils.getDaysInMonth(today.year, today.month);
    final int currentDay       = today.day;
    final int remainingDays    = daysInMonth - currentDay;

    // ── Monthly net budget impact ──────────────────────────────────────
    double currentSpent = 0.0;

    // a) Origin transactions this month
    for (final tx in allExpenses) {
      if (tx.date.month == today.month && tx.date.year == today.year) {
        currentSpent += _originCashFlow(tx);
      }
    }
    // b) Repayments this month
    for (final r in allRepayments) {
      if (r.date.month == today.month && r.date.year == today.year) {
        if (r.category == 'Borrow') {
          currentSpent += r.amount; // Cash left pocket
        } else if (r.category == 'Loan') {
          currentSpent -= r.amount; // Cash came back
        }
      }
    }
    currentSpent = currentSpent.clamp(0.0, double.infinity);

    // ── Selected-day cash flow ──────────────────────────────────────────
    double selectedDaySpent = 0.0;

    // a) Origin transactions this day
    for (final tx in allExpenses) {
      if (_isSameDay(_dateOnly(tx.date), _selectedDate)) {
        selectedDaySpent += _originCashFlow(tx);
      }
    }
    // b) Borrow repayments made on this day (cash left your pocket)
    for (final r in allRepayments) {
      if (r.category == 'Borrow' &&
          _isSameDay(_dateOnly(r.date), _selectedDate)) {
        selectedDaySpent += r.amount;
      }
    }
    // c) Loan repayments received on this day (cash came back → reduce spent)
    for (final r in allRepayments) {
      if (r.category == 'Loan' &&
          _isSameDay(_dateOnly(r.date), _selectedDate)) {
        selectedDaySpent -= r.amount;
      }
    }
    selectedDaySpent = selectedDaySpent.clamp(0.0, double.infinity);

    // ── Budget metrics ────────────────────────────────────────────────────
    final double budgetPercentage =
        monthlyBudget > 0
            ? (currentSpent / monthlyBudget).clamp(0.0, 1.0)
            : 0.0;
    final double dailyAverageSpent =
        currentDay > 0 ? currentSpent / currentDay : 0.0;
    final double remainingBudget = monthlyBudget - currentSpent;
    final double safeDailySpend =
        remainingDays > 0
            ? (remainingBudget / remainingDays)
                .clamp(0.0, double.infinity)
            : 0.0;

    // ── Notification badge logic ──────────────────────────────────────────
    final bool hasActiveLoan = allExpenses.any(
      (tx) => tx.category == 'Loan' && tx.isCleared == false,
    );
    final bool hasActiveBorrow = allExpenses.any(
      (tx) => tx.category == 'Borrow' && tx.isCleared == false,
    );

    // ── Daily transactions & repayments for selectedDate ─────────────────
    final List<RepaymentModel> dailyRepayments = allRepayments
        .where((r) => _isSameDay(_dateOnly(r.date), _selectedDate))
        .toList();

    final Set<String> activeParentIds = dailyRepayments.map((r) => r.parentId).toSet();

    final List<ExpenseModel> dailyTransactions = allExpenses
        .where((tx) =>
            _isSameDay(_dateOnly(tx.date), _selectedDate) ||
            activeParentIds.contains(tx.id))
        .toList();


    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1 ── Wallet Row (Teal card + Loans/Borrows) ──────────────
              _WalletRow(
                selectedDaySpent: selectedDaySpent,
                budgetPercentage: budgetPercentage,
                hasActiveLoan: hasActiveLoan,
                hasActiveBorrow: hasActiveBorrow,
                onLoanTap: () => _showLoanBorrowSheet(
                  context, 'Loan', allExpenses, provider, settings),
                onBorrowTap: () => _showLoanBorrowSheet(
                  context, 'Borrow', allExpenses, provider, settings),
              ),
              const SizedBox(height: 16),

              // 4 ── Date Navigation ────────────────────────────────────
              _DateNavRow(
                label: _dateLabel(_selectedDate),
                onPrev: () => _shiftDate(-1),
                onNext: _isSameDay(_selectedDate, _today())
                    ? null
                    : () => _shiftDate(1),
              ),
              const SizedBox(height: 16),

              // 5 ── Daily Ledger ──────────────────────────────────────
              _DailyLedger(
                transactions: dailyTransactions,
                repayments: dailyRepayments,
                primaryTeal: _primaryTeal,
                selectedDate: _selectedDate,
                getCategoryIcon: _getCategoryIcon,
                onEdit: (tx) => _showEditDialog(
                    context, tx, provider, settings),
                onRecordPayment: (tx) =>
                    _showRecordPaymentSheet(context, tx, provider),
                onAddExpense: () =>
                    context.go('/expense', extra: _selectedDate),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Loan / Borrow bottom sheet ────────────────────────────────────────────
  void _showLoanBorrowSheet(
    BuildContext context,
    String category,
    List<ExpenseModel> allExpenses,
    ExpenseProvider provider,
    SettingsProvider settings,
  ) {
    final isLoan = category == 'Loan';
    final accentColor =
        isLoan ? Colors.green.shade700 : Colors.red.shade700;
    final bgColor = isLoan ? Colors.green.shade50 : Colors.red.shade50;
    final borderColor =
        isLoan ? Colors.green.shade200 : Colors.red.shade200;

    final items = allExpenses
        .where((tx) => tx.category == category)
        .toList()
      ..sort((a, b) {
        // Pending first, then by date desc
        if (a.isCleared != b.isCleared) {
          return a.isCleared ? 1 : -1;
        }
        return b.date.compareTo(a.date);
      });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            accentColor.withValues(alpha: 0.15),
                        child: Icon(
                          isLoan
                              ? Icons.handshake_outlined
                              : Icons.account_balance_wallet,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isLoan ? 'Loans' : 'Borrows',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isLoan
                                  ? 'Money others owe you'
                                  : 'Money you owe others',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: PremiumEmptyState(
                              title: 'No ${category}s',
                              subtitle:
                                  'No ${isLoan ? "loan" : "borrow"} records found.',
                              icon: isLoan
                                  ? Icons.handshake_outlined
                                  : Icons.account_balance_wallet,
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: items.length,
                            itemBuilder: (_, i) {
                              final tx = items[i];
                              final cleared = tx.isCleared;
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cleared
                                        ? Colors.white
                                        : bgColor,
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    border: Border.all(
                                        color: cleared
                                            ? Colors.grey.shade100
                                            : borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6),
                                    onTap: !cleared
                                        ? () {
                                            Navigator.pop(ctx);
                                            _showRecordPaymentSheet(
                                                context,
                                                tx,
                                                provider);
                                          }
                                        : null,
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          cleared
                                              ? accentColor
                                                  .withValues(alpha: 0.1)
                                              : accentColor
                                                  .withValues(alpha: 0.2),
                                      child: Icon(
                                          _getCategoryIcon(tx.category),
                                          color: accentColor,
                                          size: 20),
                                    ),
                                    title: Text(
                                      tx.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: cleared
                                            ? Colors.grey
                                            : Colors.black87,
                                        decoration: cleared
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    subtitle: Text(
                                      cleared
                                          ? '${DateFormat('MMM d').format(tx.date)} • Cleared'
                                          : tx.isPartiallyPaid
                                              ? '${DateFormat('MMM d').format(tx.date)} • Rs ${tx.amountPaid.toStringAsFixed(0)} paid'
                                              : '${DateFormat('MMM d').format(tx.date)} • Tap to pay',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: cleared
                                              ? Colors.grey.shade400
                                              : accentColor,
                                          fontWeight: cleared
                                              ? FontWeight.normal
                                              : FontWeight.w600),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          cleared
                                              ? 'Rs ${tx.amount.toStringAsFixed(0)}'
                                              : '⏳ Rs ${tx.remainingAmount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (!cleared &&
                                            tx.isPartiallyPaid)
                                          Text(
                                            'of Rs ${tx.amount.toStringAsFixed(0)}',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey
                                                    .shade500),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WALLET ROW  (private widget)
// ═══════════════════════════════════════════════════════════════════════════════
class _WalletRow extends StatelessWidget {
  final double selectedDaySpent;
  final double budgetPercentage;
  final bool hasActiveLoan;
  final bool hasActiveBorrow;
  final VoidCallback onLoanTap;
  final VoidCallback onBorrowTap;

  const _WalletRow({
    required this.selectedDaySpent,
    required this.budgetPercentage,
    required this.hasActiveLoan,
    required this.hasActiveBorrow,
    required this.onLoanTap,
    required this.onBorrowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
        children: [
          // ── Full-width Teal "Spent" card ──────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2EC4B6), Color(0xFF22A89D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2EC4B6).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.today_outlined,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Spent',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Rs ${selectedDaySpent.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: budgetPercentage.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.black.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      budgetPercentage > 0.9
                          ? Colors.redAccent
                          : Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Loans & Borrows buttons side-by-side ───────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Loans',
                  sublabel: 'Owed to me',
                  icon: Icons.handshake_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5BA3E8), Color(0xFF4A90D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shadowColor: const Color(0xFF4A90D9),
                  hasNotification: hasActiveLoan,
                  onTap: onLoanTap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  label: 'Borrows',
                  sublabel: 'I owe',
                  icon: Icons.account_balance_wallet_outlined,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8E8E), Color(0xFFFF6B6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shadowColor: const Color(0xFFFF6B6B),
                  hasNotification: hasActiveBorrow,
                  onTap: onBorrowTap,
                ),
              ),
            ],
          ),
        ],
    );
  }
}

// ─── Action Button with notification badge ─────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final LinearGradient gradient;
  final Color shadowColor;
  final bool hasNotification;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.gradient,
    required this.shadowColor,
    required this.hasNotification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main button
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 22),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Notification badge (red dot)
        if (hasNotification)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.red.shade500,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DATE NAV ROW  (private widget)
// ═══════════════════════════════════════════════════════════════════════════════
class _DateNavRow extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext; // null → disable (can't go past today)

  const _DateNavRow({
    required this.label,
    required this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left arrow
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            color: Colors.black87,
            onPressed: onPrev,
            tooltip: 'Previous day',
          ),
          // Date label
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Right arrow
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              size: 28,
              color: onNext != null ? Colors.black87 : Colors.grey.shade300,
            ),
            onPressed: onNext,
            tooltip: 'Next day',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DAILY LEDGER  (private widget)
// ═══════════════════════════════════════════════════════════════════════════════
class _DailyLedger extends StatelessWidget {
  final List<ExpenseModel>   transactions;
  final List<RepaymentModel> repayments;   // ← repayment events on this day
  final Color primaryTeal;
  final DateTime selectedDate;
  final IconData Function(String) getCategoryIcon;
  final void Function(ExpenseModel) onEdit;
  final void Function(ExpenseModel) onRecordPayment;
  final VoidCallback onAddExpense;

  const _DailyLedger({
    required this.transactions,
    required this.repayments,
    required this.primaryTeal,
    required this.selectedDate,
    required this.getCategoryIcon,
    required this.onEdit,
    required this.onRecordPayment,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final displayRepayments = isToday ? <RepaymentModel>[] : repayments;
    final totalItems = transactions.length + displayRepayments.length;

    if (totalItems == 0) {
      return Column(
        children: [
          const PremiumEmptyState(
            title: 'No Expenses',
            subtitle: 'Nothing logged for this day yet.',
            icon: Icons.receipt_long_outlined,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: onAddExpense,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Expense',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$totalItems item${totalItems == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Origin transactions (expenses / loans / borrows)
        ...transactions.map((tx) => _TransactionCard(
          tx: tx,
          primaryTeal: primaryTeal,
          getCategoryIcon: getCategoryIcon,
          onEdit: () => onEdit(tx),
          onRecordPayment: () => onRecordPayment(tx),
          isCreationDay: tx.date.year == selectedDate.year && tx.date.month == selectedDate.month && tx.date.day == selectedDate.day,
        )),

        // Repayment events (cash that moved today)
        ...displayRepayments.map((r) => _RepaymentCard(repayment: r)),
      ],
    );
  }
}

// ─── Repayment event card ─────────────────────────────────────────────────────
class _RepaymentCard extends StatelessWidget {
  final RepaymentModel repayment;
  const _RepaymentCard({required this.repayment});

  @override
  Widget build(BuildContext context) {
    final isBorrow = repayment.category == 'Borrow';
    // Borrow repayment → you PAID OUT (red, debit)
    // Loan repayment   → you RECEIVED (green, credit)
    final color  = isBorrow ? Colors.red.shade600 : Colors.green.shade600;
    final bg     = isBorrow ? const Color(0xFFFFECEC) : const Color(0xFFECF9EC);
    final icon   = isBorrow ? Icons.arrow_upward   : Icons.arrow_downward;
    final label  = isBorrow ? 'Paid back (Borrow)' : 'Received back (Loan)';
    final prefix = isBorrow ? '- Rs ' : '+ Rs ';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('MMM d, h:mm a').format(repayment.date),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Text(
              '$prefix${repayment.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Single Transaction Card ───────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final ExpenseModel tx;
  final Color primaryTeal;
  final IconData Function(String) getCategoryIcon;
  final VoidCallback onEdit;
  final VoidCallback onRecordPayment;
  final bool isCreationDay;

  const _TransactionCard({
    required this.tx,
    required this.primaryTeal,
    required this.getCategoryIcon,
    required this.onEdit,
    required this.onRecordPayment,
    this.isCreationDay = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLoan   = tx.category == 'Loan';
    final isBorrow = tx.category == 'Borrow';
    final isSpecial = isLoan || isBorrow;
    final isCleared = tx.isCleared;

    final Color accentColor = isLoan
        ? Colors.green.shade600
        : isBorrow
            ? Colors.red.shade600
            : primaryTeal;
    final Color bgColor = isSpecial && !isCleared
        ? (isLoan ? const Color(0xFFECF9EC) : const Color(0xFFFFECEC))
        : Colors.white;

    // Non-creation-day: compact tappable tracking card
    if (isSpecial && !isCreationDay && !isCleared) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onRecordPayment,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  child: Icon(getCategoryIcon(tx.category),
                      color: accentColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        tx.isPartiallyPaid
                            ? '${tx.category} \u2022 Rs ${tx.amountPaid.toStringAsFixed(0)} paid'
                            : '${tx.category} \u2022 Tap to pay',
                        style: TextStyle(
                            fontSize: 12,
                            color: accentColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '\u23f3 Rs ${tx.remainingAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                          fontSize: 15),
                    ),
                    if (tx.isPartiallyPaid)
                      Text(
                        'Paid: ${tx.amountPaid.toStringAsFixed(0)} / ${tx.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 10,
                            color: accentColor.withValues(alpha: 0.75)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    Color amountColor   = Colors.redAccent;
    String amountPrefix = '- ';
    final Color containerColor = bgColor;
    final Color borderColor    = isSpecial && !isCleared
        ? accentColor.withValues(alpha: 0.2) : Colors.grey.shade100;
    final Color iconBgColor    = isCleared
        ? primaryTeal.withValues(alpha: 0.1) : accentColor.withValues(alpha: 0.15);
    final Color iconColor      = isCleared ? primaryTeal : accentColor;

    if (isSpecial) {
      if (isCleared) {
        amountColor  = isLoan ? Colors.green : Colors.redAccent;
        amountPrefix = isLoan ? '+ ' : '- ';
      } else {
        amountPrefix = '\u23f3 ';
        amountColor  = accentColor;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onLongPress: isCreationDay ? onEdit : null,
        child: Container(
          decoration: BoxDecoration(
            color: !isCleared ? containerColor : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: !isCleared ? borderColor : Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: isSpecial && !isCleared ? onRecordPayment : null,
            leading: CircleAvatar(
              backgroundColor:
                  !isCleared ? iconBgColor : primaryTeal.withValues(alpha: 0.1),
              child: Icon(getCategoryIcon(tx.category),
                  color: !isCleared ? iconColor : primaryTeal),
            ),
            title: Text(
              tx.label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: isSpecial && isCleared
                    ? TextDecoration.lineThrough
                    : null,
                color: isSpecial && isCleared
                    ? Colors.grey
                    : Colors.black87,
              ),
            ),
            subtitle: Text(
              isSpecial
                  ? (isCleared
                      ? '${tx.category} • Cleared'
                      : tx.isPartiallyPaid
                          ? '${tx.category} • Tap to pay remaining Rs ${tx.remainingAmount.toStringAsFixed(0)}'
                          : '${tx.category} • Tap to record payment')
                  : tx.category,
              style: TextStyle(
                color: isSpecial && !isCleared
                    ? accentColor
                    : Colors.grey.shade600,
                fontSize: 12,
                fontWeight: isSpecial && !isCleared
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isSpecial && !isCleared
                          ? '$amountPrefix Rs ${tx.remainingAmount.toStringAsFixed(0)}'
                          : '$amountPrefix Rs ${tx.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                          fontSize: 15),
                    ),
                    if (isSpecial && !isCleared && tx.isPartiallyPaid)
                      Text(
                        'Paid: ${tx.amountPaid.toStringAsFixed(0)} / ${tx.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 10,
                            color: amountColor.withValues(alpha: 0.75)),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
                // Edit icon (also reachable via long-press)
                if (isCreationDay)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onEdit,
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Icon(Icons.edit_outlined,
                          size: 18, color: Colors.grey.shade400),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}