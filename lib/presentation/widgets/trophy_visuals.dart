import 'package:flutter/material.dart';

/// Icône associée à un trophée (partagée entre la grille et la célébration).
IconData trophyIconFor(String id) {
  switch (id) {
    case 'first':
      return Icons.emoji_events;
    case 'five':
      return Icons.fitness_center;
    case 'ten':
      return Icons.bolt;
    case 'twentyFive':
      return Icons.military_tech;
    case 'fifty':
      return Icons.workspace_premium;
    case 'streak3':
      return Icons.local_fire_department;
    case 'streak7':
      return Icons.whatshot;
    default:
      return Icons.star;
  }
}
