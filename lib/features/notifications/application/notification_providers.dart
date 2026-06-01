import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsy/features/notifications/application/reminder_sync.dart';
import 'package:subsy/features/notifications/data/isar_notification_settings_repository.dart';
import 'package:subsy/features/notifications/domain/notification_scheduler.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';
import 'package:subsy/features/notifications/domain/notification_settings_repository.dart';
import 'package:subsy/features/subscriptions/application/subscription_providers.dart';

/// The OS notification adapter. Overridden in `main()` with an initialized
/// `LocalNotificationService` (it needs async plugin init + timezone setup).
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  throw UnimplementedError('notificationSchedulerProvider must be overridden in main()');
});

final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
  final db = ref.watch(isarDatabaseProvider).requireValue;
  return IsarNotificationSettingsRepository(db.isar);
});

/// Current settings; emits on every change (drives the settings UI + reschedule).
final notificationSettingsProvider = StreamProvider<NotificationSettings>((ref) {
  return ref.watch(notificationSettingsRepositoryProvider).watch();
});

final notificationSettingsControllerProvider =
    Provider<NotificationSettingsController>((ref) {
  return NotificationSettingsController(
    ref.watch(notificationSettingsRepositoryProvider),
    ref.watch(notificationSchedulerProvider),
  );
});

/// Mutates settings. Enabling first requests OS permission and only persists
/// `enabled = true` when granted (honest state — FR-014/015).
class NotificationSettingsController {
  NotificationSettingsController(this._repo, this._scheduler);

  final NotificationSettingsRepository _repo;
  final NotificationScheduler _scheduler;

  /// Returns true if the new enabled state was applied. When enabling and
  /// permission is denied, returns false and does NOT enable.
  Future<bool> setEnabled(NotificationSettings current, bool enabled) async {
    if (enabled) {
      final granted = await _scheduler.requestPermission();
      if (!granted) return false;
    }
    await _repo.save(current.copyWith(enabled: enabled));
    return true;
  }

  Future<void> setLeadDays(NotificationSettings current, int days) =>
      _repo.save(current.copyWith(leadDays: days));

  Future<void> setTime(NotificationSettings current, int hour, int minute) =>
      _repo.save(current.copyWith(hour: hour, minute: minute));
}

/// Reactive reschedule: recomputes + reschedules whenever subscriptions or
/// settings change. Kept alive by being watched at the app root.
final reminderSyncProvider = Provider<void>((ref) {
  final scheduler = ref.watch(notificationSchedulerProvider);

  Future<void> resync() async {
    final subs = ref.read(subscriptionsProvider).asData?.value;
    final settings = ref.read(notificationSettingsProvider).asData?.value;
    if (subs == null || settings == null) return;
    await rescheduleAll(scheduler, subs, settings, DateTime.now());
  }

  ref.listen(subscriptionsProvider, (_, _) => resync());
  ref.listen(notificationSettingsProvider, (_, _) => resync());
  resync();
});

/// Call once at the app root (with the widget ref) to activate reactive
/// rescheduling for the app's lifetime.
void startReminderSync(WidgetRef ref) => ref.watch(reminderSyncProvider);
