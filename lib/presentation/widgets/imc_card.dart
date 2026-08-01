import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';

/// Carte santé affichant l'IMC de l'utilisateur (calculé depuis le profil)
/// avec sa catégorie et un conseil bienveillant.
class ImcCard extends ConsumerWidget {
  const ImcCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).value;

    // Pas de profil chargé -> rien à afficher.
    if (profile == null) return const SizedBox.shrink();

    final bmi = profile.bmi;
    final category = profile.bmiCategory;
    final color = _colorFor(category);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  child: Text(
                    bmi.toStringAsFixed(1),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  'IMC',
                  style: TextStyle(fontSize: 10, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _adviceFor(category),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Indicatif — ne remplace pas un avis médical.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorFor(BmiCategory category) {
  switch (category) {
    case BmiCategory.underweight:
      return Colors.blue;
    case BmiCategory.normal:
      return Colors.green;
    case BmiCategory.overweight:
      return Colors.orange;
    case BmiCategory.obese:
      return Colors.deepOrange;
  }
}

String _adviceFor(BmiCategory category) {
  switch (category) {
    case BmiCategory.underweight:
      return 'IMC un peu bas : un renforcement musculaire régulier et une alimentation adaptée peuvent t\'aider.';
    case BmiCategory.normal:
      return 'IMC dans la norme, continue tes séances pour rester en forme ! 💪';
    case BmiCategory.overweight:
      return 'Un peu au-dessus de la norme : ta régularité à l\'entraînement va payer, garde le cap !';
    case BmiCategory.obese:
      return 'Chaque séance compte : bouger régulièrement est un excellent pas vers ta forme.';
  }
}
