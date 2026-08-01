import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/workout_stats.dart';
import '../providers/stats_provider.dart';

/// Bandeau de motivation affiché en haut du tableau de bord.
/// Met en avant la série de jours 🔥, les séances de la semaine et la
/// progression vers l'objectif hebdomadaire.
class MotivationBanner extends ConsumerWidget {
  const MotivationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsProvider);
    final scheme = Theme.of(context).colorScheme;

    return statsAsync.when(
      loading: () => Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: scheme.primaryContainer,
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      // En cas d'erreur, on n'encombre pas l'écran : le bandeau disparaît.
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) => _MotivationContent(stats: stats),
    );
  }
}

class _MotivationContent extends StatelessWidget {
  final WorkoutStats stats;

  const _MotivationContent({required this.stats});

  String get _message {
    if (stats.goalReached) {
      return 'Objectif de la semaine atteint, bravo ! 🎉';
    }
    if (stats.currentStreak >= 3) {
      return 'Ta série est en feu, ne lâche rien ! 🔥';
    }
    if (stats.workoutsThisWeek == 0) {
      return 'Prêt à forger ta semaine ? C\'est parti ! 💪';
    }
    return 'Plus que ${stats.remainingForGoal} séance(s) pour ton objectif !';
  }

  String get _streakTitle {
    if (stats.currentStreak <= 0) return 'Aucune série en cours';
    final jours = stats.currentStreak > 1 ? 'jours' : 'jour';
    return '${stats.currentStreak} $jours d\'affilée';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StreakBadge(streak: stats.currentStreak),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _streakTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _message,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Objectif : ${stats.goalLabel}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${stats.workoutsThisWeek}/${stats.weeklyGoal} séances',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: stats.goalProgress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;

  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 20)),
          Text(
            '$streak',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
