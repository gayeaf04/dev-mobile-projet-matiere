import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  // 1. La clé globale pour valider le formulaire graphiquement
  final _formKey = GlobalKey<FormState>();

  // 2. Nos contrôleurs de texte (TextEditingController)
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  // 3. Notre état local pour l'objectif (valeur par défaut)
  FitnessObjective _selectedObjective = FitnessObjective.gain;

  @override
  void initState() {
    super.initState();
    // Initialisation des contrôleurs au démarrage de l'écran
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
  }

  @override
  void dispose() {
    // TRÈS IMPORTANT : On libère la mémoire pour éviter les fuites (Memory Leaks)
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _submitForm() {
    // a. On demande au formulaire de vérifier toutes ses validations graphiques
    if (_formKey.currentState!.validate()) {

      // b. Si tout est bon, on extrait et convertit proprement les valeurs
      final newProfile = UserProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // ID unique local temporaire
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        objective: _selectedObjective,
      );

      // c. ON ENVOIE L'ENVELOPPE !
      // On utilise ref.read car on est dans une action ponctuelle (un clic)
      ref.read(profileProvider.notifier).updateProfile(newProfile);

      // Note magique : Tu n'as pas besoin de faire un context.go('/') ici !
      // Dès que updateProfile va modifier l'état, ton app_router va le capter
      // et te rediriger automatiquement vers la racine.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer mon Profil Forge'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bienvenue dans Forge. Définissons tes bases pour structurer ta progression.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Champ NOM
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom ou Pseudo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Entre un nom valide' : null,
                ),
                const SizedBox(height: 16),

                // Champ ÂGE
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Âge',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.cake),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Entre ton âge';
                    if (int.tryParse(value) == null) return 'Entre un chiffre valide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Champ TAILLE
                TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Taille (en cm)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Entre ta taille';
                    if (double.tryParse(value) == null) return 'Exemple: 175.5';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Champ POIDS
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Poids Actuel (en kg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scale),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Entre ton poids';
                    if (double.tryParse(value) == null) return 'Exemple: 72.3';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Sélection de l'OBJECTIF (Dropdown)
                DropdownButtonFormField<FitnessObjective>(
                  initialValue: _selectedObjective,
                  decoration: const InputDecoration(
                    labelText: 'Ton Objectif Principal',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.emoji_events),
                  ),
                  items: FitnessObjective.values.map((objective) {
                    return DropdownMenuItem<FitnessObjective>(
                      value: objective,
                      // C'est ici qu'on utilise l'extension qu'on a créée au début !
                      child: Text(objective.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedObjective = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 32),

                // Bouton de validation
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Forger mon profil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}