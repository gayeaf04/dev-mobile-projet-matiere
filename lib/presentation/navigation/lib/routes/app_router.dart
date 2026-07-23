

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forge/presentation/providers/profile_provider.dart';
import 'package:forge/presentation/screens/exercise_list_screen.dart';
import 'package:forge/presentation/screens/profile_setup_screen.dart';
import 'package:go_router/go_router.dart';

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
            return const ExerciseListScreen();
          },
        ),

        GoRoute(
          path: '/profile-setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),

        GoRoute(
          path: '/programs',
          builder: (context, state) {
            // Placeholder temporaire avant de mettre ton vrai écran
            return const Scaffold(
              body: Center(child: Text('Écran des programmes d\'entrainement')),
            );
          },
        ),
      ],
  );
});