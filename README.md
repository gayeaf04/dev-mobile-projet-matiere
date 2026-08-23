# Forge 🏋️

Forge est une application Flutter de suivi de musculation, **100 % hors-ligne** : toutes les
données (profil, séances, historique, poids) sont stockées localement dans une base SQLite. Aucune
connexion réseau n'est requise pour utiliser l'application.

## Sommaire

- [Fonctionnalités](#fonctionnalités)
- [Stack technique](#stack-technique)
- [Architecture](#architecture)
- [Modèle de données](#modèle-de-données)
- [Navigation](#navigation)
- [Installation](#installation)
- [Commandes utiles](#commandes-utiles)
- [Tests](#tests)
- [Structure du projet](#structure-du-projet)

## Fonctionnalités

L'application s'organise autour de 5 onglets principaux :

- **Mes Séances** — tableau de bord des séances d'entraînement : création, édition, démarrage
  d'une séance guidée avec minuteur de repos entre les séries.
- **Exercices** — catalogue d'exercices pré-rempli (groupe musculaire, type d'équipement),
  fiche détail par exercice avec historique de progression (meilleure série, charge/répétitions).
- **Suivi** — courbe de poids corporel dans le temps, calcul et affichage de l'IMC, historique des
  séances sous forme de calendrier, statistiques globales de motivation.
- **Trophées** — système de récompenses (trophées débloqués selon l'assiduité et la progression),
  avec animation de célébration à l'obtention d'un nouveau trophée.
- **Profil** — création/édition du profil utilisateur (âge, taille, poids, objectif fitness),
  avec calcul automatique de l'IMC et de sa catégorie.

Fonctionnalités transverses :

- Minuteur de repos entre les séries pendant une séance, avec notification locale à la fin du
  repos (`flutter_local_notifications` + `timezone`).
- Persistance intégrale hors-ligne via SQLite (`sqflite`), aucune donnée envoyée à un serveur.
- Gestion d'erreurs SQLite à la sauvegarde (séance et profil), avec retour utilisateur en cas
  d'échec d'écriture.

## Stack technique

| Domaine              | Choix                                    |
|-----------------------|-------------------------------------------|
| Framework              | Flutter (SDK `^3.11.5`)                   |
| Gestion d'état          | `flutter_riverpod` v3                     |
| Navigation             | `go_router`                               |
| Base de données         | `sqflite` (SQLite embarqué)                |
| Identifiants           | `uuid` (v4)                                |
| Graphiques             | `fl_chart` (courbe de poids)               |
| Notifications locales   | `flutter_local_notifications` + `timezone` |
| Préférences légères     | `shared_preferences`                       |
| Internationalisation    | `intl`                                     |
| Tests                  | `flutter_test`, `fake_async` (minuteur déterministe) |

UI, commentaires de code et données par défaut sont en **français**.

## Architecture

Le projet suit une architecture en couches (« clean architecture »), avec un flux de données à
sens unique :

```
presentation/screens  →  presentation/providers (Riverpod)  →  data/repositories  →  data/local/database_helper.dart (sqflite)  →  SQLite
```

`domain/models` fournit les entités partagées par toutes les couches.

- **`domain/models/`** — classes Dart immuables. Chacune définit `toMap()`/`fromMap()` pour la
  persistance SQLite, `copyWith()`, et d'éventuels enums avec accesseurs de libellé français
  (ex. `Exercise.muscleGroupLabel`, `FitnessObjective.displayName`).
- **`data/local/database_helper.dart`** — singleton `DatabaseHelper.instance` exposant
  `Future<Database> get database`. Gère le schéma (`_onCreate`), les migrations (`_onUpgrade`) et
  le catalogue d'exercices pré-rempli (`_prepopulateExercises`).
- **`data/repositories/`** — une classe par agrégat (`ExerciseRepository`, `UserRepository`,
  `WorkoutRepository`). Tout le SQL vit ici, jamais dans les providers ni l'UI. Les repositories
  acceptent un `DatabaseHelper` optionnel pour la testabilité (par défaut le singleton).
- **`presentation/providers/`** — état Riverpod : `FutureProvider` pour les lectures
  (ex. `workoutListProvider`), `Notifier`/`AsyncNotifier` pour l'état mutable
  (ex. `WorkoutCreatorNotifier`, `ProfileNotifier`). Après une écriture, les lectures dépendantes
  sont rafraîchies via `ref.invalidate(...)`.
- **`presentation/screens/`** — widgets `ConsumerWidget` / `ConsumerStatefulWidget`.
- **`presentation/navigation/routes/app_router.dart`** — configuration `go_router`.
- **`presentation/services/`** — services transverses (notifications, alertes de repos).
- **`presentation/widgets/`** — composants UI réutilisables (courbe de poids, carte IMC, visuels
  de trophées, bannière de motivation, image d'exercice).
- **`core/`** — réservé, actuellement vide.

## Modèle de données

Base SQLite unique (`forge.db`), schéma en version **8**. Tables principales :

| Table                | Rôle                                                         |
|-----------------------|---------------------------------------------------------------|
| `user_profile`        | Profil utilisateur (nom, âge, taille, poids, objectif)        |
| `exercises`            | Catalogue d'exercices (nom, description, groupe musculaire, équipement) |
| `workouts`             | Séances définies par l'utilisateur                             |
| `workout_exercises`    | Liaison séance ↔ exercices (ordre, charge, séries prévues)     |
| `workout_history`      | Historique des séances effectuées (clé auto-incrémentée)       |
| `set_logs`             | Détail de chaque série réalisée (charge, répétitions)          |
| `weight_logs`          | Historique du poids corporel (pour la courbe de suivi)         |

Conventions de sérialisation :

- Les enums sont stockés en texte via `.name` et relus via `MyEnum.values.byName(...)`.
- Les `DateTime` sont stockés en `toIso8601String()`, sauf `workout_history.date` qui est une
  simple chaîne `YYYY-MM-DD`.
- Les `List<int>` (ex. `assignedDays`) sont stockées en chaîne séparée par des virgules ; les
  `bool` en `INTEGER` 0/1.
- Les clés primaires sont des UUID v4 (`TEXT`), sauf `workout_history` qui utilise un
  `INTEGER PRIMARY KEY AUTOINCREMENT`.
- Les écritures multi-tables passent par `db.transaction(...)` (ex. `WorkoutRepository.saveWorkout`).
- Les upserts utilisent `ConflictAlgorithm.replace`.

Toute modification de schéma nécessite trois changements coordonnés dans
`database_helper.dart` : incrémenter `version`, ajouter le `CREATE TABLE` dans `_onCreate`, et
ajouter un bloc `if (oldVersion < N) { ... }` dans `_onUpgrade`.

## Navigation

Routage via `go_router` (`appRouterImpl`), avec un `redirect` qui observe `profileProvider` :

- Aucun profil enregistré → redirection forcée vers `/profile-setup`.
- Profil existant → `/profile-setup` redirige vers `/`.

Routes principales : `/`, `/profile-setup`, `/profile-edit`, `/create-workout`, `/session`,
`/exercise-detail`. Les objets sont transmis entre écrans via `state.extra`
(ex. `context.push('/session', extra: workout)`).

## Installation

Prérequis : [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.11.5`).

```bash
git clone <url-du-repo>
cd forge
flutter pub get
flutter run
```

L'application fonctionne sur Android, iOS, macOS, Linux, Windows et Web (dossiers de plateforme
générés par Flutter présents à la racine).

## Commandes utiles

| Commande                                          | Description                          |
|-----------------------------------------------------|----------------------------------------|
| `flutter pub get`                                    | Installer les dépendances              |
| `flutter run`                                        | Lancer l'application                   |
| `flutter analyze`                                    | Analyse statique / lint (`flutter_lints`) |
| `dart format lib test`                               | Formatter le code                      |
| `flutter test`                                       | Lancer tous les tests                  |
| `flutter test test/rest_timer_test.dart`             | Lancer un fichier de test spécifique   |
| `flutter test --name "partie du nom du test"`        | Lancer un test par son nom             |

## Tests

Le dossier `test/` couvre notamment :

- `widget_test.dart` — tests de fumée au niveau application (`MyApp`) : porte de configuration du
  profil, tableau de bord avec les 5 onglets. Utilise des overrides
  (`userRepositoryProvider`/`workoutRepositoryProvider`) avec des faux repositories plutôt qu'une
  vraie base SQLite (voir le helper `_pumpApp`).
- `rest_timer_test.dart` — minuteur de repos, piloté de façon déterministe avec `fake_async`.
- `session_capture_test.dart`, `set_log_test.dart` — capture et journalisation des séries pendant
  une séance.
- `exercise_detail_screen_test.dart`, `exercise_progress_test.dart`, `exercise_image_test.dart` —
  écran de détail d'exercice et progression.
- `trophies_test.dart`, `trophy_celebration_test.dart` — logique et animation des trophées.
- `imc_card_test.dart`, `motivation_stats_test.dart` — carte IMC et statistiques de motivation.

## Structure du projet

```
lib/
├── main.dart
├── core/                          # réservé
├── domain/
│   └── models/                    # entités immuables (toMap/fromMap/copyWith)
├── data/
│   ├── local/database_helper.dart # schéma SQLite, migrations, seed
│   └── repositories/              # accès aux données (tout le SQL est ici)
└── presentation/
    ├── navigation/routes/         # configuration go_router
    ├── providers/                 # état Riverpod (Future/Notifier/AsyncNotifier)
    ├── screens/                   # écrans (ConsumerWidget)
    ├── services/                  # notifications, alertes de repos
    └── widgets/                   # composants UI réutilisables
test/                              # tests unitaires et widgets
```
