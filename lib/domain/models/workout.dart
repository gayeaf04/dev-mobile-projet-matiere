import 'exercise.dart';

class WorkoutExercise {
  final String id;
  final String workoutId;
  final Exercise exercise; // L'exercice complet associé
  final int sets;          // Nombre de séries (ex: 4)
  final int reps;          // Nombre de répétitions (ex: 10)
  final int restSeconds;   // Temps de repos en secondes (ex: 90)

  const WorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  // Convertir en Map pour SQLite (attention, on ne stocke que l'ID de l'exercice en clé étrangère)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'workoutId': workoutId,
      'exerciseId': exercise.id,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
    };
  }
}

class Workout {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<WorkoutExercise> exercises; // La liste des exercices configurés dans cette séance

  const Workout({
    required this.id,
    required this.name,
    required this.createdAt,
    this.exercises = const [],
  });

  // Convertir en Map pour SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(), // Stockage de la date au format texte standardisé
    };
  }

  // Permet de cloner facilement une séance en lui ajoutant une liste d'exercices
  Workout copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    List<WorkoutExercise>? exercises,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      exercises: exercises ?? this.exercises,
    );
  }
}