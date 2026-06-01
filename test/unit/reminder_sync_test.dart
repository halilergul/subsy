import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/notifications/application/reminder_sync.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';
import 'package:subsy/features/notifications/domain/reminder_planner.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

import '../support/fakes.dart';

/// US1/US3 — orchestration with a fake scheduler (maps SC-001/003/005).
void main() {
  final now = DateTime(2026, 6, 1, 9);

  Subscription sub({int id = 1}) => Subscription(
        id: id,
        name: 'Netflix',
        amount: 149.99,
        currency: Currency.tryl,
        billingPeriod: BillingPeriod.monthly,
        nextRenewalDate: DateTime(2026, 6, 20),
        category: SubscriptionCategory.streaming,
        createdAt: now,
        updatedAt: now,
      );

  const enabled = NotificationSettings(enabled: true, leadDays: 3, hour: 10, minute: 0);
  const disabled = NotificationSettings(enabled: false);

  test('enabled → schedules exactly the computed plan', () async {
    final scheduler = FakeNotificationScheduler();
    final subs = [sub(id: 1), sub(id: 2)];
    await rescheduleAll(scheduler, subs, enabled, now);
    expect(scheduler.scheduled, planReminders(subs, enabled, now));
    expect(scheduler.scheduled.length, 2);
  });

  test('disabled → cancels all, schedules nothing', () async {
    final scheduler = FakeNotificationScheduler();
    await rescheduleAll(scheduler, [sub()], disabled, now);
    expect(scheduler.cancelAllCount, greaterThanOrEqualTo(1));
    expect(scheduler.scheduled, isEmpty);
  });

  test('rescheduling reflects a changed subscription list (no duplicates)', () async {
    final scheduler = FakeNotificationScheduler();
    await rescheduleAll(scheduler, [sub(id: 1)], enabled, now);
    expect(scheduler.scheduled.length, 1);

    // user added a second subscription → reschedule
    await rescheduleAll(scheduler, [sub(id: 1), sub(id: 2)], enabled, now);
    expect(scheduler.scheduled.length, 2);
    expect(scheduler.scheduled.map((r) => r.subscriptionId).toSet(), {1, 2});
  });
}
