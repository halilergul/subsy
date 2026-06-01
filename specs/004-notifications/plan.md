# Implementation Plan: Renewal Reminder Notifications

**Branch**: `004-notifications` | **Date**: 2026-06-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-notifications/spec.md`

## Summary

Schedule local, on-device reminders a configurable number of days before each subscription's effective next renewal, at a chosen time. A small settings screen controls enable/lead-days/time (persisted on-device via Isar). The pure scheduling logic (compute reminder time, skip past, map subscriptions → reminders) is unit-tested; the platform notification API and the OS scheduler sit behind a `NotificationScheduler` interface so the orchestration is testable with a fake. Rescheduling is reactive: a provider watches the core subscription stream + settings and re-plans on any change. No Figma → UI/UX decided in research.md.

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (stable)

**Primary Dependencies**: `flutter_local_notifications` + `timezone` (already in pubspec) for scheduling; **NEW**: `flutter_timezone` (resolve the device IANA zone for correct local fire times). `flutter_riverpod` for wiring; reuses `subscriptions-core` stream and the dashboard `effectiveNextRenewal`. Isar (`isar_community`) for the single settings record.

**Storage**: One Isar collection holding the single `NotificationSettings` row (stays offline + consistent with the rest of the app; no new storage package).

**Testing**: `flutter_test` — pure unit tests for the reminder planner (compute time, skip past, map list); orchestration tests with a fake `NotificationScheduler` + fake settings repo + injected subscription list; Isar settings repo via temp-dir integration (same pattern as core). The platform plugin itself is not unit-tested (thin adapter behind the interface).

**Target Platform**: iOS 13+ / Android (API 23+), offline, dark mode, Turkish UI.

**Performance Goals**: Scheduling a personal-scale set (tens) is instant; reschedule = cancel-all + schedule-all, O(n).

**Constraints**: Fully offline (no push/server, FR-016); reminders never scheduled in the past (FR-003); free-tier (not gated); reminder fire time correct across DST (use `timezone` zoned scheduling).

**Scale/Scope**: One settings screen + settings store + scheduler service + pure planner + platform adapter + reactive wiring + tests.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Business logic separated from UI | ✅ | Pure `reminder_planner`; orchestration service; platform behind interface; screen thin |
| Service/platform access via abstraction | ✅ | `NotificationScheduler` interface wraps the plugin; `NotificationSettingsRepository` wraps Isar |
| Reuse over duplication | ✅ | Reuses core subscription stream + dashboard `effectiveNextRenewal`; no new renewal logic |
| Components get data via provider | ✅ | Settings + scheduler exposed via Riverpod; reactive reschedule off the stream |
| Every feature tested; critical path mandatory | ✅ | Planner + orchestration + settings persistence tested |
| No magic numbers | ✅ | Defaults (leadDays=3, 10:00) named consts |
| Typed error handling, Turkish messages | ✅ | Permission-denied + failures → Turkish, `Result`/`AppError` where applicable |
| No secrets | ✅ | None |
| Offline / no backend | ✅ | Local notifications only |
| Dark mode / Turkish UI | ✅ | Settings screen |

**Initial gate: PASS.** No violations → Complexity Tracking empty.

## Project Structure

### Documentation (this feature)

```text
specs/004-notifications/
├── plan.md · research.md · data-model.md · quickstart.md
├── contracts/notifications.md
├── checklists/requirements.md
└── tasks.md   (later)
```

### Source Code (repository root)

```text
lib/features/notifications/
├── domain/
│   ├── notification_settings.dart            # entity (enabled, leadDays, hour, minute) + defaults
│   ├── notification_settings_repository.dart # interface
│   ├── notification_scheduler.dart           # interface: requestPermission/scheduleAll/cancelAll
│   ├── planned_reminder.dart                 # value: subscriptionId, fireTime, title, body
│   └── reminder_planner.dart                 # PURE: plan(subs, settings, now) → List<PlannedReminder> (skips past)
├── data/
│   ├── notification_settings_entity.dart     # Isar @collection (single row) + mapper
│   ├── isar_notification_settings_repository.dart
│   └── local_notification_service.dart       # flutter_local_notifications + timezone adapter (impl of scheduler)
├── application/
│   ├── notification_providers.dart           # settings + scheduler + settings-controller providers
│   └── reminder_sync.dart                    # reactive: watch(subscriptionsProvider)+settings → scheduler.scheduleAll
└── presentation/
    └── notification_settings_screen.dart      # toggle + lead days + time; permission feedback

lib/app/router/app_router.dart                 # add /settings/notifications route
lib/core/storage/isar_database.dart            # register NotificationSettingsEntitySchema
lib/main.dart                                   # tz init + start reminder sync

test/unit/
├── reminder_planner_test.dart                 # compute/skip-past/map
└── reminder_sync_test.dart                     # orchestration with fake scheduler + fake settings + seeded subs
test/integration/
└── notification_settings_repository_test.dart  # real Isar temp dir
```

**Structure Decision**: New `lib/features/notifications/` with the established `domain`/`data`/`application`/`presentation` split. The only hard-to-test part — the OS plugin — is isolated in `local_notification_service.dart` behind the `NotificationScheduler` interface; everything that carries logic (`reminder_planner` pure fn, `reminder_sync` orchestration) is testable with fakes. Settings persist through a `NotificationSettingsRepository` (Isar impl, swappable). Reactivity reuses the core subscription stream, so add/edit/delete reschedule automatically (FR-011..013) with no extra hooks.

## Complexity Tracking

> No constitution violations. Section intentionally empty.
