import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/business_data.dart';

class FinanceChart extends StatelessWidget {
  final List<Expense> expenses;

  const FinanceChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    // Group expenses by category and sum amounts
    final Map<String, double> groupedExpenses = {};
    for (var expense in expenses) {
      groupedExpenses[expense.category] = 
          (groupedExpenses[expense.category] ?? 0) + expense.amount;
    }
    
    final expenseList = groupedExpenses.entries
        .map((e) => MapEntry(e.key, e.value))
        .toList();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: expenseList.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${expenseList[groupIndex].key}\n\$${rod.toY.toStringAsFixed(2)}',
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
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < expenseList.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        expenseList[value.toInt()].key,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: expenseList.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.value,
                  color: _getColorForCategory(entry.value.key),
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getColorForCategory(String category) {
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.green,
      Colors.purple,
      Colors.red,
    ];
    return colors[category.hashCode % colors.length];
  }
}
