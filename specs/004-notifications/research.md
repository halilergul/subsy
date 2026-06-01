# Phase 0 Research: Notifications

Framework fixed by CONSTITUTION.md. Resolves notification-specific design + UI/UX (no Figma). No `NEEDS CLARIFICATION` remain.

---

## D1 — Reminder fire time & zoned scheduling

**Decision**: For each subscription, fire time = `effectiveNextRenewal(sub, now)` (reuse dashboard logic) minus `leadDays`, at `(hour, minute)`. Scheduled with `flutter_local_notifications.zonedSchedule` using a `tz.TZDateTime` in the device's local zone. Add `flutter_timezone` to resolve the IANA zone name; `tz.initializeTimeZones()` + `tz.setLocalLocation(...)` at startup.

**Rationale**: Zoned scheduling fires at the correct wall-clock local time and survives DST (SC-007). Reusing `effectiveNextRenewal` guarantees consistency with what the dashboard shows (FR-002).

**Alternatives**: plain `Duration`-from-now scheduling — drifts across reboots/DST; rejected. Device UTC offset only — breaks on DST; rejected.

---

## D2 — Skip past reminders

**Decision**: The pure planner computes the fire `DateTime`; if it is not after `now`, the reminder is omitted from the plan (FR-003). No immediate/past notifications.

**Rationale**: A renewal sooner than the lead window shouldn't spam an instant alert. Pure + `now` injected → deterministic tests.

---

## D3 — Reminder identity & no duplicates

**Decision**: Notification id = the subscription's Isar id (stable int). Reschedule = `cancelAll()` then schedule the current plan. This guarantees exactly one reminder per subscription and no duplicates on repeated runs (FR-004/005).

**Rationale**: Cancel-all-then-reschedule is the simplest correct strategy at this scale; subscription id as notification id avoids collisions and lets per-subscription cancel work too.

**Alternatives**: per-subscription diffing (cancel/update only changed) — more code for no benefit at tens of records; rejected.

---

## D4 — Settings storage

**Decision**: A single-row Isar collection `NotificationSettingsEntity` (id fixed = 0) behind `NotificationSettingsRepository`. Fields: enabled, leadDays, hour, minute. Defaults: enabled=true on first enable? → store enabled=false until the user turns on (so we don't schedule before permission); leadDays=3, hour=10, minute=0.

**Rationale**: Keeps everything offline in Isar — no new persistence package, consistent with the app. Repository abstraction keeps it swappable and testable (FR-008).

**Alternatives**: `shared_preferences` — idiomatic for prefs but adds a package and a second storage mechanism; rejected to stay Isar-only.

---

## D5 — Reactive rescheduling

**Decision**: A `reminderSync` provider/listener watches `subscriptionsProvider` (core stream) and the settings; on any emission it recomputes the plan and calls `scheduler.scheduleAll(plan)` (or `cancelAll` when disabled). Started in `main()` after tz init.

**Rationale**: Add/edit/delete already flow through the core stream, so reminders stay in sync automatically (FR-011/012/013) with no per-action wiring. Settings changes also retrigger.

**Alternatives**: manual reschedule calls in each use case — scattered, easy to miss; rejected.

---

## D6 — Permission flow

**Decision**: `NotificationScheduler.requestPermission()` wraps the plugin's iOS request + Android 13+ `POST_NOTIFICATIONS`. Requested when the user first enables reminders. If denied, the settings screen shows a Turkish message + a button to open system settings (`app_settings`/plugin capability) and does NOT show reminders as active (FR-014/015). Enabled state is only persisted true when permission is granted.

**Rationale**: Honest state; the user understands why nothing fires.

---

## D7 — Android exact-alarm strategy

**Decision**: Use `AndroidScheduleMode.inexactAllowWhileIdle` for `zonedSchedule`. Avoids the Android 12+ `SCHEDULE_EXACT_ALARM` special permission while still firing within the OS's batching window.

**Rationale**: Spec allows "±a few minutes, OS-dependent" (SC-007). Exact alarms would add a fragile permission for no real benefit on a daily reminder.

**Alternatives**: exact alarms — requires special permission + user trip to settings; rejected for v1.

---

## D8 — Notification content

**Decision**: Title = service name; body = Turkish, e.g. "Netflix aboneliğin N gün sonra yenilenecek — ₺149.99". Reuse `formatMoney`. (FR-006)

---

## UI/UX Decisions (no Figma)

- **Entry point**: a settings icon in the dashboard `AppBar` → `/settings/notifications`.
- **Settings screen**: dark, Turkish. A `SwitchListTile` "Hatırlatmalar"; below (enabled): a stepper/segmented for "Kaç gün önce" (e.g. 0–7) and a "Saat" row opening `showTimePicker`. A short helper line explains reminders are local/offline.
- **Permission denied**: an inline warning card ("Bildirim izni kapalı") + "Ayarları aç" button; the switch reflects the real (off) state.
- **Defaults shown**: 3 gün, 10:00.

> Recorded as the `UIUX-004` equivalent.

---

## Summary

| ID | Topic | Decision |
|----|-------|----------|
| D1 | Fire time | effectiveRenewal − leadDays at H:M, zoned (`timezone` + `flutter_timezone`) |
| D2 | Past | planner omits past fire times |
| D3 | Identity | notif id = subscription id; cancel-all + reschedule |
| D4 | Settings store | single-row Isar collection behind a repository |
| D5 | Reactivity | watch core stream + settings → scheduleAll |
| D6 | Permission | request on enable; honest denied state + open-settings |
| D7 | Android | inexactAllowWhileIdle (no exact-alarm permission) |
| D8 | Content | Turkish title/body with service + amount |
| UI | Settings | dashboard AppBar icon → toggle/lead/time screen |
