# Phase 0 Research: Subscription Form

Framework fixed by CONSTITUTION.md. This resolves form-specific design + UI/UX decisions (no Figma → decided here). No `NEEDS CLARIFICATION` remain.

---

## D1 — Form state & orchestration

**Decision**: A Riverpod `Notifier` `SubscriptionFormController` exposing an immutable `SubscriptionFormState` (mode, field values, `isSubmitting`, `errorMessage`). Methods: field setters, `submit()`, `delete()`. `submit()` builds a `SubscriptionDraft` and calls the existing `AddSubscription`/`UpdateSubscription` use case; maps `Result` → state (success signals close; `Failure` sets `errorMessage` from `AppError.message`).

**Rationale**: Keeps all orchestration testable without widgets (override repo/premium providers). Reuses core rules — no duplication. The widget just binds inputs and renders `errorMessage`/`isSubmitting`.

**Alternatives**: raw `StatefulWidget` + controllers (logic trapped in UI, harder to test — rejected); `flutter_hooks`/`Form` only (would re-implement value rules — rejected, reuse core validator).

---

## D2 — Validation surfacing

**Decision**: Reuse core `SubscriptionValidator` (invoked inside `AddSubscription`/`UpdateSubscription`). The form shows the returned Turkish message in an inline error area near the top / under the relevant field. Lightweight required-field affordances (e.g. disable save until name+amount non-empty) improve UX but the source of truth is the domain validator on submit.

**Rationale**: Single rule source (FR-007). One message per first failing rule is acceptable for this small form.

**Alternatives**: per-field `TextFormField` validators duplicating rules — rejected (drift risk).

---

## D3 — Add vs edit mode

**Decision**: One screen, two modes. `SubscriptionFormController` is seeded with an optional `Subscription` (null = add). Edit pre-fills fields and preserves identity on save via `UpdateSubscription`. Delete is rendered only when editing.

**Rationale**: Matches spec (single form). Reuses identical UI; the only differences are pre-fill, the use case called, and the delete affordance.

---

## D4 — Routing & entry points

**Decision**: Two `go_router` routes on the central router:
- `/subscription/add` → form in add mode.
- `/subscription/edit` → form in edit mode, receiving the `Subscription` via `GoRouterState.extra` (the dashboard already holds the object, so no refetch).
Dashboard wiring: the FAB + empty-state CTA push `/subscription/add` (replacing the placeholder SnackBar); `PaymentListItem.onTap` pushes `/subscription/edit` with its subscription.

**Rationale**: `extra` passes the domain object directly — simplest, avoids an id round-trip. Centralized routes keep navigation consistent.

**Alternatives**: `/subscription/edit/:id` + refetch by id — extra indirection for no benefit here; rejected.

---

## D5 — Result handling

**Decision**: `submit()`/`delete()` map `Result`:
- `Success` → controller flags success; the screen pops; the dashboard updates automatically (reactive stream — no manual refresh, FR-013).
- `Failure(ValidationError)` → inline Turkish message (FR-007).
- `Failure(LimitReachedError)` → a clear Turkish "limit reached" message pointing toward premium (informational; real paywall later) (FR-008).
- `Failure(StorageError/other)` → Turkish non-technical error (FR-009).

---

## D6 — Delete confirmation

**Decision**: `showDialog` `AlertDialog` ("Aboneliği sil?" + Vazgeç/Sil). Only confirmed deletes call `DeleteSubscription` (FR-012/SC-006).

---

## D7 — Live brand preview

**Decision**: As the name field changes, resolve via `BrandResolver` and render the shared `BrandAvatar` (logo+color for matches, neutral initial otherwise) plus, when matched, auto-default the category (user can override). Reuses existing widgets/logic.

**Rationale**: Premium feel; zero new logic (FR-004/FR-005/SC-005).

---

## UI/UX Decisions (no Figma — decided here)

- **Layout**: full-screen pushed route, `AppBar` titled "Abonelik ekle" / "Aboneliği düzenle", a `Kaydet` action (app bar or bottom button). Scrollable `Column`/`ListView` of fields with 16 padding, 16 gaps.
- **Brand preview**: a 56–64 `BrandAvatar` near the top, updating as the name is typed; service name field directly below.
- **Fields order**: name → (brand preview) → amount + currency (row: amount field + `CurrencySelector`) → period (`PeriodSelector` segmented) → next renewal date (tappable field opening `showDatePicker`) → optional: category dropdown, start date, notes (multiline).
- **Pickers**: currency & period as `SegmentedButton` (few values, fast); category as `DropdownButton`; date via `showDatePicker` (dark themed).
- **Errors**: inline error text (theme error color) under the form / relevant field; limit message as a highlighted banner with a subtle "premium" hint.
- **Save**: primary `FilledButton` ("Kaydet"); disabled while `isSubmitting`; spinner on the button during save.
- **Delete** (edit only): a destructive `TextButton`/icon ("Sil", error color) → confirm dialog.
- **Dark mode**: surfaces consistent with dashboard (`#0E0E12` / `#17171D`).

> Recorded here as the `UIUX-003` equivalent since the user proceeds straight to `/speckit-plan`.

---

## Summary

| ID | Topic | Decision |
|----|-------|----------|
| D1 | State | Riverpod `Notifier` form controller, testable submit/delete |
| D2 | Validation | Reuse core validator; show its Turkish message |
| D3 | Modes | One screen; optional seed Subscription; delete only when editing |
| D4 | Routing | `/subscription/add` + `/subscription/edit` (extra: Subscription) |
| D5 | Result | success→pop; typed failures→Turkish messages |
| D6 | Delete | confirm dialog before DeleteSubscription |
| D7 | Brand preview | live `BrandResolver` + shared `BrandAvatar`, auto category |
| UI | Look & feel | full-screen form, segmented pickers, dark, Turkish |
