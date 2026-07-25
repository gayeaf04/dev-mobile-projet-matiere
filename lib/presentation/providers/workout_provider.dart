import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart'; // Pour générer des IDs uniques facilement
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/workout.dart';

// 1. Provider pour le Repository des séances
final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository();
});

// 2. Provider pour l'affichage de la liste globale des séances enregistrées
// Il se rafraîchit automatiquement quand on ajoute ou supprime une séance
final workoutListProvider = FutureProvider<List<Workout>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.getAllWorkouts();
});

// 3. Le Notifier qui gère la création de la séance en cours (en mémoire)
class WorkoutCreatorNotifier extends Notifier<Workout> {
  @override
  Workout build() {
    // On initialise une séance vide avec un ID unique temporaire
    return Workout(
      id: const Uuid().v4(),
      name: '',
      createdAt: DateTime.now(),
      exercises: const [],
    );
  }

  // Mettre à jour le nom de la séance
  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  // Ajouter un exercice depuis le catalogue avec des valeurs par défaut
  void addExercise(Exercise exercise) {
    final newWorkoutExercise = WorkoutExercise(
      id: const Uuid().v4(),
      workoutId: state.id,
      exercise: exercise,
      sets: 4,          // Valeur standard par défaut
      reps: 10,         // Valeur standard par défaut
      restSeconds: 90,  // 1min30 de repos par défaut
    );

    // On recrée la liste en y ajoutant le nouvel exercice
    final updatedExercises = [...state.exercises, newWorkoutExercise];
    state = state.copyWith(exercises: updatedExercises);
  }

  // Modifier les paramètres d'un exercice déjà présent dans la liste
  void updateExerciseParameters({
    required String workoutExerciseId,
    int? sets,
    int? reps,
    int? restSeconds,
  }) {
    final updatedExercises = state.exercises.map((we) {
      if (we.id == workoutExerciseId) {
        return WorkoutExercise(
          id: we.id,
          workoutId: we.workoutId,
          exercise: we.exercise,
          sets: sets ?? we.sets,
          reps: reps ?? we.reps,
          restSeconds: restSeconds ?? we.restSeconds,
        );
      }
      return we;
    }).toList();

    state = state.copyWith(exercises: updatedExercises);
  }

  // Supprimer un exercice de la séance en cours de création
  void removeExercise(String workoutExerciseId) {
    final updatedExercises = state.exercises
        .where((we) => we.id != workoutExerciseId)
        .toList();
    state = state.copyWith(exercises: updatedExercises);
  }

  // 💾 SAUVEGARDE EN BASE DE DONNÉES SQLite
  Future<void> saveCurrentWorkout() async {
    if (state.name.trim().isEmpty) {
      throw Exception("La séance doit avoir un nom valide.");
    }

    final repository = ref.read(workoutRepositoryProvider);

    // On sauvegarde l'état actuel
    await repository.saveWorkout(state);

    // On force le rafraîchissement de la liste globale des séances
    ref.invalidate(workoutListProvider);

    // On réinitialise l'outil de création pour la prochaine séance
    reset();
  }

  // Réinitialiser le créateur
  void reset() {
    state = Workout(
      id: const Uuid().v4(),
      name: '',
      createdAt: DateTime.now(),
      exercises: const [],
    );
  }
}

// Provider global pour manipuler le créateur de séance depuis nos écrans
final workoutCreatorProvider = NotifierProvider<WorkoutCreatorNotifier, Workout>(() {
  return WorkoutCreatorNotifier();
});