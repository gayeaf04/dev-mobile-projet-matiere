import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/domain/models/trophy.dart';
import 'package:forge/presentation/widgets/trophy_celebration.dart';

void main() {
  testWidgets('la célébration affiche les trophées débloqués puis se ferme',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showTrophyCelebration(context, const [
                Trophy(
                  id: 'first',
                  title: 'Premier pas',
                  description: 'Valide ta toute première séance',
                  current: 1,
                  target: 1,
                ),
              ]),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau trophée débloqué !'), findsOneWidget);
    expect(find.text('Premier pas'), findsOneWidget);

    // Fermeture via le bouton "Génial !"
    await tester.tap(find.text('Génial !'));
    await tester.pumpAndSettle();

    expect(find.text('Nouveau trophée débloqué !'), findsNothing);
  });

  testWidgets('titre au pluriel quand plusieurs trophées', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showTrophyCelebration(context, const [
                Trophy(id: 'first', title: 'Premier pas', description: 'A', current: 1, target: 1),
                Trophy(id: 'five', title: 'Assidu', description: 'B', current: 5, target: 5),
              ]),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Nouveaux trophées débloqués !'), findsOneWidget);
    expect(find.text('Premier pas'), findsOneWidget);
    expect(find.text('Assidu'), findsOneWidget);
  });
}
