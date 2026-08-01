import 'package:flutter/foundation.dart';

enum FitnessObjective {
  gain,
  loss,
  maintenance
}

extension FitnessObjectiveExtension on FitnessObjective {
  String get displayName {
    switch (this) {
      case FitnessObjective.gain: return 'Prise de masse';
      case FitnessObjective.loss: return 'Perte de poids';
      case FitnessObjective.maintenance: return 'Maintien';
    }
  }
}

enum BmiCategory { underweight, normal, overweight, obese }

extension BmiCategoryLabel on BmiCategory {
  String get label {
    switch (this) {
      case BmiCategory.underweight: return 'Insuffisance pondérale';
      case BmiCategory.normal: return 'Corpulence normale';
      case BmiCategory.overweight: return 'Surpoids';
      case BmiCategory.obese: return 'Obésité';
    }
  }
}

@immutable
class UserProfile {
  final String id;
  final String name;
  final int age;
  final double height; // En centimètres (ex: 175.5)
  final double weight; // En kilogrammes (ex: 70.2)
  final FitnessObjective objective;

  const UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.objective,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    double? height,
    double? weight,
    FitnessObjective? objective,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      objective: objective ?? this.objective,
    );
  }

  /// Indice de Masse Corporelle (IMC) = poids(kg) / taille(m)².
  double get bmi {
    final heightInMeters = height / 100;
    if (heightInMeters <= 0) return 0;
    return weight / (heightInMeters * heightInMeters);
  }

  /// Catégorie d'IMC selon les seuils de l'OMS.
  BmiCategory get bmiCategory {
    final value = bmi;
    if (value < 18.5) return BmiCategory.underweight;
    if (value < 25) return BmiCategory.normal;
    if (value < 30) return BmiCategory.overweight;
    return BmiCategory.obese;
  }

  @override
  bool operator == (Object other) =>
      identical(this, other) ||
          other is UserProfile &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              age == other.age &&
              height == other.height &&
              weight == other.weight &&
              objective == other.objective;

  @override
  int get hashCode => Object.hash(id, name, age, weight, height, objective);

  /// Convertit notre objet UserProfile en Map (pour SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'height': height,
      'weight': weight,
      // On sauvegarde l'enum sous forme de chaîne de caractères (ex: "gain")
      'objective': objective.name,
    };
  }

  /// Crée un objet UserProfile à partir d'une Map (venant de SQLite)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as int,
      // SQLite peut parfois retourner un int au lieu d'un double si le nombre est pile (ex: 180),
      // le .toDouble() nous évite des bugs de typage surprise.
      height: (map['height'] as num).toDouble(),
      weight: (map['weight'] as num).toDouble(),
      // On convertit la chaîne de caractères lue en véritable enum Dart
      objective: FitnessObjective.values.byName(map['objective'] as String),
    );
  }
}