import 'package:flutter/material.dart';
import '../../domain/models/trophy.dart';
import 'trophy_visuals.dart';

/// Affiche une animation de félicitations listant les trophées fraîchement
/// débloqués. À appeler en fin de séance uniquement s'il y a du nouveau.
Future<void> showTrophyCelebration(BuildContext context, List<Trophy> trophies) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _TrophyCelebrationDialog(trophies: trophies),
  );
}

class _TrophyCelebrationDialog extends StatelessWidget {
  final List<Trophy> trophies;

  const _TrophyCelebrationDialog({required this.trophies});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final plural = trophies.length > 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) =>
            Transform.scale(scale: value.clamp(0.0, 1.0), child: child),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
              const SizedBox(height: 12),
              Text(
                plural
                    ? 'Nouveaux trophées débloqués !'
                    : 'Nouveau trophée débloqué !',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...trophies.map(
                (trophy) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white24,
                        child: Icon(
                          trophyIconFor(trophy.id),
                          color: Colors.amber.shade200,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trophy.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              trophy.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: scheme.primary,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Génial !',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
