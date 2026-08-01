# Copilot instructions for `forge`

Forge is a Flutter fitness/workout-tracker app. It works fully offline: all data lives in a local
SQLite database. The UI, code comments, and default data are in **French** — keep new strings and
comments French to match.

## Commands

- Install deps: `flutter pub get`
- Run app: `flutter run`
- Static analysis / lint: `flutter analyze` (rules come from `flutter_lints` via `analysis_options.yaml`)
- Format: `dart format lib test`
- Run all tests: `flutter test`
- Run a single test file: `flutter test test/widget_test.dart`
- Run a single test by name: `flutter test --name "part of the test description"`

Note: the only test, `test/widget_test.dart`, is still the default Flutter counter template. It does
not match this app and fails as-is — replace it rather than trusting it as a baseline.

## Architecture

Clean architecture in `lib/`, three layers. Data flows one direction:

`presentation/screens` → `presentation/providers` (Riverpod) → `data/repositories` → `data/local/database_helper.dart` (sqflite) → SQLite, with `domain/models` as the shared entities.

- `domain/models/` — plain immutable Dart classes. Each defines `toMap()`/`fromMap()` for SQLite,
  `copyWith()`, and any enums with French label getters (e.g. `Exercise.muscleGroupLabel`,
  `FitnessObjective.displayName`).
- `data/local/database_helper.dart` — `DatabaseHelper.instance` singleton exposing `Future<Database> get database`. Owns the schema (`_onCreate`), migrations (`_onUpgrade`), and the seeded exercise catalog (`_prepopulateExercises`).
- `data/repositories/` — one class per aggregate. All SQL lives here (no SQL in providers/UI).
  Repositories take an optional `DatabaseHelper` for testability and default to the singleton.
- `presentation/providers/` — Riverpod state (see conventions below).
- `presentation/screens/` — `ConsumerWidget` / `ConsumerStatefulWidget` UI.
- `presentation/navigation/lib/routes/app_router.dart` — the go_router config. (Yes, the path has a
  nested `lib/`; it is imported as `package:forge/presentation/navigation/lib/routes/app_router.dart`.)
- `lib/core/` — reserved/empty.

## Riverpod (flutter_riverpod v3)

- `main()` wraps the app in `ProviderScope`; `MyApp` is a `ConsumerWidget`.
- Each repository is exposed as a plain `Provider` (e.g. `workoutRepositoryProvider`).
- Reads use `FutureProvider` (e.g. `workoutListProvider`); mutable state uses `Notifier` /
  `AsyncNotifier` (e.g. `WorkoutCreatorNotifier`, `ProfileNotifier`).
- After a write, refresh dependent reads with `ref.invalidate(theFutureProvider)` — see
  `WorkoutCreatorNotifier.saveCurrentWorkout` invalidating `workoutListProvider`.

## Navigation (go_router)

- The router is `appRouterImpl` (a `Provider<GoRouter>`), watched in `MyApp`.
- A `redirect` gate watches `profileProvider`: with no profile the user is forced to `/profile-setup`;
  once a profile exists that route redirects back to `/`. So after saving a profile, **do not**
  navigate manually — the redirect handles it (see the note in `profile_setup_screen.dart`).
- Navigate with `context.push('/route')` / `context.pop()`. Pass objects between routes via
  `state.extra` (e.g. `context.push('/session', extra: workout)` read as `state.extra as Workout`).

## Database & serialization conventions

- **Schema changes require three coordinated edits** in `database_helper.dart`: bump `version` in
  `_initDatabase`, add the create statement to `_onCreate`, and add a matching
  `if (oldVersion < N) { ... }` block to `_onUpgrade`. Current version is **5**.
- Enums are stored as strings via `enumValue.name` and read back with `MyEnum.values.byName(str)`.
- `DateTime` is stored with `toIso8601String()`. Exception: `workout_history.date` is a `YYYY-MM-DD`
  string only (via `.split('T')[0]`).
- `List<int>` (e.g. `assignedDays`) is stored as a comma-joined string; `bool` as an `INTEGER` 1/0.
- Read `REAL` columns as `(map['x'] as num).toDouble()` — SQLite may return an int for whole numbers.
- Upserts use `conflictAlgorithm: ConflictAlgorithm.replace` instead of separate insert/update paths.
- Multi-table writes go through `db.transaction((txn) async { ... })` (see `WorkoutRepository.saveWorkout`).
- Primary keys are `Uuid().v4()` strings (`TEXT PRIMARY KEY`). Exception: `workout_history` uses
  `INTEGER PRIMARY KEY AUTOINCREMENT`.
