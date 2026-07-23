import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/exercise_provider.dart';
import '../../../domain/models/exercise.dart';

// 1. Passage en ConsumerStatefulWidget pour piloter le cycle de vie du contrôleur de texte
class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  // 2. Déclaration du contrôleur pour la barre de recherche
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    // Initialisation du contrôleur
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    // 3. Libération de la mémoire pour éviter les fuites (Memory Leaks)
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 4. On écoute la liste filtrée d'exercices
    final exercisesAsync = ref.watch(filteredExercisesProvider);

    // 5. On écoute le mot-clé actuel pour savoir ce qu'il y a dans la barre de recherche
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque d\'Exercices'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // BARRE DE RECHERCHE
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController, // 6. On lie le contrôleur au TextField
              onChanged: (value) {
                // On met à jour le provider de recherche à chaque lettre tapée
                ref.read(searchQueryProvider.notifier).updateQuery(value);
              },
              decoration: InputDecoration(
                labelText: 'Rechercher un exercice...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    // 7. LA CORRECTION : On force le texte du champ visuel à s'effacer
                    _searchController.clear();
                    // Puis on remet à jour l'état Riverpod pour réinitialiser la liste
                    ref.read(searchQueryProvider.notifier).updateQuery('');
                  },
                )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
              ),
            ),
          ),

          // LISTE DES EXERCICES (Gestion des 3 états de l'enveloppe AsyncValue)
          Expanded(
            child: exercisesAsync.when(
              // ÉTAT A : Chargement (SQLite est en train de lire le disque)
              loading: () => const Center(child: CircularProgressIndicator()),

              // ÉTAT B : Erreur (Un problème est survenu)
              error: (err, stack) => Center(
                child: Text('Erreur lors du chargement : $err'),
              ),

              // ÉTAT C : Données prêtes !
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const Center(
                    child: Text('Aucun exercice ne correspond à ta recherche.'),
                  );
                }

                return ListView.builder(
                  itemCount: exercises.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom : 12.0),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          exercise.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top : 8.0),
                          child: Text(
                            exercise.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: Chip(
                          label: Text(exercise.muscleGroupLabel),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}