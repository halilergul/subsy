---
description: "Task list for Renewal Reminder Notifications"
---

# Tasks: Renewal Reminder Notifications

**Input**: Design documents from `/specs/004-notifications/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/notifications.md, quickstart.md

**Tests**: INCLUDED — the pure planner and the orchestration are the critical path (unit tests with fakes); settings persistence via temp-Isar integration. The OS plugin adapter is thin and not unit-tested.

**Organization**: US1 (scheduling) / US2 (settings) / US3 (reactive sync) / US4 (permission). Reuses `subscriptions-core` stream + dashboard `effectiveNextRenewal`.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelizable (different files, no incomplete dependency)
- **[Story]**: US1 (be reminded), US2 (settings), US3 (sync), US4 (permission)

## Path Conventions

`lib/features/notifications/{domain,data,application,presentation}`, route in `lib/app/router/app_router.dart`, schema in `lib/core/storage/isar_database.dart`, startup in `lib/main.dart`. Tests in `test/unit` and `test/integration`.

---

## Phase 1: Setup

- [X] T001 Add `flutter_timezone` dependency (`flutter pub add flutter_timezone`)
- [X] T002 [P] Platform config: Android notification channel + `POST_NOTIFICATIONS` (Android 13+) in `android/app/src/main/AndroidManifest.xml`; iOS notification setup in `ios/Runner/Info.plist`/AppDelegate
- [X] T003 Initialize timezones in `lib/main.dart` — `tz.initializeTimeZones()` + `tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()))` before `runApp`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Domain types/interfaces shared by all stories. No plugin/Isar imports in these files.

- [X] T004 [P] `NotificationSettings` entity + default consts (`kDefaultLeadDays=3`, `kDefaultHour=10`, `kDefaultMinute=0`, `kMaxLeadDays=7`) in `lib/features/notifications/domain/notification_settings.dart`
- [X] T005 [P] `PlannedReminder` value (subscriptionId, fireTime, title, body) in `lib/features/notifications/domain/planned_reminder.dart`
- [X] T006 [P] `NotificationScheduler` interface (requestPermission/hasPermission/scheduleAll/cancelAll) in `lib/features/notifications/domain/notification_scheduler.dart`
- [X] T007 [P] `NotificationSettingsRepository` interface (load/save/watch) in `lib/features/notifications/domain/notification_settings_repository.dart`

**Checkpoint**: Domain shell ready.

---

## Phase 3: User Story 1 - Be reminded before a renewal (Priority: P1) 🎯 MVP

**Goal**: Compute and schedule a correct, future, de-duplicated reminder per subscription.

**Independent Test**: `planReminders` over seeded subs/settings → correct fireTimes, past skipped, disabled→[]; orchestration with a fake scheduler schedules exactly that plan.

### Implementation for User Story 1

- [X] T008 [US1] Pure `planReminders(subs, settings, now)` in `lib/features/notifications/domain/reminder_planner.dart` — uses `effectiveNextRenewal` (dashboard) + `formatMoney`; omits past; `[]` when disabled (depends on T004, T005)
- [X] T009 [US1] `LocalNotificationService` (impl `NotificationScheduler`) in `lib/features/notifications/data/local_notification_service.dart` — `flutter_local_notifications` + `timezone` zonedSchedule (`inexactAllowWhileIdle`, id = subscriptionId), `cancelAll` (depends on T006)
- [X] T010 [US1] `rescheduleAll(scheduler, subs, settings, now)` orchestration helper in `lib/features/notifications/application/reminder_sync.dart` — cancelAll then scheduleAll(plan) when enabled+permitted, else cancelAll (depends on T008, T009)
- [X] T011 [P] [US1] Planner unit tests `test/unit/reminder_planner_test.dart` — fire time math, rolled-forward base, skip past, disabled→empty (depends on T008) — maps SC-001/002
- [X] T012 [P] [US1] Orchestration unit tests `test/unit/reminder_sync_test.dart` with a `FakeScheduler` — enabled schedules the plan (no dups), disabled cancels all (depends on T010) — maps SC-001/003

**Checkpoint**: Given subs+settings, correct reminders are scheduled (testable end-to-end with a fake). MVP core.

---

## Phase 4: User Story 2 - Control reminders from settings (Priority: P1)

**Goal**: Persisted on/off + lead days + time, with a settings screen.

**Independent Test**: Save settings → reload from temp Isar → identical; screen renders current values.

### Implementation for User Story 2

- [X] T013 [US2] `NotificationSettingsEntity` Isar `@collection` (fixed `id = 0`) + mapper in `lib/features/notifications/data/notification_settings_entity.dart`
- [X] T014 [US2] Register `NotificationSettingsEntitySchema` in `lib/core/storage/isar_database.dart` and run `dart run build_runner build` (depends on T013)
- [X] T015 [US2] `IsarNotificationSettingsRepository` (load→defaults if empty, save upsert, watch) in `lib/features/notifications/data/isar_notification_settings_repository.dart` (depends on T007, T014)
- [X] T016 [US2] Providers (settings repo, scheduler, `notificationSettingsProvider` stream, settings controller setEnabled/setLeadDays/setTime) in `lib/features/notifications/application/notification_providers.dart` (depends on T015, T009)
- [X] T017 [US2] `NotificationSettingsScreen` (SwitchListTile + lead stepper + time picker, dark/Turkish) in `lib/features/notifications/presentation/notification_settings_screen.dart`; add `Routes.notificationSettings` in `app_router.dart`; add a settings `IconButton` to the dashboard `AppBar` (depends on T016)
- [X] T018 [P] [US2] Settings repo integration test `test/integration/notification_settings_repository_test.dart` — real Isar temp dir, save/reload/defaults (depends on T015) — maps SC-004

**Checkpoint**: User can configure reminders; settings persist.

---

## Phase 5: User Story 3 - Reminders stay in sync with changes (Priority: P2)

**Goal**: Add/edit/delete and settings changes reschedule automatically.

**Independent Test**: Emitting a changed subscription list (or settings) triggers `rescheduleAll` with the new plan.

### Implementation for User Story 3

- [X] T019 [US3] `startReminderSync(ref)` in `lib/features/notifications/application/reminder_sync.dart` — listen to `subscriptionsProvider` + `notificationSettingsProvider`, call `rescheduleAll` on change; invoke once in `lib/main.dart` after tz init (depends on T010, T016)
- [X] T020 [P] [US3] Sync reaction test (extend `test/unit/reminder_sync_test.dart`) — changed subs/settings → reschedule invoked with new plan (depends on T019) — maps SC-005

**Checkpoint**: Reminders track subscription + settings changes.

---

## Phase 6: User Story 4 - Permission handling (Priority: P2)

**Goal**: Request permission on enable; honest denied state.

**Independent Test**: Fake scheduler permission=false → enabling keeps `enabled=false`; UI shows warning.

### Implementation for User Story 4

- [X] T021 [US4] Implement `requestPermission`/`hasPermission` in `local_notification_service.dart`; in the settings controller, when enabling, request permission and only persist `enabled=true` if granted (depends on T009, T016; same files → sequential)
- [X] T022 [US4] Settings screen: when permission denied, show a Turkish warning card + "Ayarları aç" and keep the switch off (depends on T017, T021; same file → sequential)
- [X] T023 [P] [US4] Controller test — enable with permission denied keeps `enabled=false` (FakeScheduler permission=false) (depends on T021) — maps SC-006

**Checkpoint**: Permission-aware, trustworthy enable flow.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T024 [P] Run `flutter analyze` and resolve issues across the feature
- [X] T025 Run `flutter test` (unit + integration) green; confirm SC-001..007 coverage per quickstart.md
- [ ] T026 [P] Manual device verify (`flutter run`): enable reminders, near lead time → observe a scheduled local notification; toggle off clears it; deny permission → warning (device/simulator)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)** → **Foundational (P2)** → **Stories (P3–P6)** → **Polish (P7)**.
- `reminder_sync.dart` extended across T010→T019 (sequential). `local_notification_service.dart` across T009→T021 (sequential). `notification_providers.dart` T016 then used by T019/T021. Settings screen T017→T022 (sequential). `main.dart` T003→T019. `isar_database.dart` T014.

### Within Each Story

- US1: T008 ∥ T009 → T010; tests T011 (after T008), T012 (after T010).
- US2: T013 → T014 → T015 → T016 → T017; test T018 (after T015).
- US3: T019 (after T010+T016); test T020.
- US4: T021 (after T009+T016) → T022; test T023.

### Parallel Opportunities

- Foundational T004 ∥ T005 ∥ T006 ∥ T007.
- US1 T008 (planner) ∥ T009 (adapter); their tests T011 ∥ T012.
- Across stories: US1 planner/tests can proceed while US2 settings store is built (different files). The reactive wiring (US3) and permission (US4) come after the providers exist.

---

## Parallel Example: Foundational

```bash
Task: "T004 NotificationSettings entity"
Task: "T005 PlannedReminder value"
Task: "T006 NotificationScheduler interface"
Task: "T007 NotificationSettingsRepository interface"
```

---

## Implementation Strategy

### MVP First (User Story 1 + minimal settings)

Setup → Foundational → US1 (planner + scheduler + orchestration, tested with fakes). To actually fire on a device you also need US2 (settings to enable) — so the realistic first shippable slice is US1 + US2. US1 alone is fully unit-testable as the core.

### Incremental Delivery

1. Setup + Foundational.
2. US1 → planning/scheduling correct (tested).
3. US2 → user can enable/configure; persists.
4. US3 → auto-reschedule on changes.
5. US4 → permission-aware enable.
6. Polish → analyze, suite green, device verify.

---

## Notes

- [P] = different files, no incomplete dependency. Shared files (`reminder_sync`, `local_notification_service`, `notification_providers`, settings screen, `main.dart`, `isar_database`) serialize.
- Reuse only: `effectiveNextRenewal` (dashboard), `subscriptionsProvider` (core), `formatMoney` (shared). No new renewal logic.
- Scheduler is the single platform-coupled seam; everything logical is tested via the `FakeScheduler`.
- Commit per story checkpoint (English messages).
