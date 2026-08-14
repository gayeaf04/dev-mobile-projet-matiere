

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forge/presentation/providers/profile_provider.dart';
import 'package:forge/presentation/screens/home_screen.dart';
import 'package:forge/presentation/screens/profile_setup_screen.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/exercise.dart';
import '../../../domain/models/workout.dart';
import '../../screens/create_workout_screen.dart';
import '../../screens/exercise_detail_screen.dart';
import '../../screens/workout_session_screen.dart';

final appRouterImpl = Provider<GoRouter>((ref) {

  final profileAsync = ref.watch(profileProvider);

  return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        // 1. Si Riverpod est encore en train de charger les données depuis SQLite,
        // on bloque la redirection (on retourne null) pour éviter des flashs d'écrans.
        if (profileAsync.isLoading) return null;

        // 2. On extrait la valeur du profil (qui peut être UserProfile ou null)
        final userProfile = profileAsync.value;

        // 3. On récupère le chemin actuel où l'utilisateur tente d'aller
        final isGoingToSetup = state.matchedLocation == '/profile-setup';

        // 4. LOGIQUE DE REDIRECTION
        // Si l'utilisateur n'a pas de profil en base...
        if (userProfile == null) {
          // ...et qu'il n'est pas déjà en train d'aller sur la page de création,
          // on le force à y aller !
          return isGoingToSetup ? null : '/profile-setup';
        }

        // Si l'utilisateur a un profil mais qu'il essaie d'aller sur la page de setup,
        // on le redirige vers l'accueil puisqu'il a déjà un profil.
        if (isGoingToSetup) return '/';

        // Dans tous les autres cas, on le laisse naviguer normalement.
        return null;
      },

      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return const HomeScreen();
          },
        ),

        GoRoute(
          path: '/profile-setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),

        GoRoute(
          path: '/profile-edit',
          builder: (context, state) {
            // On pré-remplit avec le profil actuellement enregistré
            return ProfileSetupScreen(existingProfile: profileAsync.value);
          },
        ),

        GoRoute(
          path: '/create-workout',
          builder: (context, state) => const CreateWorkoutScreen(),
        ),

        GoRoute(
          path: '/session',
          builder: (context, state) {
            // On extrait l'objet Workout passé lors du clic
            final workout = state.extra as Workout;
            return WorkoutSessionScreen(workout: workout);
          },
        ),

        GoRoute(
          path: '/exercise-detail',
          builder: (context, state) {
            // On extrait l'exercice dont on veut voir la progression
            final exercise = state.extra as Exercise;
            return ExerciseDetailScreen(exercise: exercise);
          },
        ),
      ],
  );
});