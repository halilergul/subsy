import 'package:subsy/features/notifications/domain/notification_settings.dart';

/// Persists the single global [NotificationSettings] record on-device.
abstract interface class NotificationSettingsRepository {
  /// Returns the saved settings, or [NotificationSettings.defaults] if none.
  Future<NotificationSettings> load();

  Future<void> save(NotificationSettings settings);

  /// Emits the current settings and every subsequent change.
  Stream<NotificationSettings> watch();
}
