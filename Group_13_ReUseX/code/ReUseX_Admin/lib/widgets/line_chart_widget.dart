import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineChartWidget extends StatelessWidget {
  const LineChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7B61FF),
              ],
            ),
            barWidth: 4,
            spots: const [
              FlSpot(0, 3),
              FlSpot(1, 5),
              FlSpot(2, 4),
              FlSpot(3, 7),
              FlSpot(4, 6),
              FlSpot(5, 8),
            ],
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7B61FF).withValues(alpha: 0.3),
                  const Color(0xFF7B61FF).withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}