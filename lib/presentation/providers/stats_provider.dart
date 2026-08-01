import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/workout_stats.dart';
import 'profile_provider.dart';
import 'workout_provider.dart';

// Objectif de séances par semaine dérivé de l'objectif fitness du profil.
// On reste dans la logique de l'app : pas de nouvelle table, on réutilise le profil.
int _weeklyGoalFor(FitnessObjective? objective) {
  switch (objective) {
    case FitnessObjective.gain:
      return 5; // Prise de masse : rythme soutenu
    case FitnessObjective.loss:
      return 4; // Perte de poids : régularité
    case FitnessObjective.maintenance:
      return 3; // Maintien : entretien
    case null:
      return 3; // Valeur par défaut si le profil n'est pas encore chargé
  }
}

// Clé "AAAA-MM-JJ" d'une date, pour comparer les jours sans se soucier de l'heure.
String _dayKey(DateTime date) =>
    DateTime(date.year, date.month, date.day).toIso8601String().split('T')[0];

// Calcule la série de jours consécutifs se terminant aujourd'hui.
// Règle "jour de grâce" : si aucune séance aujourd'hui mais une hier, la série
// reste active (ancrée sur hier). Sinon la série repart de zéro.
int _computeStreak(Set<String> dayKeys, DateTime today) {
  final todayMidnight = DateTime(today.year, today.month, today.day);
  final yesterday = todayMidnight.subtract(const Duration(days: 1));

  DateTime anchor;
  if (dayKeys.contains(_dayKey(todayMidnight))) {
    anchor = todayMidnight;
  } else if (dayKeys.contains(_dayKey(yesterday))) {
    anchor = yesterday;
  } else {
    return 0;
  }

  var streak = 0;
  var cursor = anchor;
  while (dayKeys.contains(_dayKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

/// Fournit les statistiques de motivation affichées sur le tableau de bord.
/// Se recalcule automatiquement quand le profil change ; à invalider après
/// l'enregistrement d'une séance (voir workout_session_screen.dart).
final statsProvider = FutureProvider<WorkoutStats>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  final profile = ref.watch(profileProvider).value;

  final logs = await repository.getAllWorkoutLogs();
  final completed = logs.where((log) => log.isCompleted).toList();

  // Semaine en cours : du lundi au dimanche.
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  final workoutsThisWeek = completed.where((log) {
    final day = DateTime(log.date.year, log.date.month, log.date.day);
    return !day.isBefore(startOfWeek) && !day.isAfter(endOfWeek);
  }).length;

  final dayKeys = completed.map((log) => _dayKey(log.date)).toSet();
  final streak = _computeStreak(dayKeys, now);

  return WorkoutStats(
    currentStreak: streak,
    workoutsThisWeek: workoutsThisWeek,
    weeklyGoal: _weeklyGoalFor(profile?.objective),
    goalLabel: profile?.objective.displayName ?? 'Objectif par défaut',
  );
});
