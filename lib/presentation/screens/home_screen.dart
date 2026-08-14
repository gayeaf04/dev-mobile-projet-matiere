import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forge/presentation/screens/historyCalendarScreen.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../providers/workout_provider.dart';
import 'exercise_list_screen.dart'; // Vu qu'ils sont dans le même dossier
import 'profile_setup_screen.dart';
import '../widgets/motivation_banner.dart';
import 'trophies_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Liste des onglets principaux
  final List<Widget> _tabs = [
    const _WorkoutDashboardTab(),
    const ExerciseListScreen(),
    const HistoryCalendarScreen(),
    const TrophiesScreen(),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month), // <-- Icône calendrier
            label: 'Suivi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Trophées',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
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
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: MotivationBanner(),
          ),
          Expanded(
            child: workoutsAsync.when(
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
                        children: [
                          // 1. Les trois petits points (...) permettent d'étaler les exercices dans la liste
                          ...workout.exercises.map((we) {
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
                          }),

                          // 2. Maintenant, l'espacement et le bouton font partie intégrante de la même liste !
                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('DÉMARRER LA SÉANCE', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                // On navigue vers la session en envoyant la séance complète dans l'extra !
                                context.push('/session', extra: workout);
                              },
                            ),
                          ),
                        ], // <-- Fermeture des crochets de la Column !
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
            ),
          ),
        ],
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

// --- ONGLET PROFIL : affiche le formulaire de modification pré-rempli ---
class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('Erreur lors du chargement du profil : $err')),
      ),
      // Le redirect de app_router garantit qu'on a déjà un profil ici.
      data: (profile) => ProfileSetupScreen(existingProfile: profile),
    );
  }
}