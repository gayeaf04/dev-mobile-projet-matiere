import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/trophy.dart';
import 'workout_provider.dart';

// Plus longue série de jours consécutifs jamais réalisée (sur tout l'historique).
// On travaille en UTC minuit pour que les différences en jours restent exactes,
// même autour des changements d'heure.
int _bestStreak(Iterable<DateTime> dates) {
  final days = dates
      .map((d) => DateTime.utc(d.year, d.month, d.day))
      .toSet()
      .toList()
    ..sort();

  if (days.isEmpty) return 0;

  var best = 1;
  var current = 1;
  for (var i = 1; i < days.length; i++) {
    final gap = days[i].difference(days[i - 1]).inDays;
    if (gap == 1) {
      current++;
      if (current > best) best = current;
    } else {
      current = 1; // gap > 1 : la série est rompue (gap == 0 impossible après dédoublonnage)
    }
  }
  return best;
}

/// Liste des trophées avec leur progression, calculée à partir des séances
/// validées. À invalider après l'enregistrement d'une séance.
final trophiesProvider = FutureProvider<List<Trophy>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);

  final logs = (await repository.getAllWorkoutLogs())
      .where((log) => log.isCompleted)
      .toList();

  final total = logs.length;
  final bestStreak = _bestStreak(logs.map((log) => log.date));

  return [
    Trophy(
      id: 'first',
      title: 'Premier pas',
      description: 'Valide ta toute première séance',
      current: total,
      target: 1,
    ),
    Trophy(
      id: 'five',
      title: 'Assidu',
      description: 'Cumule 5 séances validées',
      current: total,
      target: 5,
    ),
    Trophy(
      id: 'ten',
      title: 'Machine',
      description: 'Cumule 10 séances validées',
      current: total,
      target: 10,
    ),
    Trophy(
      id: 'twentyFive',
      title: 'Vétéran',
      description: 'Cumule 25 séances validées',
      current: total,
      target: 25,
    ),
    Trophy(
      id: 'fifty',
      title: 'Légende',
      description: 'Cumule 50 séances validées',
      current: total,
      target: 50,
    ),
    Trophy(
      id: 'streak3',
      title: 'En feu',
      description: '3 jours d\'entraînement d\'affilée',
      current: bestStreak,
      target: 3,
    ),
    Trophy(
      id: 'streak7',
      title: 'Inarrêtable',
      description: '7 jours d\'entraînement d\'affilée',
      current: bestStreak,
      target: 7,
    ),
  ];
});
