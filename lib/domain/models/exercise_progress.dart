import 'set_log.dart';

/// Meilleure série d'une journée d'entraînement (au sens du 1RM estimé).
class SessionBest {
  final DateTime date;
  final SetLog best;

  const SessionBest({required this.date, required this.best});
}

/// Vue agrégée de la progression sur un exercice, calculée à partir des
/// séries enregistrées.
class ExerciseProgress {
  /// Meilleure série de chaque séance, triée du plus ancien au plus récent.
  final List<SessionBest> sessions;

  /// Record personnel à la charge la plus lourde.
  final SetLog? heaviestSet;

  /// Record personnel au meilleur 1RM estimé.
  final SetLog? bestOneRepMax;

  const ExerciseProgress({
    required this.sessions,
    required this.heaviestSet,
    required this.bestOneRepMax,
  });

  bool get isEmpty => sessions.isEmpty;

  /// Nombre total de séries enregistrées (toutes séances confondues).
  int get totalSets =>
      sessions.isEmpty ? 0 : sessions.length; // au moins 1 par séance affichée
}

/// Construit la progression d'un exercice à partir de ses séries.
///
/// - Regroupe les séries par jour et retient la meilleure (1RM estimé) de
///   chaque journée pour lisser la courbe.
/// - Détermine les records personnels (charge max et 1RM estimé max).
ExerciseProgress buildExerciseProgress(List<SetLog> logs) {
  if (logs.isEmpty) {
    return const ExerciseProgress(
      sessions: [],
      heaviestSet: null,
      bestOneRepMax: null,
    );
  }

  final byDay = <String, List<SetLog>>{};
  for (final log in logs) {
    final key = log.date.toIso8601String().split('T')[0];
    byDay.putIfAbsent(key, () => []).add(log);
  }

  final sessions = byDay.entries.map((entry) {
    final best = entry.value.reduce(
      (a, b) => a.estimatedOneRepMax >= b.estimatedOneRepMax ? a : b,
    );
    return SessionBest(date: DateTime.parse(entry.key), best: best);
  }).toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  SetLog? heaviest;
  SetLog? bestOrm;
  for (final log in logs) {
    if (heaviest == null || log.weight > heaviest.weight) heaviest = log;
    if (bestOrm == null ||
        log.estimatedOneRepMax > bestOrm.estimatedOneRepMax) {
      bestOrm = log;
    }
  }

  return ExerciseProgress(
    sessions: sessions,
    heaviestSet: heaviest,
    bestOneRepMax: bestOrm,
  );
}
