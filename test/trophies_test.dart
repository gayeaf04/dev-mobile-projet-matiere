import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forge/data/repositories/workout_repository.dart';
import 'package:forge/domain/models/workout_log.dart';
import 'package:forge/presentation/providers/workout_provider.dart';
import 'package:forge/presentation/screens/trophies_screen.dart';

class _FakeWorkoutRepository extends WorkoutRepository {
  final List<WorkoutLog> logs;
  _FakeWorkoutRepository(this.logs);

  @override
  Future<List<WorkoutLog>> getAllWorkoutLogs() async => logs;
}

DateTime _dayAgo(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(Duration(days: n));
}

Future<void> _pumpTrophies(WidgetTester tester, List<WorkoutLog> logs) async {
  // Grande surface pour que toutes les cartes de la grille soient rendues
  // (GridView.builder ne construit que les éléments visibles).
  tester.view.physicalSize = const Size(1000, 2200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(_FakeWorkoutRepository(logs)),
      ],
      child: const MaterialApp(home: TrophiesScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('débloque premier pas, assidu et en feu avec 5 jours consécutifs',
      (tester) async {
    // 5 séances validées sur 5 jours consécutifs (aujourd'hui -> J-4).
    final logs = List.generate(
      5,
      (i) => WorkoutLog(
        workoutId: 1,
        workoutName: 'Séance $i',
        date: _dayAgo(i),
        isCompleted: true,
      ),
    );

    await _pumpTrophies(tester, logs);

    // 3 trophées débloqués : Premier pas (1), Assidu (5), En feu (série 3).
    expect(find.text('3 / 7 trophées débloqués'), findsOneWidget);
    expect(find.text('Débloqué'), findsNWidgets(3));
    expect(find.text('En feu'), findsOneWidget);
    // Un palier non atteint doit afficher sa progression (ex: 5/10 pour "Machine").
    expect(find.text('5/10'), findsOneWidget);
  });

  testWidgets('aucun trophée débloqué sans séance validée', (tester) async {
    await _pumpTrophies(tester, [
      WorkoutLog(
        workoutId: 1,
        workoutName: 'Ratée',
        date: _dayAgo(0),
        isCompleted: false,
      ),
    ]);

    expect(find.text('0 / 7 trophées débloqués'), findsOneWidget);
    expect(find.text('Débloqué'), findsNothing);
  });
}
