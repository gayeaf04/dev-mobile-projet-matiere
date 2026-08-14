import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/exercise_progress.dart';
import '../providers/progression_provider.dart';
import '../widgets/exercise_image.dart';

/// Fiche détaillée d'un exercice : démonstration du mouvement, description et
/// surtout le suivi de la progression (records + évolution séance par séance).
class ExerciseDetailScreen extends ConsumerWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(exerciseProgressionProvider(exercise.id));

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🖼️ Démonstration du mouvement (départ → position finale)
            ExerciseDemo(exercise: exercise, height: 180),
            const SizedBox(height: 16),
            Center(
              child: Chip(
                avatar: const Icon(Icons.fitness_center, size: 18),
                label: Text(exercise.muscleGroupLabel),
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              exercise.description,
              style: TextStyle(color: Colors.grey[700], fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.trending_up,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Ta progression',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            progressAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Impossible de charger la progression : $err'),
              ),
              data: (progress) => _buildProgress(context, progress),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context, ExerciseProgress progress) {
    if (progress.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.insights, color: Colors.blueGrey),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aucune donnée pour le moment. Réalise cet exercice pendant une '
                'séance pour suivre ta progression (charge et répétitions).',
              ),
            ),
          ],
        ),
      );
    }

    final maxOrm = progress.sessions
        .map((s) => s.best.estimatedOneRepMax)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cartes des records personnels
        Row(
          children: [
            if (progress.heaviestSet != null)
              Expanded(
                child: _prCard(
                  context,
                  icon: Icons.fitness_center,
                  title: 'Charge max',
                  value: '${_fmt(progress.heaviestSet!.weight)} kg',
                  subtitle: '× ${progress.heaviestSet!.reps} reps',
                ),
              ),
            if (progress.heaviestSet != null && progress.bestOneRepMax != null)
              const SizedBox(width: 12),
            if (progress.bestOneRepMax != null)
              Expanded(
                child: _prCard(
                  context,
                  icon: Icons.emoji_events,
                  title: '1RM estimé',
                  value: '${_fmt(progress.bestOneRepMax!.estimatedOneRepMax)} kg',
                  subtitle: 'record de force',
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),

        // 📈 Courbe d'évolution du 1RM estimé (dès qu'on a au moins 2 séances)
        if (progress.sessions.length >= 2) ...[
          Text(
            'Évolution du 1RM estimé (kg)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: _chart(context, progress.sessions)),
          const SizedBox(height: 24),
        ],

        Text(
          'Meilleure série par séance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 12),
        ...progress.sessions.map((s) => _sessionBar(context, s, maxOrm)),
      ],
    );
  }

  Widget _prCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 2),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _sessionBar(BuildContext context, SessionBest s, double maxOrm) {
    final fraction =
        maxOrm > 0 ? (s.best.estimatedOneRepMax / maxOrm).clamp(0.12, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              _shortDate(s.date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(height: 30, color: Colors.grey.shade200),
                  FractionallySizedBox(
                    widthFactor: fraction.toDouble(),
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${_fmt(s.best.weight)} kg × ${s.best.reps}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chart(BuildContext context, List<SessionBest> sessions) {
    final primary = Theme.of(context).colorScheme.primary;

    final spots = <FlSpot>[
      for (var i = 0; i < sessions.length; i++)
        FlSpot(i.toDouble(), sessions[i].best.estimatedOneRepMax),
    ];

    final values =
        sessions.map((s) => s.best.estimatedOneRepMax).toList(growable: false);
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final pad = ((maxVal - minVal) * 0.2).clamp(2.0, double.infinity);
    final minY = (minVal - pad).clamp(0.0, double.infinity);
    final maxY = maxVal + pad;
    final labelInterval = (sessions.length / 5).ceil().toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (sessions.length - 1).toDouble(),
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
                if (i < 0 || i >= sessions.length) {
                  return const SizedBox.shrink();
                }
                if (value != i.toDouble()) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _shortDate(sessions[i].date),
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
              final s = sessions[spot.x.round()];
              return LineTooltipItem(
                '${_fmt(s.best.weight)} kg × ${s.best.reps}\n'
                '1RM ${_fmt(s.best.estimatedOneRepMax)} kg',
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
            dotData: FlDotData(show: sessions.length <= 12),
            belowBarData: BarAreaData(
              show: true,
              color: primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  String _shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _fmt(double w) =>
      w == w.roundToDouble() ? w.toStringAsFixed(0) : w.toStringAsFixed(1);
}
