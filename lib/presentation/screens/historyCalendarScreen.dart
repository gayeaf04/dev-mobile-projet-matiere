import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/history_provider.dart';
import '../../../domain/models/workout_log.dart';

class HistoryCalendarScreen extends ConsumerWidget {
  const HistoryCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(weeklyHistoryProvider);

    // Génération des 7 jours de la semaine actuelle (Lundi à Dimanche)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Suivi Réactivité'),
        centerTitle: true,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
        data: (logs) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cette semaine',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // 📅 BARRE HORIZONTALE DU CALENDRIER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: weekDays.map((day) {
                    // On vérifie si un log correspond à ce jour précis
                    final dayStr = day.toIso8601String().split('T')[0];
                    final hasLog = logs.any((log) => log.date.toIso8601String().split('T')[0] == dayStr);
                    final isToday = day.day == now.day && day.month == now.month && day.year == now.year;

                    // Lettre du jour (L, M, M, J, V, S, D)
                    final dayLabel = DateFormat('E', 'fr_FR').format(day)[0].toUpperCase();

                    return Column(
                      children: [
                        Text(
                          dayLabel,
                          style: TextStyle(
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasLog
                                ? Colors.green
                                : (isToday ? Theme.of(context).colorScheme.primaryContainer : Colors.grey[200]),
                            border: isToday
                                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: hasLog
                                ? const Icon(Icons.check, color: Colors.white, size: 20)
                                : Text(
                              '${day.day}',
                              style: TextStyle(
                                color: hasLog ? Colors.white : (isToday ? Theme.of(context).colorScheme.primary : Colors.black87),
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                const Text(
                  'Historique d\'activité',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // 📜 LISTE DES SÉANCES EFFECTUÉES
                Expanded(
                  child: logs.isEmpty
                      ? const Center(
                    child: Text(
                      'Aucun entraînement validé pour le moment.\nBouge-toi aujourd\'hui ! 💪',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                      : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final formattedDate = DateFormat('EEEE d MMMM', 'fr_FR').format(log.date);

                      return ListTile(
                        leading: const Icon(Icons.fitness_center, color: Colors.green),
                        title: Text(log.workoutName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(formattedDate),
                        trailing: const Text(
                          'Complété',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}