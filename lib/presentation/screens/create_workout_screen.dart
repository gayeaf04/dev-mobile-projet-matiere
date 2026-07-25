import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/exercise_provider.dart';
import '../providers/workout_provider.dart';
import '../../../domain/models/exercise.dart';

class CreateWorkoutScreen extends ConsumerStatefulWidget {
  const CreateWorkoutScreen({super.key});

  @override
  ConsumerState<CreateWorkoutScreen> createState() => _CreateWorkoutScreenState();
}

class _CreateWorkoutScreenState extends ConsumerState<CreateWorkoutScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(workoutCreatorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle Séance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, size: 28),
            onPressed: workout.name.trim().isEmpty || workout.exercises.isEmpty
                ? null
                : () async {
              try {
                await ref.read(workoutCreatorProvider.notifier).saveCurrentWorkout();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Séance enregistrée avec succès !')),
                  );
                  context.pop();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : $e')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. CHAMP NOM DE LA SÉANCE
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              onChanged: (value) => ref.read(workoutCreatorProvider.notifier).updateName(value),
              decoration: const InputDecoration(
                labelText: 'Nom de la séance (ex: Push Day, Leg Day)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
              ),
            ),
          ),

          const Divider(),

          // 2. LISTE DES EXERCICES SÉLECTIONNÉS
          Expanded(
            child: workout.exercises.isEmpty
                ? const Center(
              child: Text(
                'Aucun exercice ajouté.\nAppuie sur le bouton + ci-dessous.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: workout.exercises.length,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemBuilder: (context, index) {
                final workoutExercise = workout.exercises[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // EN-TÊTE : NOM DE L'EXERCICE + BOUTON SUPPRIMER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                workoutExercise.exercise.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                ref.read(workoutCreatorProvider.notifier).removeExercise(workoutExercise.id);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // PREMIÈRE LIGNE DE RÉGLAGES : SÉRIES & REPS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCounter(
                              label: 'Séries',
                              value: workoutExercise.sets,
                              onChanged: (newValue) => ref
                                  .read(workoutCreatorProvider.notifier)
                                  .updateExerciseParameters(workoutExerciseId: workoutExercise.id, sets: newValue),
                            ),
                            _buildCounter(
                              label: 'Reps',
                              value: workoutExercise.reps,
                              onChanged: (newValue) => ref
                                  .read(workoutCreatorProvider.notifier)
                                  .updateExerciseParameters(workoutExerciseId: workoutExercise.id, reps: newValue),
                            ),
                          ],
                        ),

                        const Divider(height: 16, thickness: 0.5),

                        // 🚀 SECONDE LIGNE : COMPTEUR TEMPS DE REPOS EN SECONDES (Paliers de 15s)
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            _buildCounter(
                              label: 'Repos',
                              value: workoutExercise.restSeconds,
                              suffix: 's',
                              step: 15, // On augmente/diminue de 15s à chaque clic
                              onChanged: (newValue) => ref
                                  .read(workoutCreatorProvider.notifier)
                                  .updateExerciseParameters(workoutExerciseId: workoutExercise.id, restSeconds: newValue),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExerciseSelector(context),
        label: const Text('Ajouter un exercice'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  // Widget de compteur universel amélioré avec gestion de paliers (step) et d'un suffixe visuel (ex: 's')
  Widget _buildCounter({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    int step = 1,
    String suffix = '',
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w500)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 20),
          onPressed: value > step ? () => onChanged(value - step) : null,
        ),
        Text('$value$suffix', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: () => onChanged(value + step),
        ),
      ],
    );
  }

  // 🚀 SÉLECTEUR AVEC BARRE DE RECHERCHE LOCALISÉE
  void _showExerciseSelector(BuildContext context) {
    String localSearchQuery = ''; // État de recherche local au BottomSheet

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permet au clavier de ne pas masquer le BottomSheet
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder( // Permet de rafraîchir uniquement l'intérieur du BottomSheet
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, ref, child) {
                final exercisesAsync = ref.watch(filteredExercisesProvider);

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom, // S'adapte à la hauteur du clavier
                  ),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6, // Limite la hauteur à 60% de l'écran
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
                          child: Text('Choisir un exercice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),

                        // 🔍 BARRE DE RECHERCHE DANS LE SELECTEUR
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: TextField(
                            onChanged: (value) {
                              // On met à jour l'état de recherche interne
                              setModalState(() {
                                localSearchQuery = value.toLowerCase();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Rechercher un exercice...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: localSearchQuery.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setModalState(() {
                                    localSearchQuery = '';
                                  });
                                },
                              )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12.0)),
                              ),
                            ),
                          ),
                        ),
                        const Divider(),

                        // LISTE DES EXERCICES FILTRÉE REAGISSANTE
                        Expanded(
                          child: exercisesAsync.when(
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (err, _) => Center(child: Text('Erreur: $err')),
                            data: (exercises) {
                              // On applique le filtre textuel local saisi par l'utilisateur
                              final filteredList = exercises.where((ex) {
                                return ex.name.toLowerCase().contains(localSearchQuery) ||
                                    ex.muscleGroupLabel.toLowerCase().contains(localSearchQuery);
                              }).toList();

                              if (filteredList.isEmpty) {
                                return const Center(
                                  child: Text('Aucun exercice trouvé.', style: TextStyle(color: Colors.grey)),
                                );
                              }

                              return ListView.builder(
                                itemCount: filteredList.length,
                                itemBuilder: (context, index) {
                                  final ex = filteredList[index];
                                  return ListTile(
                                    title: Text(ex.name),
                                    subtitle: Text(ex.muscleGroupLabel),
                                    trailing: const Icon(Icons.add_circle, color: Colors.green),
                                    onTap: () {
                                      ref.read(workoutCreatorProvider.notifier).addExercise(ex);
                                      context.pop();
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}