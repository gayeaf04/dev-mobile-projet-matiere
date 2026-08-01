import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forge/domain/models/exercise.dart';
import 'package:forge/domain/models/workout.dart';
import 'package:forge/domain/models/workout_session_state.dart';
import 'package:forge/presentation/providers/workout_session_provider.dart';
import 'package:forge/presentation/services/rest_alert.dart';

/// Faux service qui compte les déclenchements au lieu d'appeler les
/// canaux natifs (vibration / son).
class _FakeRestAlert extends RestAlert {
  int ticks = 0;
  int finished = 0;

  _FakeRestAlert();

  @override
  Future<void> tick() async {
    ticks++;
  }

  @override
  Future<void> restFinished() async {
    finished++;
  }
}

Workout _workout({int restSeconds = 3}) {
  const exercise = Exercise(
    id: 'e1',
    name: 'Développé couché',
    description: 'Exercice de test',
    muscleGroup: MuscleGroup.chest,
    equipmentType: EquipmentType.barbell,
  );
  return Workout(
    id: 'w1',
    name: 'Séance test',
    createdAt: DateTime(2024, 1, 1),
    exercises: [
      WorkoutExercise(
        id: 'we1',
        workoutId: 'w1',
        exercise: exercise,
        sets: 2,
        reps: 10,
        restSeconds: restSeconds,
      ),
    ],
  );
}

void main() {
  test('le repos terminé déclenche vibration + son après le décompte', () {
    fakeAsync((async) {
      final fake = _FakeRestAlert();
      final container = ProviderContainer(
        overrides: [restAlertProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.initSession(_workout(restSeconds: 3));
      notifier.startSession();
      notifier.validateSet(); // -> repos de 3 s avant la série suivante

      expect(
        container.read(workoutSessionProvider)!.status,
        SessionStatus.resting,
      );

      async.elapse(const Duration(seconds: 3));

      final state = container.read(workoutSessionProvider)!;
      expect(state.status, SessionStatus.exercising);
      expect(state.remainingRestSeconds, 0);
      expect(fake.finished, 1); // signal de fin joué une seule fois
      expect(fake.ticks, 2); // tics du décompte à 2 s et 1 s
    });
  });

  test('passer le repos ne déclenche pas le signal de fin', () {
    fakeAsync((async) {
      final fake = _FakeRestAlert();
      final container = ProviderContainer(
        overrides: [restAlertProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(workoutSessionProvider.notifier);
      notifier.initSession(_workout(restSeconds: 3));
      notifier.startSession();
      notifier.validateSet(); // -> repos
      notifier.skipRest(); // l'utilisateur saute le repos

      async.elapse(const Duration(seconds: 5));

      final state = container.read(workoutSessionProvider)!;
      expect(state.status, SessionStatus.exercising);
      expect(fake.finished, 0);
    });
  });
}
