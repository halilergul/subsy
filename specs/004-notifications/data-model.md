# Phase 1 Data Model: Notifications

One persisted entity (settings) + one transient value (planned reminder) + one pure function (the planner).

---

## `NotificationSettings` (domain entity, persisted)

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `enabled` | `bool` | `false` | true only after permission granted + user opt-in |
| `leadDays` | `int` | `3` | days before renewal (0–7 in UI) |
| `hour` | `int` | `10` | 0–23, local time |
| `minute` | `int` | `0` | 0–59 |

Defaults as named constants: `kDefaultLeadDays = 3`, `kDefaultHour = 10`, `kDefaultMinute = 0`, `kMaxLeadDays = 7`.

### Persistence: `NotificationSettingsEntity` (Isar `@collection`)
Single row with fixed `Id id = 0` (upsert). Mapper `fromDomain`/`toDomain`. Registered in `IsarDatabase` schemas.

---

## `PlannedReminder` (transient value)

| Field | Type | Notes |
|-------|------|-------|
| `subscriptionId` | `int` | also used as the OS notification id |
| `fireTime` | `DateTime` | local; strictly in the future |
| `title` | `String` | service name |
| `body` | `String` | Turkish, includes amount + when |

---

## Pure function: `reminder_planner`

```dart
/// Builds the reminder plan for the given subscriptions + settings.
/// Returns [] when settings.enabled is false. Omits any reminder whose fire
/// time is not strictly after [now] (FR-003). Deterministic given inputs.
List<PlannedReminder> planReminders(
  List<Subscription> subs,
  NotificationSettings settings,
  DateTime now,
);
```

Per subscription:
1. `renewal = effectiveNextRenewal(sub, now)` (reused from dashboard).
2. `fire = DateTime(renewal.year, renewal.month, renewal.day - settings.leadDays, settings.hour, settings.minute)`.
3. include only if `fire.isAfter(now)`.
4. `title = sub.name`; `body = "${sub.name} aboneliğin {when} yenilenecek — {formatMoney}"`.

> Notification id = `sub.id` (non-null for stored subscriptions).

---

## Scheduling lifecycle (orchestration, `reminder_sync`)

```
on (subscriptions emit) OR (settings change):
  if !settings.enabled || !permissionGranted:
      scheduler.cancelAll()
  else:
      plan = planReminders(subs, settings, now())
      scheduler.cancelAll()
      scheduler.scheduleAll(plan)
```

- Cancel-all-then-schedule guarantees no duplicates (FR-005) and handles add/edit/delete uniformly (FR-011/012/013).

---

## State (settings screen)

| State | UI |
|-------|----|
| reminders off | switch off; lead/time hidden or disabled |
| reminders on, permission granted | switch on; lead stepper + time row active; reminders scheduled |
| reminders on requested, permission denied | switch reverts to off; warning card + "Ayarları aç" (FR-015) |
