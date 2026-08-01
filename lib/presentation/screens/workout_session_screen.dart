import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/workout.dart';
import '../../domain/models/workout_log.dart';
import '../../domain/models/workout_session_state.dart';
import '../providers/history_provider.dart';
import '../providers/workout_provider.dart';
import '../providers/workout_session_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/trophies_provider.dart';
import '../widgets/trophy_celebration.dart';
import '../widgets/exercise_image.dart';

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final Workout workout;

  const WorkoutSessionScreen({super.key, required this.workout});

  @override
  ConsumerState<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  @override
  void initState() {
    super.initState();
    // ⚡ On initialise les données de la séance dès l'ouverture de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(workoutSessionProvider.notifier).initSession(widget.workout);
    });
  }

  @override
  void dispose() {
    // 🧼 On nettoie le timer si l'utilisateur quitte brusquement l'écran
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(workoutSessionProvider);

    // Sécurité le temps que l'initSession s'exécute au premier frame
    if (sessionState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Demande de confirmation pour quitter l'entraînement
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Quitter l\'entraînement ?'),
                content: const Text('Ta progression sur cette séance sera perdue.'),
                actions: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Annuler'),
                  ),
                  TextButton(
                    onPressed: () {
                      context.pop(); // Ferme le dialog
                      context.pop(); // Quitte l'écran de session
                    },
                    child: const Text('Quitter', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildContentByStatus(context, ref, sessionState),
      ),
    );
  }

  // --- ROUTAGE DES ÉCRANS EN FONCTION DU STATUT DE LA SÉANCE ---
  Widget _buildContentByStatus(BuildContext context, WidgetRef ref, WorkoutSessionState session) {
    switch (session.status) {
      case SessionStatus.ready:
        return _buildReadyScreen(ref);
      case SessionStatus.exercising:
        return _buildExercisingScreen(ref, session);
      case SessionStatus.resting:
        return _buildRestingScreen(ref, session);
      case SessionStatus.completed:
        return _buildCompletedScreen(context);
    }
  }

  // 1️⃣ ÉCRAN DE DÉPART (READY)
  Widget _buildReadyScreen(WidgetRef ref) {
    return Center(
      key: const ValueKey('ready'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, size: 100, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 24),
            const Text(
              'Prêt pour l\'entraînement ?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.workout.exercises.length} exercices programmés. Prépare ton matériel !',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              onPressed: () => ref.read(workoutSessionProvider.notifier).startSession(),
              icon: const Icon(Icons.bolt),
              label: const Text('C\'EST PARTI !'),
            ),
          ],
        ),
      ),
    );
  }

  // 2️⃣ ÉCRAN DE TRAVAIL (EXERCISING)
  Widget _buildExercisingScreen(WidgetRef ref, WorkoutSessionState session) {
    final currentWorkoutExercise = session.currentWorkoutExercise!;
    final exercise = currentWorkoutExercise.exercise;

    return Padding(
      key: const ValueKey('exercising'),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barre de progression des exercices
                  LinearProgressIndicator(
                    value: (session.currentExerciseIndex) /
                        widget.workout.exercises.length,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Exercice ${session.currentExerciseIndex + 1} sur ${widget.workout.exercises.length}',
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  // Carte Focus Exercice
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                            exercise.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(exercise.muscleGroupLabel),
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                          ),
                          const SizedBox(height: 16),

                          // 🖼️ Démonstration du mouvement (départ → arrivée)
                          ExerciseDemo(exercise: exercise),
                          const SizedBox(height: 16),

                          Text(
                            exercise.description,
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: Colors.grey[700], fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Indicateur des Séries
                  Center(
                    child: Column(
                      children: [
                        const Text('SÉRIE EN COURS',
                            style: TextStyle(
                                letterSpacing: 1.5, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          '${session.currentSetIndex + 1} / ${currentWorkoutExercise.sets}',
                          style: const TextStyle(
                              fontSize: 48, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Objectif : ${currentWorkoutExercise.reps} répétitions',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Bouton d'action principal
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => ref.read(workoutSessionProvider.notifier).validateSet(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 24),
                const SizedBox(width: 10),
                Text(
                  session.currentSetIndex + 1 == currentWorkoutExercise.sets
                      ? 'TERMINER L\'EXERCICE'
                      : 'SÉRIE VALIDÉE',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3️⃣ ÉCRAN DE REPOS IMMERSIF (RESTING)
  Widget _buildRestingScreen(WidgetRef ref, WorkoutSessionState session) {
    return Container(
      key: const ValueKey('resting'),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'RÉCUPÉRATION',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.blueGrey),
          ),
          const SizedBox(height: 24),

          // Le chrono géant dégressif
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: session.remainingRestSeconds /
                        (session.currentWorkoutExercise?.restSeconds ?? 60),
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                Text(
                  '${session.remainingRestSeconds}s',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Préparation de la suite
          if (session.currentWorkoutExercise != null) ...[
            Center(
              child: ExerciseThumbnail(
                exercise: session.currentWorkoutExercise!.exercise,
                size: 96,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Prochaine étape : Prochaine série de ${session.currentWorkoutExercise?.exercise.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 48),

          // Passer le repos
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => ref.read(workoutSessionProvider.notifier).skipRest(),
            icon: const Icon(Icons.skip_next),
            label: const Text('PASSER LE REPOS', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 4️⃣ ÉCRAN DE FIN (COMPLETED)
  Widget _buildCompletedScreen(BuildContext context) {
    return Center(
      key: const ValueKey('completed'),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              'Félicitations ! 🎉',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Séance terminée avec succès. Tu as forgé ton corps un peu plus aujourd\'hui !',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                // 1. Récupérer le repository via Riverpod (pense à importer ton repository provider si besoin)
                final repository = ref.read(workoutRepositoryProvider);

                // 2. Mémoriser les trophées déjà débloqués AVANT cette séance
                final unlockedBefore = (await ref.read(trophiesProvider.future))
                    .where((trophy) => trophy.unlocked)
                    .map((trophy) => trophy.id)
                    .toSet();

                // 3. Créer l'objet log en piochant dans widget.workout !
                final log = WorkoutLog(
                  workoutId: int.tryParse(widget.workout.id.toString()) ?? 0,
                  workoutName: widget.workout.name,
                  date: DateTime.now(),
                  isCompleted: true,
                );

                // 4. Insérer le log dans la base SQLite
                await repository.insertWorkoutLog(log);

                // 5. Invalider les providers pour forcer le calendrier, le
                // bandeau de motivation et les trophées à se recharger
                ref.invalidate(weeklyHistoryProvider);
                ref.invalidate(statsProvider);
                ref.invalidate(trophiesProvider);

                // 6. Détecter les trophées fraîchement débloqués par cette séance
                final newlyUnlocked = (await ref.read(trophiesProvider.future))
                    .where((trophy) =>
                        trophy.unlocked && !unlockedBefore.contains(trophy.id))
                    .toList();

                if (!context.mounted) return;

                // 7. Célébration s'il y a du nouveau, puis retour au tableau de bord
                if (newlyUnlocked.isNotEmpty) {
                  await showTrophyCelebration(context, newlyUnlocked);
                }

                if (context.mounted) {
                  context.pop();
                }
              },
              child: const Text('RETOUR ACCUEIL', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}