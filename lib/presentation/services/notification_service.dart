import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Rappel local quotidien pour inciter l'utilisateur à faire sa séance.
///
/// Pas de package de détection de fuseau horaire ici : on convertit l'heure
/// locale souhaitée en instant UTC (le décalage du jour même suffit pour un
/// rappel quotidien) puis on programme la répétition dans une "Location"
/// UTC fixe — évite une dépendance supplémentaire juste pour ça.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  static const _reminderNotificationId = 1;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('UTC'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    // On ne demande pas la permission au lancement : seulement quand
    // l'utilisateur active le rappel depuis son profil (voir ReminderNotifier).
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );
  }

  /// Demande les permissions nécessaires (Android 13+ et iOS). Renvoie
  /// `true` si l'utilisateur a autorisé les notifications.
  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Sur une plateforme où le plugin correspondant n'existe pas (ex. web,
    // desktop), on considère qu'il n'y a rien à bloquer.
    return (androidGranted ?? true) && (iosGranted ?? true);
  }

  /// Programme (ou reprogramme) le rappel quotidien à [time] (heure locale).
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _plugin.zonedSchedule(
      id: _reminderNotificationId,
      title: 'C\'est l\'heure de forger ton corps 💪',
      body: 'N\'oublie pas ta séance d\'aujourd\'hui !',
      scheduledDate: _nextInstanceOf(time),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Rappel quotidien',
          channelDescription:
              'Rappel pour ne pas manquer sa séance du jour',
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelDailyReminder() =>
      _plugin.cancel(id: _reminderNotificationId);

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final nowUtc = DateTime.now().toUtc();
    final localOffset = DateTime.now().timeZoneOffset;

    // Instant UTC correspondant à "time" en heure locale aujourd'hui, puis
    // on avance d'un jour si c'est déjà passé.
    var scheduledUtc = DateTime.utc(
      nowUtc.year,
      nowUtc.month,
      nowUtc.day,
      time.hour,
      time.minute,
    ).subtract(localOffset);

    if (!scheduledUtc.isAfter(nowUtc)) {
      scheduledUtc = scheduledUtc.add(const Duration(days: 1));
    }

    return tz.TZDateTime.from(scheduledUtc, tz.getLocation('UTC'));
  }
}
