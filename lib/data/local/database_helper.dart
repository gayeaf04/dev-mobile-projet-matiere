import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {

  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'forge.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        objective TEXT NOT NULL
      )
    ''');

    // NOUVELLE TABLE : Exercises
    await db.execute('''
    CREATE TABLE exercises (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT NOT NULL,
      muscleGroup TEXT NOT NULL,
      equipmentType TEXT NOT NULL
    )
  ''');

    // Injection des exercices par défaut
    await _prepopulateExercises(db);
  }
}

Future<void> _prepopulateExercises(Database db) async {
  final defaultExercises = [
    {
      'id': 'ex_bench_press',
      'name': 'Développé Couché',
      'description': 'Allongé sur un banc, pousser la barre verticalement au-dessus de la poitrine.',
      'muscleGroup': 'chest',
      'equipmentType': 'barbell',
    },
    {
      'id': 'ex_squat',
      'name': 'Squat à la Barre',
      'description': 'Barre sur les trapèzes, fléchir les jambes jusqu\'à avoir les cuisses parallèles au sol.',
      'muscleGroup': 'legs',
      'equipmentType': 'barbell',
    },
    {
      'id': 'ex_pullups',
      'name': 'Tractions',
      'description': 'Suspendu à une barre fixe, hisser le corps jusqu\'à ce que le menton passe au-dessus de la barre.',
      'muscleGroup': 'back',
      'equipmentType': 'bodyweight',
    },
    {
      'id': 'ex_bicep_curl',
      'name': 'Curl Haltères',
      'description': 'Debout, fléchir les coudes en amenant les haltères vers les épaules sans bouger les bras.',
      'muscleGroup': 'arms',
      'equipmentType': 'dumbbell',
    },
    {
      'id': 'ex_plank',
      'name': 'Gainage Planche',
      'description': 'En appui sur les avant-bras et les pointes de pieds, maintenir le corps parfaitement aligné.',
      'muscleGroup': 'core',
      'equipmentType': 'bodyweight',
    },
  ];

  for (final exercise in defaultExercises) {
    await db.insert(
      'exercises',
      exercise,
      conflictAlgorithm: ConflictAlgorithm.replace, // Évite les doublons
    );
  }
}