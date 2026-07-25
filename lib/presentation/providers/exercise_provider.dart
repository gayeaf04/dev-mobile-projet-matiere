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
  final query = ref.watch(searchQueryProvider).toLowerCase();

  // 🚀 On écoute en plus le groupe musculaire sélectionné
  final selectedMuscle = ref.watch(selectedMuscleProvider);

  // Récupération globale
  var exercises = await repository.getAllExercises();

  // 1. Filtrage par groupe musculaire (si sélectionné)
  if (selectedMuscle != null) {
    exercises = exercises.where((ex) => ex.muscleGroup == selectedMuscle).toList();
  }

  // 2. Filtrage par mot-clé (si texte saisi)
  if (query.isNotEmpty) {
    exercises = exercises.where((ex) =>
    ex.name.toLowerCase().contains(query) ||
        ex.description.toLowerCase().contains(query)
    ).toList();
  }

  return exercises;
});

// Filtrage par groupe musculaire
// Provider pour stocker le groupe musculaire sélectionné (null = aucun filtre, on affiche tout)
class SelectedMuscleNotifier extends Notifier<MuscleGroup?> {
  @override
  MuscleGroup? build() => null; // Aucun filtre par défaut

  void toggleMuscleGroup(MuscleGroup group) {
    if (state == group) {
      state = null; // Si on clique sur le même groupe, on désactive le filtre
    } else {
      state = group; // Sinon on applique le nouveau filtre
    }
  }

  void clearFilter() => state = null;
}

final selectedMuscleProvider = NotifierProvider<SelectedMuscleNotifier, MuscleGroup?>(() {
  return SelectedMuscleNotifier();
});