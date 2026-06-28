import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../expenses/providers/expense_provider.dart';
import '../../../core/widgets/premium_empty_state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final Color primaryTeal = const Color(0xFF2EC4B6);
  
  // Track which month's analytics are currently active
  String? _selectedMonthName;

  @override
  Widget build(BuildContext context) {
    // 1. Fetch live data from Provider
    final provider = context.watch<ExpenseProvider>();
    final allExpenses = provider.expenses;

    // 2. Fetch live settings from Setup Screen
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        
        double budgetLimit = 15000.0;
        double idealDaily = 500.0;
        
        if (snapshot.hasData) {
          budgetLimit = double.tryParse(snapshot.data!.getString('monthlyBudget') ?? '15000') ?? 15000.0;
          idealDaily = double.tryParse(snapshot.data!.getString('idealDaily') ?? '500') ?? 500.0;
        }

        // 3. Dynamically Group Data by Month
        Map<String, Map<String, dynamic>> monthlyData = {};
        String currentMonthKey = DateFormat('MMMM yyyy').format(DateTime.now());
        
        // Guarantee current month is always available even if no expenses are logged yet
        monthlyData[currentMonthKey] = {
          'totalSpent': 0.0,
          'categories': <String, double>{},
          'date': DateTime(DateTime.now().year, DateTime.now().month, 1),
        };

        for (var tx in allExpenses) {
          // Ignore cleared loans so they don't corrupt the budget pie chart
          if (tx.category == 'Loan' && tx.isCleared) continue;

          String monthKey = DateFormat('MMMM yyyy').format(tx.date);
          
          if (!monthlyData.containsKey(monthKey)) {
            monthlyData[monthKey] = {
              'totalSpent': 0.0,
              'categories': <String, double>{},
              'date': DateTime(tx.date.year, tx.date.month, 1),
            };
          }
          
          monthlyData[monthKey]!['totalSpent'] += tx.amount;
          
          Map<String, double> cats = monthlyData[monthKey]!['categories'];
          cats[tx.category] = (cats[tx.category] ?? 0.0) + tx.amount;
        }

        // Sort months descending (Newest first)
        List<String> sortedMonths = monthlyData.keys.toList();
        sortedMonths.sort((a, b) => (monthlyData[b]!['date'] as DateTime).compareTo(monthlyData[a]!['date'] as DateTime));

        // Default to the newest month if nothing is selected
        if (_selectedMonthName == null || !sortedMonths.contains(_selectedMonthName)) {
          _selectedMonthName = sortedMonths.first;
        }

        // 4. Extract active data for UI building
        final activeData = monthlyData[_selectedMonthName]!;
        final double totalSpent = activeData['totalSpent'];
        final Map<String, double> categories = activeData['categories'];
        
        DateTime activeDate = activeData['date'];
        int daysInMonth = DateUtils.getDaysInMonth(activeDate.year, activeDate.month);
        bool isCurrentMonth = activeDate.year == DateTime.now().year && activeDate.month == DateTime.now().month;
        int daysPassed = isCurrentMonth ? DateTime.now().day : daysInMonth;
        
        double avgDaily = daysPassed > 0 ? totalSpent / daysPassed : 0.0;

        // Map categories to specific visual distinct colors
        final Map<String, Color> catColors = {
          'Food': primaryTeal,
          'Transport': Colors.blue,
          'Laundry': Colors.indigo,
          'Bills': Colors.purple,
          'Loan': Colors.orange.shade700,
          'Supplies': Colors.amber,
          'Other': Colors.grey.shade600,
        };

        Color getCatColor(String cat, int index) {
          if (catColors.containsKey(cat)) return catColors[cat]!;
          List<Color> fallback = [Colors.pink, Colors.cyan, Colors.lime, Colors.deepOrange];
          return fallback[index % fallback.length];
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('Analytics', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Active Label Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedMonthName!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    Text(
                      'Total: Rs ${totalSpent.toStringAsFixed(0)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: totalSpent > budgetLimit ? Colors.redAccent : primaryTeal),
                    )
                  ],
                ),
                const SizedBox(height: 24),

                // --- SECTION 1: PIE CHART (CATEGORY BREAKDOWN) ---
                const Text('Category Wise Spend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 180,
                  child: categories.isEmpty 
                    ? const Center(child: Text('No expenses recorded for this month.', style: TextStyle(color: Colors.grey)))
                    : PieChart(
                        PieChartData(
                          sectionsSpace: 4,
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
                            );
                          }).toList(),
                        ),
                      ),
                ),
                const SizedBox(height: 16),
                
                // Legend Row for Pie Chart
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
                          Text(cat, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 32),
                const Divider(color: Colors.black12),
                const SizedBox(height: 20),

                // --- SECTION 2: BAR CHART (AVERAGE VS BUDGET LIMIT) ---
                const Text('Daily Average vs Ideal Limit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 24),
                SizedBox(
                  height: 160,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceEvenly,
                      maxY: (avgDaily > idealDaily ? avgDaily : idealDaily) * 1.2,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              switch (value.toInt()) {
                                case 0: return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Actual Avg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
                                case 1: return const Padding(padding: EdgeInsets.only(top: 8), child: Text('Ideal Limit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)));
                                default: return const Text('');
                              }
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(
                            toY: avgDaily, 
                            color: avgDaily > idealDaily ? Colors.redAccent : primaryTeal, 
                            width: 32, 
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          )
                        ]),
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(
                            toY: idealDaily, 
                            color: Colors.purple.withValues(alpha: 0.6), 
                            width: 32, 
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          )
                        ]),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    avgDaily > idealDaily 
                      ? 'Over budget by Rs ${(avgDaily - idealDaily).toStringAsFixed(0)} per day!' 
                      : 'Saving Rs ${(idealDaily - avgDaily).toStringAsFixed(0)} per day under ideal tracking.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: avgDaily > idealDaily ? Colors.redAccent : Colors.green),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(color: Colors.black12),
                const SizedBox(height: 20),

                // --- SECTION 3: HISTORICAL LIST OF PAST MONTHS ---
                const Text('History Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                          side: BorderSide(color: isSelected ? primaryTeal : Colors.grey.shade100, width: isSelected ? 2 : 1),
                        ),
                        color: isSelected ? primaryTeal.withValues(alpha: 0.05) : Colors.grey.shade50,
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
                                  color: monthCost > budgetLimit ? Colors.redAccent : Colors.black87
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
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
    );
  }
}