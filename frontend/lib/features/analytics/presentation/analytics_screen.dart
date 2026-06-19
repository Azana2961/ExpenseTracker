import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final Color primaryTeal = const Color(0xFF2EC4B6);
  
  // Track which month's analytics are currently active
  String _selectedMonthName = 'June 2026 (Current)';

  // Mock Database containing analytics datasets for different months
  final Map<String, Map<String, dynamic>> _monthlyDataRepo = {
    'June 2026 (Current)': {
      'totalSpent': 12500.0,
      'budgetLimit': 15000.0,
      'avgDaily': 658.0,
      'idealDaily': 500.0,
      'categories': {
        'Food': 6200.0,
        'Transport': 2100.0,
        'Laundry': 1200.0,
        'Bills': 2000.0,
        'Other': 1000.0,
      }
    },
    'May 2026': {
      'totalSpent': 14200.0,
      'budgetLimit': 15000.0,
      'avgDaily': 458.0,
      'idealDaily': 500.0,
      'categories': {
        'Food': 7500.0,
        'Transport': 2500.0,
        'Laundry': 900.0,
        'Bills': 2200.0,
        'Other': 1100.0,
      }
    },
    'April 2026': {
      'totalSpent': 15800.0, // Over budget example
      'budgetLimit': 15000.0,
      'avgDaily': 526.0,
      'idealDaily': 500.0,
      'categories': {
        'Food': 8100.0,
        'Transport': 3000.0,
        'Laundry': 1100.0,
        'Bills': 2000.0,
        'Other': 1600.0,
      }
    },
    'March 2026': {
      'totalSpent': 11900.0,
      'budgetLimit': 14000.0,
      'avgDaily': 383.0,
      'idealDaily': 450.0,
      'categories': {
        'Food': 5800.0,
        'Transport': 1800.0,
        'Laundry': 1000.0,
        'Bills': 2500.0,
        'Other': 800.0,
      }
    },
  };

  @override
  Widget build(BuildContext context) {
    // Extract data matching the currently active selection
    final activeData = _monthlyDataRepo[_selectedMonthName]!;
    final double totalSpent = activeData['totalSpent'];
    final double budgetLimit = activeData['budgetLimit'];
    final double avgDaily = activeData['avgDaily'];
    final double idealDaily = activeData['idealDaily'];
    final Map<String, double> categories = Map<String, double>.from(activeData['categories']);

    // Map categories to specific visual distinct colors
    final Map<String, Color> catColors = {
      'Food': primaryTeal,
      'Transport': Colors.blue,
      'Laundry': Colors.indigo,
      'Bills': Colors.purple,
      'Other': Colors.grey.shade400,
    };

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
                  _selectedMonthName,
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
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                  sections: categories.entries.map((entry) {
                    return PieChartSectionData(
                      color: catColors[entry.key] ?? Colors.teal,
                      value: entry.value,
                      title: 'Rs ${(entry.value / 1000).toStringAsFixed(1)}k',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Legend Row for Pie Chart
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: categories.keys.map((cat) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: catColors[cat], shape: BoxShape.circle)),
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
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _monthlyDataRepo.keys.length,
              itemBuilder: (context, index) {
                final monthName = _monthlyDataRepo.keys.elementAt(index);
                final monthCost = _monthlyDataRepo[monthName]!['totalSpent'] as double;
                final monthLimit = _monthlyDataRepo[monthName]!['budgetLimit'] as double;
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
                      color: isSelected ? primaryTeal : (monthCost > monthLimit ? Colors.redAccent : Colors.grey),
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
                            color: monthCost > monthLimit ? Colors.redAccent : Colors.black87
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
}