import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/models/weight_log.dart';

/// Courbe d'évolution du poids de l'utilisateur au fil des mois, à partir
/// de son historique de mesures (une par jour).
class WeightChart extends StatelessWidget {
  final List<WeightLog> logs;

  const WeightChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.length < 2) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.show_chart, color: Colors.blueGrey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Modifie ton poids une nouvelle fois pour voir apparaître '
                'ta courbe d\'évolution ici.',
              ),
            ),
          ],
        ),
      );
    }

    final primary = Theme.of(context).colorScheme.primary;

    final spots = <FlSpot>[
      for (var i = 0; i < logs.length; i++)
        FlSpot(i.toDouble(), logs[i].weight),
    ];

    final values = logs.map((l) => l.weight).toList(growable: false);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxVal - minVal) * 0.2).clamp(1.0, double.infinity);
    final minY = (minVal - pad).clamp(0.0, double.infinity);
    final maxY = maxVal + pad;
    final labelInterval = (logs.length / 5).ceil().toDouble();

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (logs.length - 1).toDouble(),
          minY: minY.toDouble(),
          maxY: maxY.toDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval:
                ((maxY - minY) / 4).clamp(1.0, double.infinity).toDouble(),
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  '${value.round()}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: labelInterval,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= logs.length) {
                    return const SizedBox.shrink();
                  }
                  if (value != i.toDouble()) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _shortDate(logs[i].date),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey.shade800,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final l = logs[spot.x.round()];
                return LineTooltipItem(
                  '${_fmt(l.weight)} kg\n${_shortDate(l.date)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              preventCurveOverShooting: true,
              color: primary,
              barWidth: 3,
              dotData: FlDotData(show: logs.length <= 12),
              belowBarData: BarAreaData(
                show: true,
                color: primary.withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _fmt(double w) =>
      w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);
}
