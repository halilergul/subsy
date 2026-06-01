import 'package:isar_community/isar.dart';
import 'package:subsy/features/notifications/data/notification_settings_entity.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';
import 'package:subsy/features/notifications/domain/notification_settings_repository.dart';

/// Isar-backed settings store (single row, id = 0).
class IsarNotificationSettingsRepository implements NotificationSettingsRepository {
  IsarNotificationSettingsRepository(this._isar);

  final Isar _isar;
  static const int _id = 0;

  IsarCollection<NotificationSettingsEntity> get _col => _isar.notificationSettingsEntitys;

  @override
  Future<NotificationSettings> load() async {
    final row = await _col.get(_id);
    return row?.toDomain() ?? NotificationSettings.defaults;
  }

  @override
  Future<void> save(NotificationSettings settings) async {
    await _isar.writeTxn(() => _col.put(NotificationSettingsEntity.fromDomain(settings)));
  }

  @override
  Stream<NotificationSettings> watch() {
    return _col
        .watchObject(_id, fireImmediately: true)
        .map((row) => row?.toDomain() ?? NotificationSettings.defaults);
  }
}
