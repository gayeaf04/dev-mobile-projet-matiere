import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../providers/reminder_provider.dart';
import '../widgets/imc_card.dart';
import '../widgets/weight_chart.dart';

/// Écran de profil : sert à la fois à la création initiale (forcée par le
/// redirect tant qu'aucun profil n'existe) et à la modification ultérieure
/// via la route `/profile-edit` (on passe alors [existingProfile]).
class ProfileSetupScreen extends ConsumerStatefulWidget {
  final UserProfile? existingProfile;

  const ProfileSetupScreen({super.key, this.existingProfile});

  bool get isEditing => existingProfile != null;

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
    // Initialisation des contrôleurs au démarrage de l'écran, pré-remplis
    // avec le profil existant si on est en mode modification.
    final existing = widget.existingProfile;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _ageController = TextEditingController(text: existing?.age.toString() ?? '');
    _heightController =
        TextEditingController(text: existing?.height.toString() ?? '');
    _weightController =
        TextEditingController(text: existing?.weight.toString() ?? '');
    if (existing != null) {
      _selectedObjective = existing.objective;
    }
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

  Future<void> _submitForm() async {
    // a. On demande au formulaire de vérifier toutes ses validations graphiques
    if (_formKey.currentState!.validate()) {

      // b. Si tout est bon, on extrait et convertit proprement les valeurs.
      // En modification, on conserve l'id existant pour mettre à jour la
      // même ligne en base plutôt que d'en créer une nouvelle.
      final newProfile = UserProfile(
        id: widget.existingProfile?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        objective: _selectedObjective,
      );

      try {
        await ref.read(profileProvider.notifier).updateProfile(newProfile);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'enregistrer le profil : $error'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;

      if (widget.isEditing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour !')),
        );
        // L'écran est accessible soit en push (route /profile-edit), soit
        // comme onglet de la barre du bas : on ne revient en arrière que
        // dans le premier cas, sinon on reste simplement sur l'onglet.
        if (Navigator.canPop(context)) {
          context.pop();
        }
      }
      // En création, pas besoin de naviguer : dès que updateProfile modifie
      // l'état, l'app_router capte le changement et redirige vers la racine.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Mon Profil' : 'Créer mon Profil Forge'),
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
                Text(
                  widget.isEditing
                      ? 'Modifie tes informations à tout moment : ton IMC et ta courbe de poids se mettront à jour automatiquement.'
                      : 'Bienvenue dans Forge. Définissons tes bases pour structurer ta progression.',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                  child: Text(widget.isEditing
                      ? 'Enregistrer les modifications'
                      : 'Forger mon profil'),
                ),

                // En modification uniquement : IMC actuel + courbe de poids,
                // puisqu'il faut un profil déjà enregistré pour avoir un historique.
                if (widget.isEditing) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const ImcCard(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(Icons.show_chart,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Évolution du poids',
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, _) {
                      final historyAsync = ref.watch(weightHistoryProvider);
                      return historyAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, stack) => Text(
                          'Impossible de charger l\'historique : $err',
                        ),
                        data: (logs) => WeightChart(logs: logs),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.alarm,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Rappel quotidien',
                        style:
                            TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, _) {
                      final reminderAsync = ref.watch(reminderProvider);
                      return reminderAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, stack) => Text(
                          'Impossible de charger le rappel : $err',
                        ),
                        data: (settings) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Recevoir un rappel'),
                              subtitle: const Text(
                                'Une notification pour ne pas oublier ta séance du jour.',
                              ),
                              value: settings.enabled,
                              onChanged: (value) async {
                                await ref
                                    .read(reminderProvider.notifier)
                                    .setEnabled(value);
                                if (!context.mounted) return;
                                final stillDisabled =
                                    !(ref.read(reminderProvider).value?.enabled ??
                                        false);
                                if (value && stillDisabled) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Autorise les notifications dans les réglages pour activer le rappel.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            if (settings.enabled)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.access_time),
                                title: const Text('Heure du rappel'),
                                trailing: Text(
                                  settings.time.format(context),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: settings.time,
                                  );
                                  if (picked != null) {
                                    await ref
                                        .read(reminderProvider.notifier)
                                        .setTime(picked);
                                  }
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}