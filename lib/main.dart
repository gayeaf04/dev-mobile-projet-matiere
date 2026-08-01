import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forge/presentation/navigation/lib/routes/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
// Note : Pense à importer ton fichier de routage dès qu'il sera créé !
// import 'presentation/navigation/app_router.dart';

void main() async {
  // ⚡ Indispensable pour s'assurer que les services Flutter sont prêts avant l'initialisation asynchrone
  WidgetsFlutterBinding.ensureInitialized();

  // 🌍 Charge les données de formatage pour le français (et les autres langues)
  await initializeDateFormatting('fr_FR', null);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  // Puisqu'on utilise Riverpod et qu'on va avoir besoin d'écouter notre routeur,
  // MyApp hérite de ConsumerWidget au lieu de StatelessWidget, ce qui nous donne accès à 'ref'.
  Widget build(BuildContext context, WidgetRef ref) {

    // 2. C'est ici qu'on branchera notre configuration GoRouter.
    // Pour l'instant, on met un placeholder en attendant de coder le fichier app_router.dart.
    // Plus tard, cela ressemblera à : final router = ref.watch(appRouterImpl);
    final router = ref.watch(appRouterImpl);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Fit App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 3. On configure l'application pour utiliser la navigation déclarative
      // Ces trois lignes indiquent à Flutter que c'est GoRouter qui gère l'affichage des écrans.
      routerConfig: router, // À remplacer par ton vrai router bientôt !
    );
  }
}
