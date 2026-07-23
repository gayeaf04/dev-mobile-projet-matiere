import '../../domain/models/exercise.dart';
import '../local/database_helper.dart';

class ExerciseRepository {
  final DatabaseHelper _dbHelper;

  ExerciseRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  // Récupérer tous les exercices de la base de données
  Future<List<Exercise>> getAllExercises() async {
    final db = await _dbHelper.database;

    // On requête la table 'exercises' en triant par nom alphabétique
    final List<Map<String, dynamic>> maps = await db.query(
      'exercises',
      orderBy: 'name ASC',
    );

    // On transforme la liste de Maps en liste d'objets Exercise
    return List.generate(maps.length, (i) => Exercise.fromMap(maps[i]));
  }
}