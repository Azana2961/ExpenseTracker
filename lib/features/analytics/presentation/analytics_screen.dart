import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../setup/providers/settings_provider.dart';
import '../../../core/widgets/premium_empty_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final Color primaryTeal = const Color(0xFF2EC4B6);
  
  String? _selectedMonthName;

  Widget _buildInfoBox(
    String title,
    String amount,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final allExpenses = provider.expenses;
    final settings = context.watch<SettingsProvider>();
    final double budgetLimit = settings.monthlyBudget;

    Map<String, Map<String, dynamic>> monthlyData = {};
    String currentMonthKey = DateFormat('MMMM yyyy').format(DateTime.now());
    
    monthlyData[currentMonthKey] = {
      'totalSpent': 0.0,
      'categories': <String, double>{},
      'date': DateTime(DateTime.now().year, DateTime.now().month, 1),
    };


    // 1. Add origin transactions
    for (var tx in allExpenses) {
      double contribution = 0.0;
      if (tx.category == 'Borrow' || tx.category == 'Loan') {
        contribution = 0.0; // Industry standard: Loans and Borrows are transfers, not expenses.
      } else {
        contribution = tx.amount;
      }
      if (contribution == 0) continue; 

      String monthKey = DateFormat('MMMM yyyy').format(tx.date);
      
      if (!monthlyData.containsKey(monthKey)) {
        monthlyData[monthKey] = {
          'totalSpent': 0.0,
          'categories': <String, double>{},
          'date': DateTime(tx.date.year, tx.date.month, 1),
        };
      }
      
      monthlyData[monthKey]!['totalSpent'] += contribution;
      
      Map<String, double> cats = monthlyData[monthKey]!['categories'];
      cats[tx.category] = (cats[tx.category] ?? 0.0) + contribution;
    }

    // 2. Add repayments
    // (Industry standard: Repayments are asset transfers, they don't affect spent or categories)

    // Clean up negative/zero categories after refunds
    for (var monthData in monthlyData.values) {
      Map<String, double> cats = monthData['categories'];
      cats.removeWhere((key, value) => value <= 0);
    }

    List<String> sortedMonths = monthlyData.keys.toList();
    sortedMonths.sort((a, b) => (monthlyData[b]!['date'] as DateTime).compareTo(monthlyData[a]!['date'] as DateTime));

    if (_selectedMonthName == null || !sortedMonths.contains(_selectedMonthName)) {
      _selectedMonthName = sortedMonths.first;
    }

    final activeData = monthlyData[_selectedMonthName]!;
    final double totalSpent = activeData['totalSpent'];
    final Map<String, double> categories = activeData['categories'];
    
    DateTime activeDate = activeData['date'];
    int daysInMonth = DateUtils.getDaysInMonth(activeDate.year, activeDate.month);
    bool isCurrentMonth = activeDate.year == DateTime.now().year && activeDate.month == DateTime.now().month;
    int daysPassed = isCurrentMonth ? DateTime.now().day : daysInMonth;
    
    double avgDaily = daysPassed > 0 ? totalSpent / daysPassed : 0.0;
    
    double totalAllTimeSpent = 0.0;
    for (var monthData in monthlyData.values) {
      totalAllTimeSpent += monthData['totalSpent'] as double;
    }
    double avgMonthlySpent = monthlyData.isEmpty ? 0.0 : totalAllTimeSpent / monthlyData.length;

    final DateTime now = DateTime.now();
    final List<Map<String, dynamic>> last7DaysData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return {'date': date, 'spent': 0.0};
    });

    for (var tx in allExpenses) {
      if (tx.category == 'Borrow' || tx.category == 'Loan') continue;
      
      for (var i = 0; i < 7; i++) {
        final bucketDate = last7DaysData[i]['date'] as DateTime;
        if (bucketDate.year == tx.date.year && bucketDate.month == tx.date.month && bucketDate.day == tx.date.day) {
          last7DaysData[i]['spent'] += tx.amount;
          break;
        }
      }
    }

    double maxSpend7Days = 0.0;
    for (var dayData in last7DaysData) {
      if (dayData['spent'] > maxSpend7Days) maxSpend7Days = dayData['spent'];
    }
    if (maxSpend7Days == 0) maxSpend7Days = 100;

    final Map<String, Color> catColors = {
      'Food': primaryTeal,
      'Transport': Colors.blue,
      'Laundry': Colors.indigo,
      'Bills': Colors.purple,
      'Loan': Colors.green.shade600,
      'Borrow': Colors.red.shade600,
      'Supplies': Colors.amber,
      'Other': Colors.grey.shade600,
    };

    Color getCatColor(String cat, int index) {
      if (catColors.containsKey(cat)) return catColors[cat]!;
      List<Color> fallback = [Colors.pink, Colors.cyan, Colors.lime, Colors.deepOrange];
      return fallback[index % fallback.length];
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedMonthName!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: Rs ${totalSpent.toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: totalSpent > budgetLimit ? Colors.redAccent : primaryTeal),
                )
              ],
            ),
            const SizedBox(height: 24),

            Text('Category Wise Spend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 180,
              child: categories.isEmpty 
                ? const Center(child: Text('No expenses recorded for this month.', style: TextStyle(color: Colors.grey)))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 40,
                      sections: categories.entries.toList().asMap().entries.map((entry) {
                        int idx = entry.key;
                        String catName = entry.value.key;
                        double catAmount = entry.value.value;
                        
                        return PieChartSectionData(
                          color: getCatColor(catName, idx),
                          value: catAmount,
                          title: 'Rs ${(catAmount / 1000).toStringAsFixed(1)}k',
                          radius: 50,
                          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        );
                      }).toList(),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            
            if (categories.isNotEmpty)
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: categories.keys.toList().asMap().entries.map((entry) {
                  int idx = entry.key;
                  String cat = entry.value;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: getCatColor(cat, idx), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Text(cat, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                    ],
                  );
                }).toList(),
              ),
            const SizedBox(height: 32),
            const Divider(color: Colors.black12),
            const SizedBox(height: 20),

            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    'Average Daily Spent',
                    'Rs ${avgDaily.toStringAsFixed(0)}',
                    primaryTeal.withValues(alpha: 0.1),
                    primaryTeal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoBox(
                    'Average Monthly Spent',
                    'Rs ${avgMonthlySpent.toStringAsFixed(0)}',
                    Colors.purple.withValues(alpha: 0.1),
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text('Last 7 Days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxSpend7Days * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'Rs ${rod.toY.toStringAsFixed(0)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final date = last7DaysData[value.toInt()]['date'] as DateTime;
                          final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                          final text = isToday ? 'Today' : DateFormat('EEE').format(date);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(text, style: TextStyle(fontSize: 10, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? primaryTeal : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    final spent = last7DaysData[index]['spent'] as double;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: spent,
                          color: primaryTeal,
                          width: 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        )
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 20),

            const Text('History Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            if (sortedMonths.length == 1 && categories.isEmpty)
               const PremiumEmptyState(
                 title: 'No History',
                 subtitle: 'Once you start tracking expenses, your past months will appear here.',
                 icon: Icons.history,
               )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedMonths.length,
                itemBuilder: (context, index) {
                  final monthName = sortedMonths[index];
                  final monthCost = monthlyData[monthName]!['totalSpent'] as double;
                  final bool isSelected = monthName == _selectedMonthName;

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSelected ? primaryTeal : Theme.of(context).dividerColor, width: isSelected ? 2 : 1),
                    ),
                    color: isSelected ? primaryTeal.withValues(alpha: 0.1) : Theme.of(context).colorScheme.surface,
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _selectedMonthName = monthName;
                        });
                      },
                      leading: Icon(
                        Icons.calendar_month, 
                        color: isSelected ? primaryTeal : (monthCost > budgetLimit ? Colors.redAccent : Colors.grey),
                      ),
                      title: Text(
                        monthName, 
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Rs ${monthCost.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 15,
                              color: monthCost > budgetLimit ? Colors.redAccent : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}