/// Un relevé de poids à une date donnée, pour tracer l'évolution du profil
/// dans le temps. Un point par modification de profil (date+heure), pas une
/// seule valeur par jour : ça permet de voir la courbe bouger tout de suite.
class WeightLog {
  final int? id;
  final DateTime date;
  final double weight;

  const WeightLog({this.id, required this.date, required this.weight});

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
      };

  factory WeightLog.fromMap(Map<String, dynamic> map) => WeightLog(
        id: map['id'] as int?,
        date: DateTime.parse(map['date'] as String),
        weight: (map['weight'] as num).toDouble(),
      );
}
