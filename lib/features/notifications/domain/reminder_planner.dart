import 'package:subsy/features/dashboard/domain/relative_date_label.dart';
import 'package:subsy/features/dashboard/domain/renewal_calculator.dart';
import 'package:subsy/features/notifications/domain/notification_settings.dart';
import 'package:subsy/features/notifications/domain/planned_reminder.dart';
import 'package:subsy/features/subscriptions/domain/subscription.dart';
import 'package:subsy/shared/utils/money_format.dart';

/// Builds the reminder plan for [subs] given [settings] and [now].
///
/// - Returns `[]` when reminders are disabled.
/// - Each reminder fires at (effective next renewal − leadDays) at the chosen
///   time of day; the effective renewal rolls past dates forward (reused from
///   the dashboard).
/// - Reminders whose fire time is not strictly after [now] are omitted
///   (no past/immediate notifications).
/// - One reminder per (persisted) subscription; notification id = subscription id.
/// Pure and deterministic given its inputs.
List<PlannedReminder> planReminders(
  List<Subscription> subs,
  NotificationSettings settings,
  DateTime now,
) {
  if (!settings.enabled) return const [];

  final reminders = <PlannedReminder>[];
  for (final s in subs) {
    final id = s.id;
    if (id == null) continue;

    final renewal = effectiveNextRenewal(s, now);
    final fire = DateTime(
      renewal.year,
      renewal.month,
      renewal.day - settings.leadDays,
      settings.hour,
      settings.minute,
    );
    if (!fire.isAfter(now)) continue;

    final when = relativeDateLabel(renewal, now);
    reminders.add(PlannedReminder(
      subscriptionId: id,
      fireTime: fire,
      title: s.name,
      body: '${s.name} aboneliğin $when yenilenecek — ${formatMoney(s.amount, s.currency)}',
    ));
  }
  return reminders;
}
