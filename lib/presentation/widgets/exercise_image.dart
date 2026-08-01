import 'package:flutter/material.dart';
import '../../domain/models/exercise.dart';

const String _imageBase =
    'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises';

/// Slug free-exercise-db (banque d'images de démonstration libres) associé à
/// chaque exercice du catalogue, indexé par son id stable.
const Map<String, String> kExerciseImageSlugs = {
  'ex_bench_press': 'Barbell_Bench_Press_-_Medium_Grip',
  'ex_incline_dumbbell_press': 'Incline_Dumbbell_Press',
  'ex_pushups': 'Pushups',
  'ex_pullups': 'Pullups',
  'ex_barbell_row': 'Bent_Over_Barbell_Row',
  'ex_lat_pulldown': 'Wide-Grip_Lat_Pulldown',
  'ex_squat': 'Barbell_Squat',
  'ex_romanian_deadlift': 'Romanian_Deadlift',
  'ex_leg_press': 'Leg_Press',
  'ex_overhead_press': 'Standing_Military_Press',
  'ex_lateral_raises': 'Side_Lateral_Raise',
  'ex_bicep_curl': 'Dumbbell_Bicep_Curl',
  'ex_tricep_pushdown': 'Triceps_Pushdown_-_Rope_Attachment',
  'ex_plank': 'Plank',
  'ex_hanging_leg_raises': 'Hanging_Leg_Raise',
};

/// URLs de démonstration d'un exercice : `[0]` = position de départ,
/// `[1]` = position finale. Liste vide si aucune image n'est connue.
List<String> exerciseImageUrls(String exerciseId) {
  final slug = kExerciseImageSlugs[exerciseId];
  if (slug == null) return const [];
  return ['$_imageBase/$slug/0.jpg', '$_imageBase/$slug/1.jpg'];
}

/// URL de la miniature (première image) ou `null` si l'exercice est inconnu.
String? exerciseThumbnailUrl(String exerciseId) {
  final urls = exerciseImageUrls(exerciseId);
  return urls.isEmpty ? null : urls.first;
}

IconData _iconForMuscle(MuscleGroup group) {
  switch (group) {
    case MuscleGroup.core:
      return Icons.self_improvement;
    case MuscleGroup.legs:
      return Icons.directions_run;
    default:
      return Icons.fitness_center;
  }
}

/// Petite vignette carrée d'un exercice, utilisée dans les listes.
///
/// Charge l'image depuis Internet et retombe proprement sur une icône du
/// groupe musculaire si l'URL est inconnue ou si le chargement échoue
/// (l'appli reste utilisable hors-ligne).
class ExerciseThumbnail extends StatelessWidget {
  final Exercise exercise;
  final double size;

  const ExerciseThumbnail({super.key, required this.exercise, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final url = exerciseThumbnailUrl(exercise.id);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? _fallback(context)
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _loading(),
                errorBuilder: (context, error, stackTrace) => _fallback(context),
              ),
      ),
    );
  }

  Widget _loading() => Container(color: Colors.grey.shade100);

  Widget _fallback(BuildContext context) => Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          _iconForMuscle(exercise.muscleGroup),
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}

/// Démonstration du mouvement affichée pendant la séance : la position de
/// départ et la position finale côte à côte, pour montrer comment exécuter
/// l'exercice.
class ExerciseDemo extends StatelessWidget {
  final Exercise exercise;
  final double height;

  const ExerciseDemo({super.key, required this.exercise, this.height = 150});

  @override
  Widget build(BuildContext context) {
    final urls = exerciseImageUrls(exercise.id);
    if (urls.isEmpty) {
      return SizedBox(height: height, child: _fallback(context));
    }
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(child: _position(context, urls[0], 'Départ')),
          const SizedBox(width: 8),
          Expanded(child: _position(context, urls[1], 'Position finale')),
        ],
      ),
    );
  }

  Widget _position(BuildContext context, String url, String label) {
    return Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _loading(),
                errorBuilder: (context, error, stackTrace) => _fallback(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _loading() => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _fallback(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _iconForMuscle(exercise.muscleGroup),
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
}
