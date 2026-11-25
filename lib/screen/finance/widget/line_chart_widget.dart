import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesLineChart extends StatelessWidget {
  final List<dynamic> chartData;
  const SalesLineChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) return const Center(child: Text('No data'));
    return Container(
      height: 250, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: LineChart(LineChartData(
        lineBarsData: [
          LineChartBarData(spots: List.generate(chartData.length, (i) => FlSpot(i.toDouble(), chartData[i]['sales'].toDouble())), isCurved: true, color: Colors.green),
          LineChartBarData(spots: List.generate(chartData.length, (i) => FlSpot(i.toDouble(), chartData[i]['expenses'].toDouble())), isCurved: true, color: Colors.red),
        ],
      )),
    );
  }
}