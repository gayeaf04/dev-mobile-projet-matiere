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
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // 3. NOUVELLE TABLE : Enveloppe de la Séance
    await db.execute('''
    CREATE TABLE workouts (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      createdAt TEXT NOT NULL
    )
  ''');

    // 4. NOUVELLE TABLE : Ligne d'exercice au sein d'une séance (Table de liaison)
    await db.execute('''
    CREATE TABLE workout_exercises (
      id TEXT PRIMARY KEY,
      workoutId TEXT NOT NULL,
      exerciseId TEXT NOT NULL,
      sets INTEGER NOT NULL,
      reps INTEGER NOT NULL,
      restSeconds INTEGER NOT NULL,
      FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE,
      FOREIGN KEY (exerciseId) REFERENCES exercises (id)
    )
  ''');

    // À insérer dans le script de création de ta base SQLite :
    await db.execute('''
    CREATE TABLE workout_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      workout_id INTEGER,
      workout_name TEXT,
      date TEXT, -- Format YYYY-MM-DD
      is_completed INTEGER
    )
  ''');

    // À exécuter lors de la création/mise à jour de ta table 'workouts' :
    await db.execute('ALTER TABLE workouts ADD COLUMN assigned_days TEXT DEFAULT ""');
    await db.execute('ALTER TABLE workouts ADD COLUMN has_cardio INTEGER DEFAULT 0');

    // Injection des exercices par défaut
    await _prepopulateExercises(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Vérification des mises à jour de la BDD... Ancienne version: $oldVersion, Nouvelle version: $newVersion");

    // Si tu avais une version très ancienne (v1), on s'assure d'avoir la table exercices
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercises (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          muscleGroup TEXT NOT NULL,
          equipmentType TEXT NOT NULL
        )
      ''');
      await _prepopulateExercises(db);
    }

    // 🚀 LA MIGRATION ACTUELLE (v2 vers v3)
    if (oldVersion < 3) {
      // On ajoute la table des séances
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workouts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      // On ajoute la table de liaison avec les clés étrangères
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workout_exercises (
          id TEXT PRIMARY KEY,
          workoutId TEXT NOT NULL,
          exerciseId TEXT NOT NULL,
          sets INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          restSeconds INTEGER NOT NULL,
          FOREIGN KEY (workoutId) REFERENCES workouts (id) ON DELETE CASCADE,
          FOREIGN KEY (exerciseId) REFERENCES exercises (id)
        )
      ''');

      print("🚀 MIGRATION REUSSIE : Les tables de séances ont été ajoutées en tâche de fond !");
    }

    if(oldVersion < 4 ) {
      // À insérer dans le script de création de ta base SQLite :
      await db.execute('''
      CREATE TABLE workout_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER,
        workout_name TEXT,
        date TEXT, -- Format YYYY-MM-DD
        is_completed INTEGER
      )
    ''');

      print("Creation de la table Workout log dans la base effectuée avec succès");
    }

    if (oldVersion < 5) {
      // À exécuter lors de la création/mise à jour de ta table 'workouts' :
      await db.execute('ALTER TABLE workouts ADD COLUMN assigned_days TEXT DEFAULT ""');
      await db.execute('ALTER TABLE workouts ADD COLUMN has_cardio INTEGER DEFAULT 0');
    }
  }
}
Future<void> _prepopulateExercises(Database db) async {
  final defaultExercises = [
    // --- PECTORAUX (CHEST) ---
    {
      'id': 'ex_bench_press',
      'name': 'Développé Couché',
      'description': 'Allongé sur un banc, pousser la barre verticalement au-dessus de la poitrine. Exercice roi pour les pectoraux.',
      'muscleGroup': 'chest',
      'equipmentType': 'barbell',
    },
    {
      'id': 'ex_incline_dumbbell_press',
      'name': 'Développé Incliné Haltères',
      'description': 'Sur un banc incliné à 30°, pousser les haltères pour cibler le haut des pectoraux.',
      'muscleGroup': 'chest',
      'equipmentType': 'dumbbell',
    },
    {
      'id': 'ex_pushups',
      'name': 'Pompes',
      'description': 'Face au sol, repousser le poids de son corps. Idéal pour le renforcement global.',
      'muscleGroup': 'chest',
      'equipmentType': 'bodyweight',
    },

    // --- DOS (BACK) ---
    {
      'id': 'ex_pullups',
      'name': 'Tractions',
      'description': 'Suspendu à une barre fixe, hisser le corps jusqu\'au menton. Excellent pour la largeur du dos.',
      'muscleGroup': 'back',
      'equipmentType': 'bodyweight',
    },
    {
      'id': 'ex_barbell_row',
      'name': 'Busting Rowing (Barre)',
      'description': 'Buste penché en avant, ramener la barre vers le nombril en serrant les omoplates.',
      'muscleGroup': 'back',
      'equipmentType': 'barbell',
    },
    {
      'id': 'ex_lat_pulldown',
      'name': 'Tirage Vertical Poulie',
      'description': 'Assis à la machine, tirer la barre vers le haut de la poitrine pour cibler les grands dorsaux.',
      'muscleGroup': 'back',
      'equipmentType': 'cables',
    },

    // --- JAMBES (LEGS) ---
    {
      'id': 'ex_squat',
      'name': 'Squat à la Barre',
      'description': 'Barre sur les trapèzes, fléchir les jambes jusqu\'à l\'horizontale. Développe toute la masse des cuisses.',
      'muscleGroup': 'legs',
      'equipmentType': 'barbell',
    },
    {
      'id': 'ex_romanian_deadlift',
      'name': 'Soulevé de Terre Roumain',
      'description': 'Charnière de hanche en arrière avec jambes quasi-tendues pour cibler les ischios et les fessiers.',
      'muscleGroup': 'legs',
      'equipmentType': 'barbell',
    },
    {
      'id': 'ex_leg_press',
      'name': 'Presse à Cuisses',
      'description': 'Pousser le plateau de la machine avec les pieds pour isoler les quadriceps en sécurité.',
      'muscleGroup': 'legs',
      'equipmentType': 'machine',
    },

    // --- ÉPAULES (SHOULDERS) ---
    {
      'id': 'ex_overhead_press',
      'name': 'Développé Militaire',
      'description': 'Debout, pousser la barre au-dessus de la tête. Exercice de force pure pour les épaules.',
      'muscleGroup': 'shoulders',
      'equipmentType': 'barbell',
    },
    {
      'id': 'ex_lateral_raises',
      'name': 'Élévations Latérales',
      'description': 'Lever les haltères sur les côtés jusqu\'à l\'horizontale pour donner de la largeur aux épaules.',
      'muscleGroup': 'shoulders',
      'equipmentType': 'dumbbell',
    },

    // --- BRAS (ARMS) ---
    {
      'id': 'ex_bicep_curl',
      'name': 'Curl Haltères Switch',
      'description': 'Fléchir les coudes en amenant les haltères vers les épaules avec une rotation du poignet.',
      'muscleGroup': 'arms',
      'equipmentType': 'dumbbell',
    },
    {
      'id': 'ex_tricep_pushdown',
      'name': 'Triceps Corde',
      'description': 'À la poulie haute, tendre les bras vers le bas en écartant la corde en fin de mouvement.',
      'muscleGroup': 'arms',
      'equipmentType': 'cables',
    },

    // --- ABDOS / SANGLE ABDOMINALE (CORE) ---
    {
      'id': 'ex_plank',
      'name': 'Gainage Planche',
      'description': 'En appui sur les avant-bras et les pointes de pieds, maintenir le corps aligné pour renforcer le transverse.',
      'muscleGroup': 'core',
      'equipmentType': 'bodyweight',
    },
    {
      'id': 'ex_hanging_leg_raises',
      'name': 'Relevé de Jambes Suspendu',
      'description': 'Suspendu à la barre, relever les jambes tendues ou fléchies pour cibler le bas des abdos.',
      'muscleGroup': 'core',
      'equipmentType': 'bodyweight',
    },
  ];

  for (final exercise in defaultExercises) {
    await db.insert(
      'exercises',
      exercise,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}