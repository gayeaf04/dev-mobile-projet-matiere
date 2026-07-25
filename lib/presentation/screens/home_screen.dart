import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/workout_provider.dart';
import 'exercise_list_screen.dart'; // Vu qu'ils sont dans le même dossier

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Liste des deux onglets principaux
  final List<Widget> _tabs = [
    const _WorkoutDashboardTab(),
    const ExerciseListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Mes Séances',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Exercices',
          ),
        ],
      ),
    );
  }
}

// --- ONGLET 1 : TABLEAU DE BORD DES SÉANCES ---
class _WorkoutDashboardTab extends ConsumerWidget {
  const _WorkoutDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On écoute la liste des séances lues depuis SQLite
    final workoutsAsync = ref.watch(workoutListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forge - Entraînements'),
        centerTitle: true,
      ),
      body: workoutsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (workouts) {
          if (workouts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Aucune séance programmée.\nCrée ta première routine avec le bouton + !',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: workouts.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return Card(
                margin: const EdgeInsets.only(bottom : 16.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                child: ExpansionTile(
                  title: Text(
                    workout.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text('${workout.exercises.length} exercice(s) configuré(s)'),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.calendar_today, size: 20, color: Theme.of(context).colorScheme.primary),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                    onPressed: () async {
                      // Optionnel : ajouter une boîte de dialogue de confirmation
                      await ref.read(workoutRepositoryProvider).deleteWorkout(workout.id);
                      ref.invalidate(workoutListProvider);
                    },
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                      child: Column(
                        children: workout.exercises.map((we) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  we.exercise.name,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${we.sets}x${we.reps} • ${we.restSeconds}s',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation vers l'écran de création
          context.push('/create-workout');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}