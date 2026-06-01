import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:subsy/features/notifications/data/isar_notification_settings_repository.dart';
import 'package:subsy/features/notifications/data/notification_settings_entity.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';

/// US2 — settings persistence (maps SC-004).
void main() {
  late Directory tempDir;
  var counter = 0;

  setUpAll(() => Isar.initializeIsarCore(download: true));

  setUp(() => tempDir = Directory.systemTemp.createTempSync('subsy_notif_'));

  tearDown(() async {
    for (final name in Isar.instanceNames.toList()) {
      await Isar.getInstance(name)?.close(deleteFromDisk: true);
    }
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<Isar> openIsar() => Isar.open(
        [NotificationSettingsEntitySchema],
        directory: tempDir.path,
        name: 'notif_${counter++}',
      );

  test('load returns defaults when nothing is saved', () async {
    final repo = IsarNotificationSettingsRepository(await openIsar());
    final s = await repo.load();
    expect(s, NotificationSettings.defaults);
    expect(s.enabled, isFalse);
    expect(s.leadDays, kDefaultLeadDays);
  });

  test('save then load returns the same values', () async {
    final repo = IsarNotificationSettingsRepository(await openIsar());
    const settings = NotificationSettings(enabled: true, leadDays: 5, hour: 9, minute: 30);
    await repo.save(settings);
    expect(await repo.load(), settings);
  });

  test('save overwrites the single row (no second record)', () async {
    final repo = IsarNotificationSettingsRepository(await openIsar());
    await repo.save(const NotificationSettings(enabled: true, leadDays: 2));
    await repo.save(const NotificationSettings(enabled: true, leadDays: 6));
    final s = await repo.load();
    expect(s.leadDays, 6);
  });

  test('persists across a reopen of the same database', () async {
    final isar1 = await openIsar();
    final name = isar1.name;
    await IsarNotificationSettingsRepository(isar1)
        .save(const NotificationSettings(enabled: true, leadDays: 4, hour: 8, minute: 0));
    await isar1.close();

    final isar2 = await Isar.open(
      [NotificationSettingsEntitySchema],
      directory: tempDir.path,
      name: name,
    );
    final s = await IsarNotificationSettingsRepository(isar2).load();
    expect(s.leadDays, 4);
    expect(s.hour, 8);
  });
}
