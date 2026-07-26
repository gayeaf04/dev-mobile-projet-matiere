import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_provider.dart'; // Pour récupérer ton workoutRepositoryProvider
import '../../../domain/models/workout_log.dart';

// Provider qui récupère les logs de la semaine en cours
final weeklyHistoryProvider = FutureProvider<List<WorkoutLog>>((ref) async {
  final repository = ref.watch(workoutRepositoryProvider);

  // On calcule le début (Lundi) et la fin (Dimanche) de la semaine actuelle
  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final endOfWeek = startOfWeek.add(const Duration(days: 6));

  return repository.getWorkoutLogsForRange(startOfWeek, endOfWeek);
});