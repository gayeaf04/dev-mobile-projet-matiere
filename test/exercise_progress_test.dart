import 'package:flutter_test/flutter_test.dart';
import 'package:forge/domain/models/exercise_progress.dart';
import 'package:forge/domain/models/set_log.dart';

SetLog _log({
  required String date,
  required double weight,
  required int reps,
  int setNumber = 1,
}) =>
    SetLog(
      exerciseId: 'ex_bench_press',
      exerciseName: 'Développé Couché',
      setNumber: setNumber,
      weight: weight,
      reps: reps,
      date: DateTime.parse(date),
    );

void main() {
  test('liste vide -> progression vide', () {
    final p = buildExerciseProgress([]);
    expect(p.isEmpty, isTrue);
    expect(p.sessions, isEmpty);
    expect(p.heaviestSet, isNull);
    expect(p.bestOneRepMax, isNull);
  });

  test('regroupe par jour et retient la meilleure série (1RM) du jour', () {
    final logs = [
      _log(date: '2024-01-01', weight: 100, reps: 1), // 1RM 100
      _log(date: '2024-01-01', weight: 80, reps: 10), // 1RM ~106.7 (meilleure)
      _log(date: '2024-01-03', weight: 90, reps: 5), // 1RM 105
    ];

    final p = buildExerciseProgress(logs);

    expect(p.sessions.length, 2);
    // La meilleure série du 1er jour est le 80 kg × 10 (1RM le plus élevé)
    expect(p.sessions.first.best.weight, 80);
    expect(p.sessions.first.best.reps, 10);
  });

  test('les séances sont triées par date croissante', () {
    final logs = [
      _log(date: '2024-01-10', weight: 50, reps: 5),
      _log(date: '2024-01-01', weight: 60, reps: 5),
      _log(date: '2024-01-05', weight: 70, reps: 5),
    ];

    final p = buildExerciseProgress(logs);

    expect(
      p.sessions.map((s) => s.date).toList(),
      [DateTime(2024, 1, 1), DateTime(2024, 1, 5), DateTime(2024, 1, 10)],
    );
  });

  test('records : charge la plus lourde et meilleur 1RM estimé', () {
    final logs = [
      _log(date: '2024-01-01', weight: 120, reps: 1), // charge max, 1RM 120
      _log(date: '2024-01-02', weight: 100, reps: 10), // 1RM ~133 (meilleur)
    ];

    final p = buildExerciseProgress(logs);

    expect(p.heaviestSet!.weight, 120);
    expect(p.bestOneRepMax!.weight, 100);
    expect(p.bestOneRepMax!.reps, 10);
  });
}
