import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ExpensesPieChart extends StatelessWidget {
  final double sales;
  final double expenses;
  const ExpensesPieChart({super.key, required this.sales, required this.expenses});

  @override
  Widget build(BuildContext context) {
    double total = sales + expenses == 0 ? 1 : sales + expenses;
    return Container(
      height: 200, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: PieChart(PieChartData(sections: [
        PieChartSectionData(value: sales, color: Colors.green, title: '${(sales/total*100).toStringAsFixed(0)}%'),
        PieChartSectionData(value: expenses, color: Colors.red, title: '${(expenses/total*100).toStringAsFixed(0)}%'),
      ])),
    );
  }
}