import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forge/domain/models/exercise.dart';
import 'package:forge/domain/models/workout.dart';
import 'package:forge/domain/models/workout_session_state.dart';
import 'package:forge/presentation/providers/workout_session_provider.dart';
import 'package:forge/presentation/services/rest_alert.dart';

/// Service muet : évite les appels natifs (vibration / son) pendant le test.
class _SilentRestAlert extends RestAlert {
  @override
  Future<void> tick() async {}

  @override
  Future<void> restFinished() async {}
}

Workout _workout() {
  const exercise = Exercise(
    id: 'ex_bench_press',
    name: 'Développé Couché',
    description: 'Exercice de test',
    muscleGroup: MuscleGroup.chest,
    equipmentType: EquipmentType.barbell,
  );
  return Workout(
    id: 'w1',
    name: 'Push',
    createdAt: DateTime(2024, 1, 1),
    exercises: [
      WorkoutExercise(
        id: 'we1',
        workoutId: 'w1',
        exercise: exercise,
        sets: 2,
        reps: 10,
        restSeconds: 60,
      ),
    ],
  );
}

void main() {
  test('validateSet enregistre chaque série réalisée (poids × reps)', () {
    final container = ProviderContainer(
      overrides: [restAlertProvider.overrideWithValue(_SilentRestAlert())],
    );
    addTearDown(container.dispose);

    final notifier = container.read(workoutSessionProvider.notifier);
    notifier.initSession(_workout());
    notifier.startSession();

    // Série 1
    notifier.validateSet(weight: 60, reps: 10);
    var state = container.read(workoutSessionProvider)!;
    expect(state.performedSets.length, 1);
    expect(state.performedSets.first.weight, 60);
    expect(state.performedSets.first.reps, 10);
    expect(state.performedSets.first.setNumber, 1);
    expect(state.performedSets.first.exerciseId, 'ex_bench_press');
    expect(state.status, SessionStatus.resting);

    // On saute le repos (annule le timer) puis on valide la dernière série
    notifier.skipRest();
    notifier.validateSet(weight: 62.5, reps: 8);
    state = container.read(workoutSessionProvider)!;
    expect(state.performedSets.length, 2);
    expect(state.performedSets[1].weight, 62.5);
    expect(state.performedSets[1].reps, 8);
    expect(state.performedSets[1].setNumber, 2);
    expect(state.status, SessionStatus.completed);
  });
}
