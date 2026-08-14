import 'package:flutter_test/flutter_test.dart';
import 'package:forge/domain/models/set_log.dart';

void main() {
  final date = DateTime(2024, 3, 15, 10, 30);

  SetLog make({double weight = 80, int reps = 8}) => SetLog(
        exerciseId: 'ex_bench_press',
        exerciseName: 'Développé Couché',
        setNumber: 1,
        weight: weight,
        reps: reps,
        date: date,
      );

  test('toMap / fromMap : aller-retour fidèle', () {
    final log = SetLog(
      id: 3,
      historyId: 7,
      exerciseId: 'ex_squat',
      exerciseName: 'Squat',
      setNumber: 2,
      weight: 100,
      reps: 5,
      date: date,
    );

    final map = log.toMap();
    expect(map['history_id'], 7);
    expect(map['exercise_id'], 'ex_squat');
    expect(map['exercise_name'], 'Squat');
    expect(map['set_number'], 2);
    expect(map['weight'], 100);
    expect(map['reps'], 5);
    expect(map['date'], '2024-03-15'); // AAAA-MM-JJ

    final back = SetLog.fromMap(map);
    expect(back.id, 3);
    expect(back.historyId, 7);
    expect(back.exerciseId, 'ex_squat');
    expect(back.exerciseName, 'Squat');
    expect(back.setNumber, 2);
    expect(back.weight, 100);
    expect(back.reps, 5);
    expect(back.date, DateTime(2024, 3, 15));
  });

  test('toMap omet la clé id quand elle est nulle', () {
    expect(make().toMap().containsKey('id'), isFalse);
  });

  test('1RM estimé (Epley)', () {
    // reps <= 1 -> la charge elle-même
    expect(make(weight: 100, reps: 1).estimatedOneRepMax, 100);
    expect(make(weight: 100, reps: 0).estimatedOneRepMax, 100);
    // reps > 1 -> poids * (1 + reps/30)
    expect(
      make(weight: 100, reps: 10).estimatedOneRepMax,
      closeTo(100 * (1 + 10 / 30), 0.0001),
    );
  });

  test('volume = poids × répétitions', () {
    expect(make(weight: 80, reps: 8).volume, 640);
  });

  test('copyWith met à jour id et historyId sans toucher au reste', () {
    final log = make();
    final copy = log.copyWith(id: 5, historyId: 9);
    expect(copy.id, 5);
    expect(copy.historyId, 9);
    expect(copy.weight, log.weight);
    expect(copy.reps, log.reps);
    expect(copy.exerciseId, log.exerciseId);
    expect(copy.setNumber, log.setNumber);
    expect(copy.date, log.date);
  });
}
