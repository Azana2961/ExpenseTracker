import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/premium_empty_state.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../setup/providers/settings_provider.dart';
import '../../expenses/models/expense_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color primaryTeal = const Color(0xFF2EC4B6);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Helper to map categories to specific icons
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food': return Icons.fastfood;
      case 'Transport': return Icons.directions_car;
      case 'Laundry': return Icons.local_laundry_service;
      case 'Bills': return Icons.receipt;
      case 'Loan': return Icons.handshake_outlined;
      case 'Supplies': return Icons.shopping_cart;
      default: return Icons.payments_outlined;
    }
  }

  // --- POPUP: SHOW TRANSACTIONS FOR SPECIFIC DAY ---
  void _showTransactionsPopup(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<ExpenseProvider>(
          builder: (context, provider, child) {
            final dailyTransactions = provider.expenses.where((tx) => isSameDay(tx.date, day)).toList();

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isSameDay(day, DateTime.now()) 
                              ? "Today's Activity" 
                              : DateFormat('MMM d, yyyy').format(day),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (dailyTransactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: PremiumEmptyState(
                          title: 'No Expenses',
                          subtitle: 'You have not logged any spending for this day.',
                          icon: Icons.receipt_long_outlined,
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: dailyTransactions.length,
                          itemBuilder: (context, index) {
                            final tx = dailyTransactions[index];
                            final isLoan = tx.category == 'Loan';
                            final isCleared = tx.isCleared;

                            Color amountColor = Colors.redAccent;
                            String amountPrefix = '- ';
                            
                            if (isLoan) {
                              if (isCleared) {
                                amountColor = Colors.green; 
                                amountPrefix = '+ ';
                              } else {
                                amountColor = Colors.orange.shade700; 
                                amountPrefix = '⏳ ';
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isLoan && !isCleared ? Colors.orange.shade50 : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isLoan && !isCleared ? Colors.orange.shade200 : Colors.grey.shade100),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  onTap: isLoan ? () {
                                    final updatedTx = tx.copyWith(isCleared: !isCleared);
                                    provider.updateExpense(updatedTx);
                                  } : null,
                                  leading: CircleAvatar(
                                    backgroundColor: isLoan && !isCleared ? Colors.orange.withValues(alpha: 0.2) : primaryTeal.withValues(alpha: 0.1),
                                    child: Icon(_getCategoryIcon(tx.category), color: isLoan && !isCleared ? Colors.orange.shade700 : primaryTeal),
                                  ),
                                  title: Text(
                                    tx.label, 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: isLoan && isCleared ? TextDecoration.lineThrough : null, 
                                      color: isLoan && isCleared ? Colors.grey : Colors.black87,
                                    )
                                  ),
                                  subtitle: Text(
                                    isLoan 
                                      ? (isCleared ? 'Loan • Cleared' : 'Loan • Tap to mark as paid') 
                                      : tx.category, 
                                    style: TextStyle(
                                      color: isLoan && !isCleared ? Colors.orange.shade800 : Colors.grey.shade600, 
                                      fontSize: 12,
                                      fontWeight: isLoan && !isCleared ? FontWeight.bold : FontWeight.normal,
                                    )
                                  ),
                                  trailing: Text(
                                    '$amountPrefix Rs ${tx.amount.toStringAsFixed(0)}', 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: amountColor, fontSize: 16)
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context); 
                          context.go('/expense', extra: day); 
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Expense for this Day', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Fetch live data from ExpenseProvider
    final provider = context.watch<ExpenseProvider>();
    final allExpenses = provider.expenses;

    // 2. Watch live settings directly from the new SettingsProvider!
    final settings = context.watch<SettingsProvider>();
    final double monthlyBudget = settings.monthlyBudget;
    final double idealDailySpend = settings.idealDailySpend;

    final DateTime today = DateTime.now();
    final int daysInMonth = DateUtils.getDaysInMonth(today.year, today.month);
    final int currentDay = today.day;
    final int remainingDays = daysInMonth - currentDay;

    // 3. Calculate REAL spending for current month
    double currentSpent = 0.0;
    double todaySpent = 0.0;
    
    for (var tx in allExpenses) {
      if (tx.date.month == today.month && tx.date.year == today.year) {
        if (tx.category == 'Loan' && tx.isCleared) continue; 
        
        currentSpent += tx.amount;
        if (isSameDay(tx.date, today)) todaySpent += tx.amount;
      }
    }

    final double budgetPercentage = monthlyBudget > 0 ? (currentSpent / monthlyBudget).clamp(0.0, 1.0) : 0.0;
    final double dailyAverageSpent = currentDay > 0 ? (currentSpent / currentDay) : 0.0;
    final double remainingBudget = monthlyBudget - currentSpent;
    final double safeDailySpend = remainingDays > 0 ? (remainingBudget / remainingDays).clamp(0.0, double.infinity) : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('${DateFormat('MMMM').format(today)} Overview', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: primaryTeal, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Text('Today Spent', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Rs ${todaySpent.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildInfoBox('Avg Spent', 'Rs ${dailyAverageSpent.toStringAsFixed(0)}', primaryTeal.withValues(alpha: 0.1), primaryTeal)),
                const SizedBox(width: 8),
                Expanded(child: _buildInfoBox('Ideal Daily', 'Rs ${idealDailySpend.toStringAsFixed(0)}', Colors.purple.withValues(alpha: 0.1), Colors.purple)),
                const SizedBox(width: 8),
                Expanded(child: _buildInfoBox('Safe to Spend', 'Rs ${safeDailySpend.toStringAsFixed(0)}', Colors.orange.withValues(alpha: 0.1), Colors.orange.shade800)),
              ],
            ),
            const SizedBox(height: 28),

            const Text('Monthly Budget', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Spent Till Date', style: TextStyle(color: Colors.grey)),
                    Text('Rs ${currentSpent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Budget', style: TextStyle(color: Colors.grey)),
                    Text('Rs ${monthlyBudget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: budgetPercentage,
                minHeight: 14,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(budgetPercentage > 0.9 ? Colors.redAccent : primaryTeal),
              ),
            ),
            const SizedBox(height: 8),
            Text('${(budgetPercentage * 100).toStringAsFixed(1)}% of your budget used', style: TextStyle(color: budgetPercentage > 0.9 ? Colors.redAccent : Colors.grey.shade700, fontWeight: FontWeight.w500)),
            const SizedBox(height: 28),

            const Text('Expense Calendar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    bool hasPendingLoan = allExpenses.any((tx) => isSameDay(tx.date, day) && tx.category == 'Loan' && tx.isCleared == false);
                    
                    if (hasPendingLoan) {
                      return Center(
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orange.shade700, width: 2.5),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.3), shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: primaryTeal, shape: BoxShape.circle),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _showTransactionsPopup(selectedDay);
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String title, String amount, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(amount, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}