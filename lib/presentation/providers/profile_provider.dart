

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forge/data/repositories/user_repository.dart';
import 'package:forge/domain/models/user_profile.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());


final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(() {
  return ProfileNotifier();
});

class ProfileNotifier extends AsyncNotifier<UserProfile?> {

  @override
  FutureOr<UserProfile?> build() async {
    // a. On récupère notre repository grâce à 'ref.read'
    final userRepository = ref.read(userRepositoryProvider);

    // b. On demande au repository d'aller chercher le profil en base SQLite
    // Cet état sera automatiquement enveloppé par Riverpod dans un AsyncValue (Loading/Data/Error)
    return await userRepository.getProfile();
  }

  Future<void> updateProfile(UserProfile profile) async {
    // a. On passe l'état en mode "chargement" visuel (optionnel mais propre)
    state = const AsyncValue.loading();

    // b. On récupère notre repository
    final userRepository = ref.read(userRepositoryProvider);

    // c. On utilise un bloc try/catch au cas où la base de données aurait un problème
    try {
      // Sauvegarde physique dans SQLite
      await userRepository.saveProfile(profile);

      // Mise à jour de l'état local interne (state) pour notifier instantanément l'UI
      state = AsyncData(profile);
    } catch (error, stackTrace) {
      // Si ça crash (rare avec SQLite mais bonne pratique), on pousse l'erreur dans l'état
      state = AsyncValue.error(error, stackTrace);
    }
  }
}