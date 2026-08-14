import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/exercise_progress.dart';
import '../../domain/models/set_log.dart';
import 'workout_provider.dart';

/// Dernière série enregistrée pour un exercice donné.
///
/// Sert à pré-remplir la charge lors de la séance suivante (surcharge
/// progressive) et à afficher un indice « Dernière fois : X kg × Y ».
final lastPerformanceProvider =
    FutureProvider.family<SetLog?, String>((ref, exerciseId) async {
  final repository = ref.watch(workoutRepositoryProvider);
  return repository.getLastSetLogForExercise(exerciseId);
});

/// Progression agrégée d'un exercice (meilleures séries par séance + records).
final exerciseProgressionProvider =
    FutureProvider.family<ExerciseProgress, String>((ref, exerciseId) async {
  final repository = ref.watch(workoutRepositoryProvider);
  final logs = await repository.getSetLogsForExercise(exerciseId);
  return buildExerciseProgress(logs);
});
