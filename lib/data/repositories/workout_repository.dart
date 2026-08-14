import 'package:sqflite/sqflite.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/set_log.dart';
import '../../domain/models/workout.dart';
import '../../domain/models/workout_log.dart';
import '../local/database_helper.dart';

class WorkoutRepository {
  final DatabaseHelper _dbHelper;

  WorkoutRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // --- 1. ENREGISTRER UNE SÉANCE ---
  Future<void> saveWorkout(Workout workout) async {
    final db = await _dbHelper.database;

    // On ouvre une TRANSACTION : si une seule insertion échoue,
    // tout est annulé pour éviter d'avoir des données corrompues en BDD.
    await db.transaction((txn) async {
      // a. Insertion de la séance globale
      await txn.insert(
        'workouts',
        workout.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // b. Insertion de chaque exercice lié à cette séance
      for (final workoutExercise in workout.exercises) {
        await txn.insert(
          'workout_exercises',
          workoutExercise.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // --- 2. RÉCUPÉRER TOUTES LES SÉANCES (Avec leurs exercices) ---
  Future<List<Workout>> getAllWorkouts() async {
    final db = await _dbHelper.database;

    // a. On récupère d'abord toutes les séances de la table 'workouts'
    final List<Map<String, dynamic>> workoutMaps = await db.query(
      'workouts',
      orderBy: 'createdAt DESC', // Les plus récentes en premier
    );

    final List<Workout> workouts = [];

    // b. Pour chaque séance, on va chercher ses exercices associés en faisant un JOIN
    for (final workoutMap in workoutMaps) {
      final workoutId = workoutMap['id'] as String;

      final List<Map<String, dynamic>> exerciseRows = await db.rawQuery('''
        SELECT we.*, e.name, e.description, e.muscleGroup, e.equipmentType
        FROM workout_exercises we
        INNER JOIN exercises e ON we.exerciseId = e.id
        WHERE we.workoutId = ?
      ''', [workoutId]);

      // c. On reconstruit les objets WorkoutExercise à partir des résultats du JOIN
      final List<WorkoutExercise> workoutExercises = exerciseRows.map((row) {
        final exercise = Exercise(
          id: row['exerciseId'] as String,
          name: row['name'] as String,
          description: row['description'] as String,
          muscleGroup: MuscleGroup.values.byName(row['muscleGroup'] as String),
          equipmentType: EquipmentType.values.byName(row['equipmentType'] as String),
        );

        return WorkoutExercise(
          id: row['id'] as String,
          workoutId: row['workoutId'] as String,
          exercise: exercise,
          sets: row['sets'] as int,
          reps: row['reps'] as int,
          restSeconds: row['restSeconds'] as int,
        );
      }).toList();

      // d. On assemble le tout pour créer notre entité Workout finale
      workouts.add(Workout(
        id: workoutId,
        name: workoutMap['name'] as String,
        createdAt: DateTime.parse(workoutMap['createdAt'] as String),
        exercises: workoutExercises,
      ));
    }

    return workouts;
  }

  // --- 3. SUPPRIMER UNE SÉANCE ---
  Future<void> deleteWorkout(String workoutId) async {
    final db = await _dbHelper.database;
    // Grâce au ON DELETE CASCADE configuré lors de la migration,
    // supprimer la ligne dans 'workouts' va détruire automatiquement
    // les lignes liées dans 'workout_exercises' !
    await db.delete(
      'workouts',
      where: 'id = ?',
      whereArgs: [workoutId],
    );
  }

  // --- À AJOUTER DANS TA CLASSE WORKOUTREPOSITORY ---

// 1. Sauvegarder une séance validée. Renvoie l'id (history_id) créé.
  Future<int> insertWorkoutLog(WorkoutLog log) async {
    final db = await _dbHelper.database; // Utilise le nom de ta variable de BDD interne (ex: _db, _database)
    return await db.insert(
      'workout_history',
      log.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

// 2. Récupérer l'historique de la semaine
  Future<List<WorkoutLog>> getWorkoutLogsForRange(DateTime start, DateTime end) async {
    final db = await _dbHelper.database;

    final startDateStr = start.toIso8601String().split('T')[0];
    final endDateStr = end.toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> maps = await db.query(
      'workout_history',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
      orderBy: 'date ASC',
    );

    return List.generate(maps.length, (i) => WorkoutLog.fromMap(maps[i]));
  }

// 3. Récupérer tout l'historique (nécessaire pour calculer la série de jours)
  Future<List<WorkoutLog>> getAllWorkoutLogs() async {
    final db = await _dbHelper.database;

    final List<Map<String, dynamic>> maps = await db.query(
      'workout_history',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) => WorkoutLog.fromMap(maps[i]));
  }

  // --- SUIVI DES PERFORMANCES (séries) ---

  // Enregistre en bloc les séries réalisées pendant une séance.
  Future<void> insertSetLogs(List<SetLog> logs) async {
    if (logs.isEmpty) return;
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final log in logs) {
        await txn.insert(
          'set_logs',
          log.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  // Toutes les séries d'un exercice (les plus anciennes d'abord) pour la
  // courbe de progression.
  Future<List<SetLog>> getSetLogsForExercise(String exerciseId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'set_logs',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'date ASC, id ASC',
    );
    return List.generate(maps.length, (i) => SetLog.fromMap(maps[i]));
  }

  // Dernière série enregistrée pour un exercice (pour pré-remplir la charge).
  Future<SetLog?> getLastSetLogForExercise(String exerciseId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'set_logs',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SetLog.fromMap(maps.first);
  }
}