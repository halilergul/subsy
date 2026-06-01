import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/notifications/application/notification_providers.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';
import 'package:subsy/features/notifications/domain/notification_settings_repository.dart';

import '../support/fakes.dart';

/// In-memory settings repo for controller tests.
class FakeSettingsRepository implements NotificationSettingsRepository {
  NotificationSettings current = NotificationSettings.defaults;

  @override
  Future<NotificationSettings> load() async => current;

  @override
  Future<void> save(NotificationSettings settings) async => current = settings;

  @override
  Stream<NotificationSettings> watch() => Stream.value(current);
}

/// US4 — permission-aware enable (maps SC-006).
void main() {
  test('enabling with permission granted persists enabled = true', () async {
    final repo = FakeSettingsRepository();
    final controller = NotificationSettingsController(
      repo,
      FakeNotificationScheduler(permission: true),
    );

    final applied = await controller.setEnabled(NotificationSettings.defaults, true);
    expect(applied, isTrue);
    expect(repo.current.enabled, isTrue);
  });

  test('enabling with permission denied keeps enabled = false', () async {
    final repo = FakeSettingsRepository();
    final controller = NotificationSettingsController(
      repo,
      FakeNotificationScheduler(permission: false),
    );

    final applied = await controller.setEnabled(NotificationSettings.defaults, true);
    expect(applied, isFalse);
    expect(repo.current.enabled, isFalse);
  });

  test('disabling does not require permission', () async {
    final repo = FakeSettingsRepository()
      ..current = const NotificationSettings(enabled: true);
    final controller = NotificationSettingsController(
      repo,
      FakeNotificationScheduler(permission: false),
    );

    final applied = await controller.setEnabled(repo.current, false);
    expect(applied, isTrue);
    expect(repo.current.enabled, isFalse);
  });

  test('setLeadDays / setTime persist', () async {
    final repo = FakeSettingsRepository();
    final controller = NotificationSettingsController(
      repo,
      FakeNotificationScheduler(),
    );
    await controller.setLeadDays(NotificationSettings.defaults, 5);
    expect(repo.current.leadDays, 5);
    await controller.setTime(repo.current, 8, 30);
    expect(repo.current.hour, 8);
    expect(repo.current.minute, 30);
  });
}
