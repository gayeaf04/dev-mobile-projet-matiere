/// Performance enregistrée pour une série d'un exercice pendant une séance.
///
/// C'est la brique qui permet le suivi de la progression (surcharge
/// progressive) : on mémorise le poids soulevé et le nombre de répétitions
/// réellement effectuées, série par série.
class SetLog {
  final int? id;
  final int? historyId; // Réf. vers workout_history.id (la séance)
  final String exerciseId; // Réf. vers exercises.id
  final String exerciseName;
  final int setNumber; // Numéro de la série (1 = première série)
  final double weight; // Charge en kg
  final int reps; // Répétitions effectuées
  final DateTime date;

  const SetLog({
    this.id,
    this.historyId,
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.weight,
    required this.reps,
    required this.date,
  });

  /// 1RM estimé (charge maximale théorique sur 1 répétition) via la formule
  /// d'Epley : `poids × (1 + reps/30)`. Sert d'indicateur de force comparable
  /// entre des séries de reps différentes.
  double get estimatedOneRepMax =>
      reps <= 1 ? weight : weight * (1 + reps / 30.0);

  /// Volume de la série (tonnage) = poids × répétitions.
  double get volume => weight * reps;

  SetLog copyWith({int? id, int? historyId}) => SetLog(
        id: id ?? this.id,
        historyId: historyId ?? this.historyId,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        setNumber: setNumber,
        weight: weight,
        reps: reps,
        date: date,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'history_id': historyId,
        'exercise_id': exerciseId,
        'exercise_name': exerciseName,
        'set_number': setNumber,
        'weight': weight,
        'reps': reps,
        // Date au format AAAA-MM-JJ (cohérent avec workout_history)
        'date': date.toIso8601String().split('T')[0],
      };

  factory SetLog.fromMap(Map<String, dynamic> map) => SetLog(
        id: map['id'] as int?,
        historyId: map['history_id'] as int?,
        exerciseId: map['exercise_id'] as String,
        exerciseName: map['exercise_name'] as String,
        setNumber: map['set_number'] as int,
        weight: (map['weight'] as num).toDouble(),
        reps: map['reps'] as int,
        date: DateTime.parse(map['date'] as String),
      );
}
