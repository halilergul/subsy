---
description: "Task list for Subscription Form (Add / Edit / Delete)"
---

# Tasks: Subscription Form (Add / Edit / Delete)

**Input**: Design documents from `/specs/003-subscription-form/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/subscription_form.md, quickstart.md

**Tests**: INCLUDED — controller logic is the critical path (unit tests with fake repo + premium toggle); widget tests cover the key form flows.

**Organization**: Grouped by user story (US1 add / US2 edit / US3 delete). All business rules reuse `subscriptions-core`; this feature adds no rules or persistence.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: parallelizable (different files, no incomplete dependency)
- **[Story]**: US1 (add), US2 (edit), US3 (delete)

## Path Conventions

Form in `lib/features/subscriptions/{application,presentation}`, routes in `lib/app/router/app_router.dart`, dashboard wiring in `lib/features/dashboard/presentation`. Tests in `test/unit` and `test/widget`.

---

## Phase 1: Setup

- [X] T001 Confirm baseline green (`flutter analyze` + `flutter test`); no new packages required for this feature

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared form shell every story uses — state, controller skeleton, field widgets, and the screen layout (save/delete wired per-story later).

**⚠️ CRITICAL**: Blocks all stories.

- [X] T002 Create immutable `SubscriptionFormState` (+ copyWith, `mode`, all fields, `isSubmitting`, `errorMessage`, `saved`) in `lib/features/subscriptions/application/subscription_form_controller.dart` (per data-model.md)
- [X] T003 Add `SubscriptionFormController` (`NotifierProvider.autoDispose.family<…, Subscription?>`) with `build()` seeding (add defaults / edit pre-fill) and all field setters in the same file (depends on T002)
- [X] T004 [P] Create `CurrencySelector` (SegmentedButton<Currency>) in `lib/features/subscriptions/presentation/widgets/currency_selector.dart`
- [X] T005 [P] Create `PeriodSelector` (SegmentedButton<BillingPeriod>) in `lib/features/subscriptions/presentation/widgets/period_selector.dart`
- [X] T006 [P] Create `BrandPreview` (resolves name via `BrandResolver` → shared `BrandAvatar`) in `lib/features/subscriptions/presentation/widgets/brand_preview.dart`
- [X] T007 Create `SubscriptionFormScreen` skeleton in `lib/features/subscriptions/presentation/subscription_form_screen.dart` — `ConsumerWidget`, renders all fields bound to the controller (name, BrandPreview, amount+CurrencySelector, PeriodSelector, date via showDatePicker, optional category/startDate/notes), dark mode + Turkish labels; "Kaydet" button present (action wired in US1) (depends on T003, T004, T005, T006)

**Checkpoint**: Form shell renders and is bound to state — stories can wire behavior.

---

## Phase 3: User Story 1 - Add a new subscription (Priority: P1) 🎯 MVP

**Goal**: Fill the form and save a new subscription; it appears on the dashboard.

**Independent Test**: Open add form (override repo), fill valid values, save → subscription persisted, screen pops; invalid → Turkish message, nothing saved; free user at 5 → limit message.

### Implementation for User Story 1

- [X] T008 [US1] Implement `submit()` add path in `subscription_form_controller.dart` — build `SubscriptionDraft` (parse amountText), call `addSubscriptionProvider`, map `Result` → `saved` / `errorMessage` (depends on T003)
- [X] T009 [US1] Wire the "Kaydet" button in `subscription_form_screen.dart` → `submit()`; pop on `saved`; show `errorMessage` (validation/limit/storage) inline; disable + spinner while `isSubmitting` (depends on T007, T008)
- [X] T010 [US1] Add `Routes.addSubscription = '/subscription/add'` → `SubscriptionFormScreen()` in `lib/app/router/app_router.dart` (depends on T007)
- [X] T011 [US1] Wire dashboard add entry points → push add route in `lib/features/dashboard/presentation/dashboard_screen.dart` (FAB + empty-state CTA), replacing the placeholder SnackBar (depends on T010)
- [X] T012 [P] [US1] Controller unit tests `test/unit/subscription_form_controller_test.dart` — add success, validation failure (no write), limit reached (fake repo + FakePremium) (depends on T008) — maps SC-002/004
- [X] T013 [P] [US1] Widget test `test/widget/subscription_form_screen_test.dart` — add renders, invalid save shows Turkish message, valid save pops (depends on T009)

**Checkpoint**: Add loop works end-to-end (dashboard → form → saved → appears). MVP.

---

## Phase 4: User Story 2 - Edit an existing subscription (Priority: P2)

**Goal**: Open a stored subscription pre-filled, change it, save → updated in place.

**Independent Test**: Seed a subscription, open in edit mode → fields pre-filled; change amount/date, save → same record updated; limit does not block.

### Implementation for User Story 2

- [X] T014 [US2] Extend `submit()` for edit mode in `subscription_form_controller.dart` — when `mode == edit`, call `updateSubscriptionProvider(editingId, draft)`; confirm `build()` pre-fill from the seeded `Subscription` (depends on T008; same file → sequential)
- [X] T015 [US2] Add `Routes.editSubscription = '/subscription/edit'` (extra: `Subscription`) → `SubscriptionFormScreen(subscription: ...)` in `app_router.dart` (depends on T010; same file → sequential)
- [X] T016 [US2] Wire `PaymentListItem.onTap` → push edit route with the subscription, in `dashboard_screen.dart` (pass `onTap` to the item) (depends on T015, T011; same file → sequential)
- [X] T017 [P] [US2] Controller unit tests (edit) — pre-fill correctness, update success preserves id, limit NOT applied on edit (depends on T014) — maps SC-004
- [X] T018 [P] [US2] Widget test — edit mode renders pre-filled fields (depends on T014)

**Checkpoint**: Add + edit both work via the same screen.

---

## Phase 5: User Story 3 - Delete a subscription (Priority: P2)

**Goal**: Delete from edit mode, with confirmation.

**Independent Test**: Open edit, tap Sil → confirm dialog; confirm → removed (dashboard no longer shows it); cancel → nothing removed.

### Implementation for User Story 3

- [X] T019 [US3] Implement `delete()` in `subscription_form_controller.dart` — call `deleteSubscriptionProvider(editingId)`, map `Result` → `saved` / `errorMessage` (depends on T014; same file → sequential)
- [X] T020 [US3] Add a destructive "Sil" action (edit mode only) + confirm `AlertDialog` in `subscription_form_screen.dart` → on confirm call `delete()`, pop on `saved` (depends on T009, T019; same file → sequential)
- [X] T021 [P] [US3] Controller unit test — delete success sets saved; freed slot lets a subsequent add succeed (depends on T019)
- [X] T022 [P] [US3] Widget test — delete shows confirm dialog; confirm triggers removal; cancel does nothing (depends on T020)

**Checkpoint**: Full add/edit/delete lifecycle works.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T023 [P] Run `flutter analyze` and resolve issues across the feature
- [X] T024 Run `flutter test` (unit + widget) green; confirm SC-001..006 coverage per quickstart.md
- [ ] T025 [P] Manual full-loop verify (`flutter run`): dashboard → add → appears → edit → delete; dark mode + Turkish (device/simulator)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)** → **Foundational (P2)** → **Stories (P3–P5)** → **Polish (P6)**.
- The controller (`subscription_form_controller.dart`) is extended across T003→T008→T014→T019 (sequential, same file). The screen (`subscription_form_screen.dart`) across T007→T009→T020 (sequential). The router across T010→T015 (sequential). The dashboard screen across T011→T016 (sequential).

### Within Each Story

- US1: T008 → T009 → T010 → T011; tests T012 (after T008), T013 (after T009).
- US2: T014 → T015 → T016; tests T017 (after T014), T018 (after T014).
- US3: T019 → T020; tests T021 (after T019), T022 (after T020).

### Parallel Opportunities

- Foundational field widgets: T004 ∥ T005 ∥ T006 (then T007).
- Test tasks within a story (T012∥T013, T017∥T018, T021∥T022) are different files → parallel.
- Stories are mostly sequential here because they share the controller/screen/router files; the independent parts are the per-story tests and the field widgets.

---

## Parallel Example: Foundational field widgets

```bash
Task: "T004 CurrencySelector"
Task: "T005 PeriodSelector"
Task: "T006 BrandPreview"
```

---

## Implementation Strategy

### MVP First (User Story 1)

Setup → Foundational → US1 → **STOP & VALIDATE** (`flutter test`, then `flutter run`: dashboard → add → appears). The add loop is the core write path and a complete MVP.

### Incremental Delivery

1. Setup + Foundational (form shell).
2. US1 → add works (MVP).
3. US2 → edit works.
4. US3 → delete works.
5. Polish → analyze clean, suite green, full-loop verified.

---

## Notes

- [P] = different files, no incomplete dependency. Controller/screen/router/dashboard files are shared → those tasks serialize.
- Reuse only: call core use cases (`add`/`update`/`delete`), `SubscriptionValidator` (inside them), `BrandResolver`, shared `BrandAvatar`. Do NOT re-implement rules.
- Controller tests override `subscriptionRepositoryProvider` (the in-memory fake) and `premiumStatusProvider` (FakePremium) — same pattern as the core limit test.
- Commit per story checkpoint (English messages).
