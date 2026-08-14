import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forge/data/repositories/user_repository.dart';
import 'package:forge/data/repositories/workout_repository.dart';
import 'package:forge/domain/models/user_profile.dart';
import 'package:forge/domain/models/workout.dart';
import 'package:forge/domain/models/workout_log.dart';
import 'package:forge/main.dart';
import 'package:forge/presentation/providers/profile_provider.dart';
import 'package:forge/presentation/providers/workout_provider.dart';

class _FakeUserRepository extends UserRepository {
  final UserProfile? profile;
  _FakeUserRepository(this.profile);

  @override
  Future<UserProfile?> getProfile() async => profile;
}

class _FakeWorkoutRepository extends WorkoutRepository {
  @override
  Future<List<Workout>> getAllWorkouts() async => [];

  @override
  Future<List<WorkoutLog>> getAllWorkoutLogs() async => [];
}

Future<void> _pumpApp(WidgetTester tester, UserProfile? profile) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(_FakeUserRepository(profile)),
        workoutRepositoryProvider.overrideWithValue(_FakeWorkoutRepository()),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans profil enregistré, l\'app force la création du profil',
      (tester) async {
    await _pumpApp(tester, null);

    expect(find.text('Créer mon Profil Forge'), findsOneWidget);
    expect(find.text('Forger mon profil'), findsOneWidget);
  });

  testWidgets(
      'avec un profil existant, l\'app affiche le tableau de bord et les 5 onglets',
      (tester) async {
    await _pumpApp(
      tester,
      const UserProfile(
        id: 'test',
        name: 'Test',
        age: 30,
        height: 180,
        weight: 75,
        objective: FitnessObjective.maintenance,
      ),
    );

    expect(find.text('Forge - Entraînements'), findsOneWidget);
    expect(find.text('Mes Séances'), findsOneWidget);
    expect(find.text('Exercices'), findsOneWidget);
    expect(find.text('Suivi'), findsOneWidget);
    expect(find.text('Trophées'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
  });
}
