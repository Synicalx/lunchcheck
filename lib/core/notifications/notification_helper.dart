import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final ValueNotifier<bool> openInputModalNotifier = ValueNotifier<bool>(false);

  static Future<void> init() async {
    // 1. Initialize timezone database
    tz.initializeTimeZones();
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Could not get local timezone, fallback to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    // 2. Initialize settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // When notification is tapped, trigger entry view
        openInputModalNotifier.value = true;
      },
    );
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final bool? grantedNotification =
          await androidImplementation?.requestNotificationsPermission();
      final bool? grantedAlarm =
          await androidImplementation?.requestExactAlarmsPermission();
      return (grantedNotification ?? false) && (grantedAlarm ?? false);
    } else if (Platform.isIOS) {
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return true;
  }

  static Future<void> scheduleNotifications({
    required List<int> activeDays, // 1 = Monday, 7 = Sunday
    required int hour,
    required int minute,
  }) async {
    // Cancel all previously scheduled notifications
    await _notificationsPlugin.cancelAll();

    // Setup details
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'lunchcheck_reminders',
      'Lunch Check Reminders',
      channelDescription: 'Daily scheduled reminder to input lunch spend',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    for (final day in activeDays) {
      final scheduledDate = _nextInstanceOfWeekdayAndTime(day, hour, minute);
      
      // Notification ID can be the weekday (1-7) to ensure unique slot per active day
      await _notificationsPlugin.zonedSchedule(
        day,
        'LunchCheck',
        'Hey, how much did lunch cost today?',
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      
      debugPrint('Scheduled notification ID $day for weekday $day at $hour:$minute (Local: $scheduledDate)');
    }
  }

  static tz.TZDateTime _nextInstanceOfWeekdayAndTime(int weekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
