import 'package:subsy/features/notifications/domain/notification_scheduler.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';
import 'package:subsy/features/notifications/domain/reminder_planner.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// Reconciles scheduled reminders with the current subscriptions + settings.
/// Disabled → cancel everything; enabled → schedule the computed plan
/// (`scheduleAll` cancels first, so there are never duplicates).
Future<void> rescheduleAll(
  NotificationScheduler scheduler,
  List<Subscription> subs,
  NotificationSettings settings,
  DateTime now,
) async {
  if (!settings.enabled) {
    await scheduler.cancelAll();
    return;
  }
  await scheduler.scheduleAll(planReminders(subs, settings, now));
}
