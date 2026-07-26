import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/workout.dart';
import '../../domain/models/workout_session_state.dart';

// 🚀 La classe hérite simplement de Notifier<State> avec le type d'argument précisé dans le Provider
class WorkoutSessionNotifier extends Notifier<WorkoutSessionState?> {
  Timer? _timer;

  @override
  WorkoutSessionState? build() {
    // 💡 Avec Riverpod, si tu déclares un NotifierProvider.family,
    // l'argument passé est automatiquement accessible via "this.arg" !
    // Mais attention, pour que "this.arg" soit généré proprement sans build_runner,
    // on va plutôt stocker l'argument à l'initialisation ou le gérer à la racine.

    ref.onDispose(() {
      _cancelTimer();
    });

    return null;
  }

  // Initialise l'état avec la séance sélectionnée
  void initSession(Workout workout) {
    state = WorkoutSessionState(workout: workout);
  }

  // Débuter officiellement la séance
  void startSession() {
    if (state == null) return;
    state = state!.copyWith(status: SessionStatus.exercising);
  }

  // Valider une série (clic sur le bouton "Série validée")
  void validateSet() {
    final currentState = state;
    if (currentState == null || currentState.currentWorkoutExercise == null) return;

    final currentExercise = currentState.currentWorkoutExercise!;

    // Étape A : Est-ce qu'il reste des séries dans l'exercice actuel ?
    if (currentState.currentSetIndex + 1 < currentExercise.sets) {
      // Oui -> On lance le chrono de repos pour la série suivante
      _startRestTimeout(currentExercise.restSeconds, currentState.currentSetIndex + 1, currentState.currentExerciseIndex);
    } else {
      // Non -> On a fini toutes les séries de cet exercice. Reste-t-il un autre exercice ?
      if (currentState.currentExerciseIndex + 1 < currentState.workout.exercises.length) {
        // Oui -> On passe à l'exercice suivant
        _startRestTimeout(currentExercise.restSeconds, 0, currentState.currentExerciseIndex + 1);
      } else {
        // Non -> L'entraînement complet est fini !
        _cancelTimer();
        state = currentState.copyWith(status: SessionStatus.completed);
      }
    }
  }

  // Lancement du compte à rebours
  void _startRestTimeout(int seconds, int nextSet, int nextExercise) {
    _cancelTimer();
    if (state == null) return;

    state = state!.copyWith(
      status: SessionStatus.resting,
      remainingRestSeconds: seconds,
      currentSetIndex: nextSet,
      currentExerciseIndex: nextExercise,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == null) {
        timer.cancel();
        return;
      }

      final remaining = state!.remainingRestSeconds;
      if (remaining > 1) {
        state = state!.copyWith(remainingRestSeconds: remaining - 1);
      } else {
        // Le chrono est arrivé à zéro -> On remet l'utilisateur au travail !
        timer.cancel();
        state = state!.copyWith(
          status: SessionStatus.exercising,
          remainingRestSeconds: 0,
        );
      }
    });
  }

  // Permet de passer manuellement le temps de repos si l'utilisateur est prêt avant
  void skipRest() {
    _cancelTimer();
    if (state == null) return;
    state = state!.copyWith(
      status: SessionStatus.exercising,
      remainingRestSeconds: 0,
    );
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // Nettoyage automatique si l'utilisateur quitte l'écran
  void disposeSession() {
    _cancelTimer();
    state = null;
  }
}

// 🚀 Déclaration simplifiée et robuste du Provider global
final workoutSessionProvider = NotifierProvider<WorkoutSessionNotifier, WorkoutSessionState?>(() {
  return WorkoutSessionNotifier();
});