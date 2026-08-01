import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service de retour haptique + sonore pour le minuteur de repos.
///
/// N'utilise que les API intégrées de Flutter ([HapticFeedback] et
/// [SystemSound]) : aucune dépendance externe, 100 % hors-ligne.
class RestAlert {
  const RestAlert();

  /// Petit « tic » discret joué pendant le décompte final (3, 2, 1…).
  Future<void> tick() async {
    await HapticFeedback.selectionClick();
  }

  /// Signal marqué (vibration forte + son) quand le repos est terminé.
  Future<void> restFinished() async {
    await HapticFeedback.heavyImpact();
    await SystemSound.play(SystemSoundType.alert);
  }
}

/// Fournit le [RestAlert] utilisé pendant la séance.
///
/// Peut être surchargé dans les tests pour vérifier les déclenchements
/// sans passer par les canaux natifs.
final restAlertProvider = Provider<RestAlert>((ref) => const RestAlert());
