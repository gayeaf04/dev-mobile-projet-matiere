import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:forge/data/repositories/user_repository.dart';
import 'package:forge/domain/models/user_profile.dart';
import 'package:forge/presentation/providers/profile_provider.dart';
import 'package:forge/presentation/widgets/imc_card.dart';

class _FakeUserRepository extends UserRepository {
  final UserProfile? profile;
  _FakeUserRepository(this.profile);

  @override
  Future<UserProfile?> getProfile() async => profile;
}

UserProfile _profile({required double height, required double weight}) => UserProfile(
      id: 'test',
      name: 'Test',
      age: 30,
      height: height,
      weight: weight,
      objective: FitnessObjective.maintenance,
    );

Future<void> _pumpCard(WidgetTester tester, UserProfile profile) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        userRepositoryProvider.overrideWithValue(_FakeUserRepository(profile)),
      ],
      child: const MaterialApp(home: Scaffold(body: ImcCard())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('IMC normal : 180 cm / 75 kg -> 23.1, corpulence normale',
      (tester) async {
    await _pumpCard(tester, _profile(height: 180, weight: 75));

    expect(find.text('23.1'), findsOneWidget);
    expect(find.text('Corpulence normale'), findsOneWidget);
    expect(find.textContaining('avis médical'), findsOneWidget);
  });

  testWidgets('IMC élevé : 170 cm / 100 kg -> 34.6, obésité', (tester) async {
    await _pumpCard(tester, _profile(height: 170, weight: 100));

    expect(find.text('34.6'), findsOneWidget);
    expect(find.text('Obésité'), findsOneWidget);
  });
}
