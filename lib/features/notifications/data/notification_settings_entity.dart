import 'package:isar_community/isar.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';

part 'notification_settings_entity.g.dart';

/// Single-row Isar persistence of [NotificationSettings] (always id = 0).
@collection
class NotificationSettingsEntity {
  /// Fixed id — there is only ever one settings record.
  Id id = 0;

  late bool enabled;
  late int leadDays;
  late int hour;
  late int minute;

  static NotificationSettingsEntity fromDomain(NotificationSettings s) {
    return NotificationSettingsEntity()
      ..id = 0
      ..enabled = s.enabled
      ..leadDays = s.leadDays
      ..hour = s.hour
      ..minute = s.minute;
  }

  NotificationSettings toDomain() => NotificationSettings(
        enabled: enabled,
        leadDays: leadDays,
        hour: hour,
        minute: minute,
      );
}
