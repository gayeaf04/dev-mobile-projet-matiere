class WorkoutLog {
  final int? id;
  final int workoutId;
  final String workoutName;
  final DateTime date;
  final bool isCompleted; // true = fait, false = planifié mais raté

  const WorkoutLog({
    this.id,
    required this.workoutId,
    required this.workoutName,
    required this.date,
    required this.isCompleted,
  });

  // Pour l'insertion en base SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'workout_id': workoutId,
      'workout_name': workoutName,
      // On stocke la date au format ISO (AAAA-MM-JJ) pour faciliter les filtres
      'date': date.toIso8601String().split('T')[0],
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  // Pour la lecture depuis la base SQLite
  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    return WorkoutLog(
      id: map['id'] as int?,
      workoutId: map['workout_id'] as int,
      workoutName: map['workout_name'] as String,
      date: DateTime.parse(map['date'] as String),
      isCompleted: (map['is_completed'] as int) == 1,
    );
  }
}