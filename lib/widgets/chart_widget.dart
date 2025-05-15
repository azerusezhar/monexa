import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final Color lineColor;
  final Color? textColor;

  const ChartWidget({
    super.key,
    required this.data,
    this.lineColor = Colors.blue,
    this.textColor, 
  });

  @override
  Widget build(BuildContext context) {
    final Color defaultTextColor = Theme.of(context).textTheme.bodySmall?.color ?? Colors.white70;

    if (data.isEmpty) {
      return Center(
        child: Text(
          "Not enough data for chart.",
          style: TextStyle(color: textColor ?? defaultTextColor),
        ),
      );
    }

    final spots = data.asMap().entries.map((e) {
      final amount = (e.value['amount'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(e.key.toDouble(), amount);
    }).toList();

    double maxY = 0;
    if (spots.isNotEmpty) {
      maxY = spots.map((s) => s.y).fold(0.0, (prev, current) => current > prev ? current : prev);
      if (maxY == 0) maxY = 100000; // Default jika semua nilai 0 untuk skala
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.2, // Beri sedikit padding di atas
        titlesData: const FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withOpacity(0.3),
                  lineColor.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          )
        ],
      ),
    );
  }
}