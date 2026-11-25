import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesChart extends StatelessWidget {
  final List<dynamic> chartData;
  const SalesChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) return const Center(child: Text('No data'));
    return Container(
      height: 250, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: List.generate(chartData.length, (index) => BarChartGroupData(x: index, barRods: [
          BarChartRodData(toY: chartData[index]['sales'].toDouble(), color: Colors.green, width: 8),
          BarChartRodData(toY: chartData[index]['expenses'].toDouble(), color: Colors.red, width: 8),
        ])),
      )),
    );
  }
}