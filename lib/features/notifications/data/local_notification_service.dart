import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:subsy/features/notifications/domain/notification_scheduler.dart';
import 'package:subsy/features/notifications/domain/planned_reminder.dart';
import 'package:timezone/timezone.dart' as tz;

/// `flutter_local_notifications` + `timezone` adapter — the single
/// platform-coupled implementation of [NotificationScheduler]. Uses zoned
/// scheduling so reminders fire at the correct local wall-clock time across
/// DST, and inexact alarms (no Android exact-alarm permission needed).
class LocalNotificationService implements NotificationScheduler {
  LocalNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const String _channelId = 'subsy_reminders';
  static const String _channelName = 'Abonelik hatırlatmaları';
  static const String _channelDescription =
      'Yaklaşan abonelik yenilemeleri için hatırlatmalar';

  /// One-time plugin init (call at startup). Permissions are requested
  /// explicitly later, when the user enables reminders.
  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> requestPermission() async {
    final android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _ios;
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }

  @override
  Future<bool> hasPermission() async {
    final android = _android;
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    return true; // iOS: assume granted unless a request returns false
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> scheduleAll(List<PlannedReminder> reminders) async {
    await _plugin.cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    for (final r in reminders) {
      await _plugin.zonedSchedule(
        id: r.subscriptionId,
        title: r.title,
        body: r.body,
        scheduledDate: tz.TZDateTime.from(r.fireTime, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
