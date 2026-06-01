# Quickstart: Notifications

## Prerequisites

- `subscriptions-core` + `dashboard` on `master`.
- Add `flutter_timezone`; `flutter_local_notifications` + `timezone` already present. `flutter pub get`.
- Platform setup: Android notification channel + `POST_NOTIFICATIONS` (Android 13+); iOS notification capability. Initialize timezone in `main()`.

## Build & checks

```bash
flutter pub add flutter_timezone
dart run build_runner build              # regenerate Isar schema (new settings collection)
flutter analyze
flutter test test/unit/reminder_planner_test.dart
flutter test test/unit/reminder_sync_test.dart
flutter test test/integration/notification_settings_repository_test.dart
flutter run                              # enable reminders, set a near lead time, observe a scheduled reminder
```

## Verifying behavior (maps to Success Criteria)

| Check | How | Spec |
|-------|-----|------|
| Correct fire time | plan a sub with known renewal/lead/time → assert fireTime = renewal−lead @ H:M | SC-001 |
| Rolled-forward base | past renewal → plan uses effective (future) date | SC-002 |
| Skip past | renewal sooner than lead → no reminder in plan | SC-002 |
| No duplicates | run plan twice → scheduler receives one per sub (cancelAll+scheduleAll) | SC-001 |
| Toggle off/on | disabled → cancelAll, empty plan; enabled → all scheduled | SC-003 |
| Persist settings | save → reload (temp Isar) → same values | SC-004 |
| Sync on change | seed subs list change → reminder_sync reschedules | SC-005 |
| Permission denied | fake scheduler returns false → enabled stays false, UI warns | SC-006 |

## Test patterns

**Planner (pure):**
```dart
final plan = planReminders([sub(renewal: d, period: monthly)], settings(lead: 3, h: 10), now);
expect(plan.single.fireTime, DateTime(d.year, d.month, d.day - 3, 10, 0));
```

**Sync (fake scheduler + fake settings repo):**
```dart
final scheduler = FakeScheduler();           // records scheduleAll/cancelAll
// enabled=false → expect scheduler.cancelled, scheduler.scheduled empty
// enabled=true  → expect scheduler.scheduled == planReminders(...)
```

**Settings repo:** real Isar in a temp dir (same pattern as `isar_subscription_repository_test`).

## Integration points

- Reuses `effectiveNextRenewal` (dashboard) and `subscriptionsProvider` (core).
- `reminder_sync` is started once in `main()` after tz init.
- Later: a premium tier could add richer reminder options (out of scope).
