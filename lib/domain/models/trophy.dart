/// Un trophée (badge) débloquable, dérivé de l'historique des séances.
/// Modèle volontairement pur (pas d'import Flutter) : l'icône et les couleurs
/// sont choisies dans la couche présentation. Nommé `Trophy` pour éviter le
/// conflit avec le widget Material `Badge`.
class Trophy {
  final String id;
  final String title;
  final String description;
  final int current; // Valeur actuelle de l'utilisateur (ex: nb de séances, meilleure série)
  final int target;  // Seuil à atteindre pour débloquer le trophée

  const Trophy({
    required this.id,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
  });

  /// Vrai si le trophée est débloqué.
  bool get unlocked => current >= target;

  /// Progression vers le déblocage, bornée entre 0.0 et 1.0.
  double get progress =>
      target <= 0 ? 1.0 : (current / target).clamp(0.0, 1.0);
}
