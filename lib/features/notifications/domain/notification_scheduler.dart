import 'package:subsy/features/notifications/domain/planned_reminder.dart';

/// Wraps the OS local-notification plugin — the only platform-coupled seam.
/// Implemented by `LocalNotificationService`; faked in tests.
abstract interface class NotificationScheduler {
  /// Requests OS notification permission; returns true if granted.
  Future<bool> requestPermission();

  /// Whether permission is currently granted.
  Future<bool> hasPermission();

  /// Cancels all pending reminders, then schedules the given plan. Each
  /// reminder uses its `subscriptionId` as the notification id.
  Future<void> scheduleAll(List<PlannedReminder> reminders);

  /// Cancels every pending reminder.
  Future<void> cancelAll();
}
