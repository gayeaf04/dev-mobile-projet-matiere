enum MuscleGroup {
  chest,      // Pectoraux
  back,       // Dos
  legs,       // Jambes
  shoulders,  // Épaules
  arms,       // Bras (Biceps/Triceps)
  core        // Abdos/Lombaires
}

enum EquipmentType {
  barbell,    // Barre olympique
  dumbbell,   // Haltères
  machine,    // Machine guidée
  bodyweight, // Poids du corps
  cables      // Poules / Câbles
}

class Exercise {
  final String id;
  final String name;
  final String description;
  final MuscleGroup muscleGroup;
  final EquipmentType equipmentType;

  const Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.muscleGroup,
    required this.equipmentType,
  });

  // Pour l'affichage propre dans l'UI en Français
  String get muscleGroupLabel {
    switch (muscleGroup) {
      case MuscleGroup.chest: return 'Pectoraux';
      case MuscleGroup.back: return 'Dos';
      case MuscleGroup.legs: return 'Jambes';
      case MuscleGroup.shoulders: return 'Épaules';
      case MuscleGroup.arms: return 'Bras';
      case MuscleGroup.core: return 'Abdos / Gainage';
    }
  }

  // --- Sérialisation pour SQLite ---

  // Convertir un Exercice en Map (pour insertion SQL)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'muscleGroup': muscleGroup.name, // On stocke le nom du enum en String
      'equipmentType': equipmentType.name,
    };
  }

  // Créer un Exercice à partir d'un Map (lecture SQL)
  factory Exercise.fromMap(Map<String, dynamic> map) {
    return Exercise(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      muscleGroup: MuscleGroup.values.byName(map['muscleGroup'] as String),
      equipmentType: EquipmentType.values.byName(map['equipmentType'] as String),
    );
  }
}