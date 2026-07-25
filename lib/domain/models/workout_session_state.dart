import 'workout.dart';

enum SessionStatus { ready, exercising, resting, completed }

class WorkoutSessionState {
  final Workout workout;
  final int currentExerciseIndex; // Index de l'exercice en cours
  final int currentSetIndex;      // Index de la série en cours (0 pour la 1ère série)
  final SessionStatus status;     // Statut actuel de la séance
  final int remainingRestSeconds; // Temps restant pour le chrono de repos

  const WorkoutSessionState({
    required this.workout,
    this.currentExerciseIndex = 0,
    this.currentSetIndex = 0,
    this.status = SessionStatus.ready,
    this.remainingRestSeconds = 0,
  });

  // Raccourci pour récupérer l'exercice actuel de manière sécurisée
  WorkoutExercise? get currentWorkoutExercise {
    if (currentExerciseIndex < workout.exercises.length) {
      return workout.exercises[currentExerciseIndex];
    }
    return null;
  }

  WorkoutSessionState copyWith({
    Workout? workout,
    int? currentExerciseIndex,
    int? currentSetIndex,
    SessionStatus? status,
    int? remainingRestSeconds,
  }) {
    return WorkoutSessionState(
      workout: workout ?? this.workout,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      currentSetIndex: currentSetIndex ?? this.currentSetIndex,
      status: status ?? this.status,
      remainingRestSeconds: remainingRestSeconds ?? this.remainingRestSeconds,
    );
  }
}