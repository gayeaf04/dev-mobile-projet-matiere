import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../domain/models/exercise.dart';

// 1. Provider pour le Repository
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository();
});

// 2. Le nouveau filtre de recherche version moderne (Notifier)
// Il gère un simple état String (le mot-clé)
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => ''; // Chaîne vide par défaut

  void updateQuery(String newQuery) {
    state = newQuery; // Met à jour l'enveloppe du mot-clé
  }
}

// Déclaration globale du provider de recherche
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// 3. Provider qui combine tout pour filtrer en temps réel
final filteredExercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);

  // On écoute le mot-clé. Dès qu'il change, ce FutureProvider se relance tout seul !
  final query = ref.watch(searchQueryProvider).toLowerCase();

  // Récupération depuis la base SQLite
  final allExercises = await repository.getAllExercises();

  if (query.isEmpty) {
    return allExercises;
  }

  // Filtrage intelligent
  return allExercises.where((exercise) {
    final matchesName = exercise.name.toLowerCase().contains(query);
    final matchesDescription = exercise.description.toLowerCase().contains(query);
    return matchesName || matchesDescription;
  }).toList();
});