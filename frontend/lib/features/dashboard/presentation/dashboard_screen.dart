import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryTeal = Color(0xFF2EC4B6);

    // Mock Data for the UI
    const double currentSpent = 12500.0;
    const double monthlyBudget = 15000.0;
    const double idealDailySpend = 500.0; 
    
    // Dynamic Date Math
    final DateTime today = DateTime.now();
    final int daysInMonth = DateUtils.getDaysInMonth(today.year, today.month);
    final int currentDay = today.day;
    final int remainingDays = daysInMonth - currentDay;

    // Averages Calculations
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
            // --- TOP SECTION ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryTeal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Text('Today Spent', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Rs 240', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // --- MIDDLE SECTION: PACING ---
            const Text('Monthly Budget', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spent Till Date', style: TextStyle(color: Colors.grey)),
                    Text('Rs 12,500', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total Budget', style: TextStyle(color: Colors.grey)),
                    Text('Rs 15,000', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 20),

            // --- THE 3 AVERAGES BOXES ---
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

            // --- CALENDAR WIDGET ---
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
                focusedDay: today,
                currentDay: today,
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(color: primaryTeal, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: Color(0x802EC4B6), shape: BoxShape.circle),
                ),
                onDaySelected: (selectedDay, focusedDay) => context.go('/expense', extra: selectedDay),
              ),
            ),
            const SizedBox(height: 20),
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