import 'package:flutter_test/flutter_test.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';
import 'package:subsy/features/notifications/domain/reminder_planner.dart';
import 'package:subsy/features/subscriptions/domain/enums.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';

/// US1 — pure reminder planning (maps SC-001/002).
void main() {
  final now = DateTime(2026, 6, 1, 9); // 09:00

  Subscription sub({
    int id = 1,
    String name = 'Netflix',
    DateTime? renewal,
    BillingPeriod period = BillingPeriod.monthly,
  }) {
    final t = DateTime(2026, 1, 1);
    return Subscription(
      id: id,
      name: name,
      amount: 149.99,
      currency: Currency.tryl,
      billingPeriod: period,
      nextRenewalDate: renewal ?? DateTime(2026, 6, 20),
      category: SubscriptionCategory.streaming,
      createdAt: t,
      updatedAt: t,
    );
  }

  const settings = NotificationSettings(enabled: true, leadDays: 3, hour: 10, minute: 0);

  test('disabled settings → empty plan', () {
    final plan = planReminders([sub()], settings.copyWith(enabled: false), now);
    expect(plan, isEmpty);
  });

  test('fires at (renewal - leadDays) at the configured time', () {
    final plan = planReminders([sub(renewal: DateTime(2026, 6, 20))], settings, now);
    expect(plan.single.subscriptionId, 1);
    expect(plan.single.fireTime, DateTime(2026, 6, 17, 10, 0));
    expect(plan.single.title, 'Netflix');
    expect(plan.single.body, contains('Netflix'));
    expect(plan.single.body, contains('₺149.99'));
  });

  test('past stored renewal rolls forward before computing the reminder', () {
    // renews on the 20th; last (May 20) is past → effective Jun 20 → fire Jun 17
    final plan = planReminders([sub(renewal: DateTime(2026, 5, 20))], settings, now);
    expect(plan.single.fireTime, DateTime(2026, 6, 17, 10, 0));
  });

  test('reminder whose fire time is already past is skipped', () {
    // renewal in 2 days (Jun 3), lead 3 → fire Jun 0 == May 31 09:00... before now → skip
    final plan = planReminders([sub(renewal: DateTime(2026, 6, 3))], settings, now);
    expect(plan, isEmpty);
  });

  test('one reminder per subscription, id = subscription id', () {
    final plan = planReminders(
      [sub(id: 1, name: 'A'), sub(id: 2, name: 'B')],
      settings,
      now,
    );
    expect(plan.map((r) => r.subscriptionId).toSet(), {1, 2});
  });

  test('subscriptions without an id are ignored', () {
    final noId = Subscription(
      name: 'X',
      amount: 10,
      currency: Currency.tryl,
      billingPeriod: BillingPeriod.monthly,
      nextRenewalDate: DateTime(2026, 6, 20),
      category: SubscriptionCategory.other,
      createdAt: now,
      updatedAt: now,
    );
    expect(planReminders([noId], settings, now), isEmpty);
  });
}
