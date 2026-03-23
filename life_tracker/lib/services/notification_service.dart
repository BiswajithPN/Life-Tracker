import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.toString()));
    } catch (_) {
      // fallback
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Request notification & exact alarm permissions on Android 13+
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Show a simple notification immediately
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'life_tracker_channel',
      'Life Tracker Alerts',
      channelDescription: 'Notifications from Life Tracker app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }

  /// Cancel a specific reminder
  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  /// Schedule daily habit reminder at a specific time
  static Future<void> scheduleDailyHabitReminder({
    required int id,
    required String habitName,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_habit_channel',
      'Daily Habits',
      channelDescription: 'Daily reminders for your habits',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      '🎯 Habit Reminder',
      'Time to complete your habit: $habitName',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Show habit reminder notification
  static Future<void> showHabitReminder(String habitName) async {
    await showNotification(
      id: habitName.hashCode,
      title: '🎯 Habit Reminder',
      body: 'Time to complete: $habitName',
    );
  }

  /// Show spending alert notification
  static Future<void> showSpendingAlert(double percentage) async {
    await showNotification(
      id: 9999,
      title: '⚠️ Spending Alert',
      body:
          'You have spent ${percentage.toStringAsFixed(0)}% of your income! Consider slowing down.',
    );
  }
}
