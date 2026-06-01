# Contracts: Notifications

---

## 1. Consumed (existing)

```dart
final subscriptionsProvider;                  // StreamProvider<List<Subscription>>  (core)
DateTime effectiveNextRenewal(Subscription, DateTime now);  // dashboard domain
String formatMoney(double, Currency);         // shared util
```

---

## 2. Domain interfaces (this feature)

```dart
/// Persists the single global settings record.
abstract interface class NotificationSettingsRepository {
  Future<NotificationSettings> load();          // returns defaults if none saved
  Future<void> save(NotificationSettings settings);
  Stream<NotificationSettings> watch();          // emits on change (drives reschedule)
}

/// Wraps the OS notification plugin. The only platform-coupled seam.
abstract interface class NotificationScheduler {
  Future<bool> requestPermission();              // true if granted
  Future<bool> hasPermission();
  Future<void> scheduleAll(List<PlannedReminder> reminders);
  Future<void> cancelAll();
}
```

**Contract**
- `NotificationSettingsRepository.load()` never throws → returns defaults when empty.
- `NotificationScheduler.scheduleAll` schedules each reminder at its (future) `fireTime`, id = `subscriptionId`; callers pass a plan that already excludes past times.
- `cancelAll` removes every pending Subsy reminder.

---

## 3. Pure planner

```dart
List<PlannedReminder> planReminders(
  List<Subscription> subs, NotificationSettings settings, DateTime now);
```
- `enabled == false` → `[]`.
- Omits reminders with `fireTime <= now`.
- One reminder per subscription, id = subscription id; deterministic.

---

## 4. Application wiring

```dart
final notificationSettingsRepositoryProvider; // Provider<NotificationSettingsRepository>
final notificationSchedulerProvider;          // Provider<NotificationScheduler> (LocalNotificationService)
final notificationSettingsProvider;            // StreamProvider<NotificationSettings> (watch)
final notificationSettingsControllerProvider;  // controller: setEnabled/​setLeadDays/​setTime (+ permission)

/// Reactive reschedule: watches subscriptionsProvider + settings, calls scheduler.
void startReminderSync(Ref ref);               // invoked once at startup
```

**Behavioral contract (maps to spec)**
| Scenario | Expected |
|----------|----------|
| settings.enabled false | `cancelAll`, no reminders (FR-009) |
| enable + permission granted | schedule all current subs (FR-009/011) |
| subscription added/edited/deleted | plan recomputed + rescheduled (FR-011/012/013) |
| lead/time changed | reschedule with new values (FR-010) |
| permission denied on enable | enabled stays false; UI warns (FR-015) |
| computed fire in past | omitted (FR-003) |

---

## 5. UI + routing

```dart
class NotificationSettingsScreen extends ConsumerWidget { ... }  // route '/settings/notifications'
// Routes.notificationSettings = '/settings/notifications'
// Dashboard AppBar gains a settings IconButton → push that route.
```
- Renders enable switch, lead-days control, time picker; permission-denied warning + open-settings; dark mode + Turkish (FR-007/015/018).
