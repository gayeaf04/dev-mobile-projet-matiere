import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:forge/domain/models/exercise.dart';
import 'package:forge/domain/models/exercise_progress.dart';
import 'package:forge/domain/models/set_log.dart';
import 'package:forge/presentation/providers/progression_provider.dart';
import 'package:forge/presentation/screens/exercise_detail_screen.dart';

const _exercise = Exercise(
  id: 'ex_bench_press',
  name: 'Développé Couché',
  description: 'Exercice de test',
  muscleGroup: MuscleGroup.chest,
  equipmentType: EquipmentType.barbell,
);

SetLog _log(String date, double weight, int reps) => SetLog(
      exerciseId: _exercise.id,
      exerciseName: _exercise.name,
      setNumber: 1,
      weight: weight,
      reps: reps,
      date: DateTime.parse(date),
    );

Widget _wrap(ExerciseProgress progress) {
  return ProviderScope(
    overrides: [
      exerciseProgressionProvider(_exercise.id)
          .overrideWith((ref) async => progress),
      lastPerformanceProvider(_exercise.id).overrideWith((ref) async => null),
    ],
    child: const MaterialApp(
      home: ExerciseDetailScreen(exercise: _exercise),
    ),
  );
}

void main() {
  testWidgets('affiche la courbe et les records avec plusieurs séances',
      (tester) async {
    final progress = buildExerciseProgress([
      _log('2024-01-01', 80, 8),
      _log('2024-01-08', 82.5, 8),
      _log('2024-01-15', 85, 6),
    ]);

    await tester.pumpWidget(_wrap(progress));
    await tester.pump(); // résolution du FutureProvider
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Ta progression'), findsOneWidget);
    expect(find.text('Charge max'), findsOneWidget);
    expect(find.text('1RM estimé'), findsOneWidget);
  });

  testWidgets('message d\'invite quand aucune donnée', (tester) async {
    await tester.pumpWidget(_wrap(buildExerciseProgress([])));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LineChart), findsNothing);
    expect(find.textContaining('Aucune donnée'), findsOneWidget);
  });
}
