import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:forge/domain/models/exercise.dart';
import 'package:forge/presentation/widgets/exercise_image.dart';

const _base =
    'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises';

Exercise _ex(String id, {MuscleGroup group = MuscleGroup.chest}) => Exercise(
      id: id,
      name: 'Test',
      description: 'desc',
      muscleGroup: group,
      equipmentType: EquipmentType.bodyweight,
    );

void main() {
  group('URLs des images d\'exercices', () {
    test('un exercice connu renvoie ses 2 positions (départ + arrivée)', () {
      expect(exerciseImageUrls('ex_pushups'), [
        '$_base/Pushups/0.jpg',
        '$_base/Pushups/1.jpg',
      ]);
    });

    test('la miniature correspond à la première image', () {
      expect(exerciseThumbnailUrl('ex_squat'), '$_base/Barbell_Squat/0.jpg');
    });

    test('un exercice inconnu ne renvoie aucune image', () {
      expect(exerciseImageUrls('exercice_inexistant'), isEmpty);
      expect(exerciseThumbnailUrl('exercice_inexistant'), isNull);
    });

    test('les 15 exercices du catalogue ont chacun 2 images', () {
      expect(kExerciseImageSlugs.length, 15);
      for (final id in kExerciseImageSlugs.keys) {
        expect(exerciseImageUrls(id).length, 2, reason: id);
      }
    });
  });

  testWidgets('ExerciseThumbnail connu -> Image réseau avec la bonne URL',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseThumbnail(exercise: _ex('ex_plank', group: MuscleGroup.core)),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, '$_base/Plank/0.jpg');

    await tester.pumpAndSettle();
  });

  testWidgets('ExerciseThumbnail inconnu -> icône de repli, sans image réseau',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExerciseThumbnail(exercise: _ex('inconnu', group: MuscleGroup.core)),
        ),
      ),
    );

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(Icons.self_improvement), findsOneWidget);
  });
}
