import 'package:sqflite/sqflite.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/weight_log.dart';
import '../local/database_helper.dart';

class UserRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> saveProfile(UserProfile profile) async {
    // 1. On attend que la base de données soit prête et ouverte
    final db = await _dbHelper.database;

    // 2. On insère les données converties en Map
    await db.insert(
      'user_profile',
      profile.toMap(),
      // L'algorithme de conflit ultra pratique :
      // Si un profil avec le même ID existe déjà, SQLite l'écrase avec les nouvelles données.
      // Ça évite de devoir coder une méthode "insert" ET une méthode "update".
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ==========================================
  // RÉCUPÉRATION (LECTURE)
  // ==========================================
  Future<UserProfile?> getProfile() async {
    // 1. On récupère l'accès à la base de données
    final db = await _dbHelper.database;

    // 2. On fait une requête SELECT sur la table
    // query() retourne une liste de Maps. Chaque ligne de la table est une Map.
    final List<Map<String, dynamic>> maps = await db.query('user_profile');

    // 3. On vérifie s'il y a des données
    // Si la liste est vide, cela signifie que l'utilisateur n'a pas encore créé son profil
    if (maps.isEmpty) {
      return null; // On retourne null pour que l'app sache qu'il n'y a pas de profil
    }

    // 4. On transforme la première ligne trouvée (maps.first) en un bel objet UserProfile
    return UserProfile.fromMap(maps.first);
  }

  // ==========================================
  // HISTORIQUE DU POIDS (courbe d'évolution)
  // ==========================================

  // Enregistre un nouveau point de poids (un par modification de profil,
  // même plusieurs fois le même jour) pour la courbe d'évolution.
  Future<void> logWeight(DateTime date, double weight) async {
    final db = await _dbHelper.database;
    await db.insert('weight_logs', WeightLog(date: date, weight: weight).toMap());
  }

  // Tout l'historique de poids, du plus ancien au plus récent.
  Future<List<WeightLog>> getWeightLogs() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'weight_logs',
      orderBy: 'date ASC',
    );
    return List.generate(maps.length, (i) => WeightLog.fromMap(maps[i]));
  }
}