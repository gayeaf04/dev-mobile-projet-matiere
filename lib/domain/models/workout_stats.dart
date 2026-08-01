/// Statistiques de motivation calculées à partir de l'historique des séances.
/// Ce modèle n'est pas persisté : il est dérivé à la volée depuis 'workout_history'
/// et le profil de l'utilisateur (pour l'objectif hebdomadaire).
class WorkoutStats {
  final int currentStreak;    // Nombre de jours consécutifs avec au moins une séance 🔥
  final int workoutsThisWeek; // Séances validées durant la semaine en cours (Lun -> Dim)
  final int weeklyGoal;       // Objectif de séances par semaine (dérivé de l'objectif du profil)
  final String goalLabel;     // Libellé lisible de l'objectif (ex: "Prise de masse")

  const WorkoutStats({
    required this.currentStreak,
    required this.workoutsThisWeek,
    required this.weeklyGoal,
    required this.goalLabel,
  });

  /// Progression vers l'objectif hebdomadaire, bornée entre 0.0 et 1.0.
  double get goalProgress =>
      weeklyGoal <= 0 ? 0.0 : (workoutsThisWeek / weeklyGoal).clamp(0.0, 1.0);

  /// Vrai si l'objectif de la semaine est atteint.
  bool get goalReached => weeklyGoal > 0 && workoutsThisWeek >= weeklyGoal;

  /// Nombre de séances restantes avant d'atteindre l'objectif (jamais négatif).
  int get remainingForGoal {
    final remaining = weeklyGoal - workoutsThisWeek;
    return remaining < 0 ? 0 : remaining;
  }
}
