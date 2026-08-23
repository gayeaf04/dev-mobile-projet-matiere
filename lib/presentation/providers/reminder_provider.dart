import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

const _prefEnabled = 'reminder_enabled';
const _prefHour = 'reminder_hour';
const _prefMinute = 'reminder_minute';

/// Réglages du rappel quotidien, persistés localement (SharedPreferences) —
/// ce n'est pas une donnée du profil, juste une préférence de l'appareil.
class ReminderSettings {
  final bool enabled;
  final TimeOfDay time;

  const ReminderSettings({required this.enabled, required this.time});

  static const defaultTime = TimeOfDay(hour: 18, minute: 0);
}

class ReminderNotifier extends AsyncNotifier<ReminderSettings> {
  @override
  Future<ReminderSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefEnabled) ?? false;
    final hour = prefs.getInt(_prefHour) ?? ReminderSettings.defaultTime.hour;
    final minute =
        prefs.getInt(_prefMinute) ?? ReminderSettings.defaultTime.minute;
    final settings = ReminderSettings(
      enabled: enabled,
      time: TimeOfDay(hour: hour, minute: minute),
    );

    // Si le rappel était actif, on le reprogramme au démarrage pour rester
    // cohérent avec les préférences (les notifications planifiées ne
    // survivent pas forcément à une réinstallation de l'app).
    if (enabled) {
      await NotificationService.instance.scheduleDailyReminder(settings.time);
    }

    return settings;
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.value ??
        const ReminderSettings(
          enabled: false,
          time: ReminderSettings.defaultTime,
        );

    if (enabled) {
      final granted = await NotificationService.instance.requestPermissions();
      if (!granted) return; // permission refusée : on ne change pas l'état
      await NotificationService.instance.scheduleDailyReminder(current.time);
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, enabled);
    state = AsyncData(ReminderSettings(enabled: enabled, time: current.time));
  }

  Future<void> setTime(TimeOfDay time) async {
    final current = state.value;
    if (current == null || !current.enabled) return;

    await NotificationService.instance.scheduleDailyReminder(time);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefHour, time.hour);
    await prefs.setInt(_prefMinute, time.minute);
    state = AsyncData(ReminderSettings(enabled: current.enabled, time: time));
  }
}

final reminderProvider =
    AsyncNotifierProvider<ReminderNotifier, ReminderSettings>(
  () => ReminderNotifier(),
);
