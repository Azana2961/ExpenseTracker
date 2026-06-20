import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/premium_empty_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color primaryTeal = const Color(0xFF2EC4B6);

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Mock Database of expenses (Now supports 'Loan' and 'isCleared')
  final List<Map<String, dynamic>> _allTransactions = [
    {'id': '1', 'date': DateTime.now(), 'label': '🍔 Lunch', 'amount': '450', 'category': 'Food', 'icon': Icons.fastfood, 'isCleared': true},
    {'id': '2', 'date': DateTime.now(), 'label': '🍕 Pizza (Ali)', 'amount': '800', 'category': 'Loan', 'icon': Icons.handshake_outlined, 'isCleared': false}, // PENDING LOAN
    {'id': '3', 'date': DateTime.now().subtract(const Duration(days: 1)), 'label': '🛺 Rickshaw to Uni', 'amount': '150', 'category': 'Transport', 'icon': Icons.directions_car, 'isCleared': true},
    {'id': '4', 'date': DateTime.now().subtract(const Duration(days: 2)), 'label': '👕 Laundry', 'amount': '300', 'category': 'Laundry', 'icon': Icons.local_laundry_service, 'isCleared': true},
    {'id': '5', 'date': DateTime.now().subtract(const Duration(days: 2)), 'label': '☕ Coffee (Sara)', 'amount': '400', 'category': 'Loan', 'icon': Icons.handshake_outlined, 'isCleared': true}, // CLEARED LOAN
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // Filter transactions based on the selected date
  List<Map<String, dynamic>> _getTransactionsForDay(DateTime day) {
    return _allTransactions.where((tx) => isSameDay(tx['date'] as DateTime, day)).toList();
  }

  // Check if a specific day has any un-cleared loans
  bool _hasPendingLoan(DateTime day) {
    return _allTransactions.any((tx) => isSameDay(tx['date'] as DateTime, day) && tx['category'] == 'Loan' && tx['isCleared'] == false);
  }

  // --- POPUP: SHOW TRANSACTIONS FOR SPECIFIC DAY ---
  void _showTransactionsPopup(DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final dailyTransactions = _getTransactionsForDay(day);

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
                            final isLoan = tx['category'] == 'Loan';
                            final isCleared = tx['isCleared'] as bool? ?? true;

                            // UI styling based on Loan state
                            Color amountColor = Colors.redAccent;
                            String amountPrefix = '- ';
                            
                            if (isLoan) {
                              if (isCleared) {
                                amountColor = Colors.green; // Got money back
                                amountPrefix = '+ ';
                              } else {
                                amountColor = Colors.orange.shade700; // Pending
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
                                    // Logic to toggle the Loan Status
                                    setState(() {
                                      final txIndex = _allTransactions.indexWhere((t) => t['id'] == tx['id']);
                                      if (txIndex != -1) {
                                        _allTransactions[txIndex]['isCleared'] = !isCleared;
                                      }
                                    });
                                    setModalState(() {}); // Refresh Popup UI
                                  } : null,
                                  leading: CircleAvatar(
                                    backgroundColor: isLoan && !isCleared ? Colors.orange.withValues(alpha: 0.2) : primaryTeal.withValues(alpha: 0.1),
                                    child: Icon(tx['icon'] as IconData, color: isLoan && !isCleared ? Colors.orange.shade700 : primaryTeal),
                                  ),
                                  title: Text(
                                    tx['label'] as String, 
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: isLoan && isCleared ? TextDecoration.lineThrough : null, // Strike through if cleared
                                      color: isLoan && isCleared ? Colors.grey : Colors.black87,
                                    )
                                  ),
                                  subtitle: Text(
                                    isLoan 
                                      ? (isCleared ? 'Loan • Cleared' : 'Loan • Tap to mark as paid') 
                                      : tx['category'] as String, 
                                    style: TextStyle(
                                      color: isLoan && !isCleared ? Colors.orange.shade800 : Colors.grey.shade600, 
                                      fontSize: 12,
                                      fontWeight: isLoan && !isCleared ? FontWeight.bold : FontWeight.normal,
                                    )
                                  ),
                                  trailing: Text(
                                    '$amountPrefix Rs ${tx['amount']}', 
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
    const double currentSpent = 12500.0;
    const double monthlyBudget = 15000.0;
    const double idealDailySpend = 500.0; 
    
    final DateTime today = DateTime.now();
    final int daysInMonth = DateUtils.getDaysInMonth(today.year, today.month);
    final int currentDay = today.day;
    final int remainingDays = daysInMonth - currentDay;

    final double budgetPercentage = (currentSpent / monthlyBudget).clamp(0.0, 1.0);
    final double dailyAverageSpent = currentSpent / currentDay;
    final double remainingBudget = monthlyBudget - currentSpent;
    final double safeDailySpend = remainingDays > 0 ? (remainingBudget / remainingDays) : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('June Overview', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
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
              child: const Column(
                children: [
                  Text('Today Spent', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Rs 240', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
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
                
                // --- CUSTOM OVERLAPPING RING FOR LOANS ---
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (_hasPendingLoan(day)) {
                      return Center(
                        child: Container(
                          width: 42, // Large enough to encircle the date
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