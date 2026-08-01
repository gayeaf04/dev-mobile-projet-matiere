import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forge/data/repositories/user_repository.dart';
import 'package:forge/data/repositories/workout_repository.dart';
import 'package:forge/domain/models/user_profile.dart';
import 'package:forge/domain/models/workout_log.dart';
import 'package:forge/domain/models/workout_stats.dart';
import 'package:forge/presentation/providers/profile_provider.dart';
import 'package:forge/presentation/providers/stats_provider.dart';
import 'package:forge/presentation/providers/workout_provider.dart';
import 'package:forge/presentation/widgets/motivation_banner.dart';

class _FakeWorkoutRepository extends WorkoutRepository {
  final List<WorkoutLog> logs;
  _FakeWorkoutRepository(this.logs);

  @override
  Future<List<WorkoutLog>> getAllWorkoutLogs() async => logs;
}

class _FakeUserRepository extends UserRepository {
  final UserProfile? profile;
  _FakeUserRepository(this.profile);

  @override
  Future<UserProfile?> getProfile() async => profile;
}

UserProfile _profileWith(FitnessObjective objective) => UserProfile(
      id: 'test',
      name: 'Test',
      age: 25,
      height: 180,
      weight: 75,
      objective: objective,
    );

// Pompe le vrai bandeau branché sur le vrai statsProvider, avec des
// repositories simulés (aucun accès SQLite).
Future<void> _pumpBanner(
  WidgetTester tester, {
  required List<WorkoutLog> logs,
  required UserProfile profile,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(_FakeWorkoutRepository(logs)),
        userRepositoryProvider.overrideWithValue(_FakeUserRepository(profile)),
      ],
      child: const MaterialApp(home: Scaffold(body: MotivationBanner())),
    ),
  );
  await tester.pumpAndSettle();
}

DateTime _dayAgo(int n) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(Duration(days: n));
}

void main() {
  testWidgets('série de 3 jours consécutifs + objectif maintien (3 séances)',
      (tester) async {
    await _pumpBanner(
      tester,
      logs: [
        WorkoutLog(workoutId: 1, workoutName: 'A', date: _dayAgo(0), isCompleted: true),
        WorkoutLog(workoutId: 1, workoutName: 'B', date: _dayAgo(1), isCompleted: true),
        WorkoutLog(workoutId: 1, workoutName: 'C', date: _dayAgo(2), isCompleted: true),
        // Séance non validée : ne doit pas compter dans la série.
        WorkoutLog(workoutId: 1, workoutName: 'X', date: _dayAgo(3), isCompleted: false),
      ],
      profile: _profileWith(FitnessObjective.maintenance),
    );

    expect(find.text('3 jours d\'affilée'), findsOneWidget);
    expect(find.textContaining('/3 séances'), findsOneWidget); // objectif "maintien"
    expect(find.textContaining('Maintien'), findsOneWidget);
  });

  testWidgets('aucune série récente + objectif prise de masse (5 séances)',
      (tester) async {
    await _pumpBanner(
      tester,
      logs: [
        WorkoutLog(workoutId: 1, workoutName: 'Vieux', date: _dayAgo(5), isCompleted: true),
      ],
      profile: _profileWith(FitnessObjective.gain),
    );

    expect(find.text('Aucune série en cours'), findsOneWidget);
    expect(find.textContaining('/5 séances'), findsOneWidget); // objectif "prise de masse"
  });

  testWidgets('affichage direct via un WorkoutStats fourni', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsProvider.overrideWith(
            (ref) => Future<WorkoutStats>.value(const WorkoutStats(
              currentStreak: 3,
              workoutsThisWeek: 2,
              weeklyGoal: 5,
              goalLabel: 'Prise de masse',
            )),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: MotivationBanner())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('3 jours d\'affilée'), findsOneWidget);
    expect(find.text('2/5 séances'), findsOneWidget);
    expect(find.textContaining('Prise de masse'), findsOneWidget);
  });
}
