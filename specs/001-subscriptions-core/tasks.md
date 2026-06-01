---
description: "Task list for Subscriptions Core (Data Foundation)"
---

# Tasks: Subscriptions Core (Data Foundation)

**Input**: Design documents from `/specs/001-subscriptions-core/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/subscription_repository.md, quickstart.md

**Tests**: INCLUDED — the feature spec explicitly delivers "veri + repository + testler". Tests are a primary deliverable here.

**Organization**: Tasks grouped by user story (US1/US2/US3) so each is independently implementable and testable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependency on an incomplete task)
- **[Story]**: US1 (persistence), US2 (brand recognition), US3 (free-tier limit)

## Path Conventions

Flutter feature-first layout under `lib/features/subscriptions/{domain,data,application}`, shared `lib/core/` + `lib/shared/`, tests under `test/unit` and `test/integration`. Paths match plan.md.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Test scaffolding and codegen pipeline ready (app scaffold already exists from Feature 0).

- [X] T001 Create test directory structure `test/unit/` and `test/integration/` (keep existing `test/widget_test.dart`)
- [X] T002 [P] Verify codegen pipeline runs clean: `dart run build_runner build --delete-conflicting-outputs` (no annotated files yet → should no-op cleanly)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Pure-domain types every user story depends on. No Isar/Flutter-plugin imports in these files.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T003 [P] Define enums in `lib/features/subscriptions/domain/enums.dart` — `Currency` (tryl/usd/eur with `code` getter → "TRY"/"USD"/"EUR"), `BillingPeriod` (weekly/monthly/yearly), `SubscriptionCategory` (streaming/music/cloud/ai/productivity/shopping/other)
- [X] T004 [P] Add `ValidationError` variant to `lib/core/errors/app_error.dart` (sealed `AppError`, Turkish message)
- [X] T005 [P] Add constants in `lib/shared/constants/limits.dart` — `kFreeSubscriptionLimit = 5`, `kSupportedCurrencies` set
- [X] T006 Create immutable `Subscription` domain entity + `copyWith` in `lib/features/subscriptions/domain/subscription.dart` (uses T003; fields per data-model.md)
- [X] T007 Define `SubscriptionRepository` abstract interface in `lib/features/subscriptions/domain/subscription_repository.dart` (uses T006; signatures per contracts/)

**Checkpoint**: Domain foundation ready — US1, US2, US3 can begin.

---

## Phase 3: User Story 1 - Record and reliably keep a subscription (Priority: P1) 🎯 MVP

**Goal**: On-device CRUD that survives app restart, fully offline (the product's core promise).

**Independent Test**: Run `test/integration/isar_subscription_repository_test.dart` — create a subscription, close + reopen Isar, read it back identical; update/delete behave; all with no network.

### Implementation for User Story 1

- [X] T008 [US1] Create `SubscriptionEntity` Isar `@collection` + `fromDomain`/`toDomain` mappers in `lib/features/subscriptions/data/subscription_entity.dart` (enums `@Enumerated(EnumType.name)`, `@Index` on name; per data-model.md)
- [X] T009 [US1] Run `dart run build_runner build --delete-conflicting-outputs` to generate `subscription_entity.g.dart` (depends on T008)
- [X] T010 [US1] Implement `IsarDatabase` in `lib/core/storage/isar_database.dart` — open single Isar instance with `SubscriptionEntitySchema` using `path_provider` app dir (depends on T009)
- [X] T011 [US1] Implement `IsarSubscriptionRepository` in `lib/features/subscriptions/data/isar_subscription_repository.dart` — `add/update/delete/getAll/getById/count/watchAll`, all returning `Result`, mapping IO failures → `StorageError` (depends on T007, T010)
- [X] T012 [US1] Add `isarProvider` (FutureProvider<Isar>) + `subscriptionRepositoryProvider` in `lib/features/subscriptions/application/subscription_providers.dart` (depends on T011)
- [X] T013 [P] [US1] Integration tests in `test/integration/isar_subscription_repository_test.dart` — real Isar in temp dir via `Isar.initializeIsarCore(download: true)`: CRUD round-trip, restart persistence (close+reopen), offline, closed-instance → `StorageError` (depends on T011) — maps SC-001/002/006

**Checkpoint**: US1 fully functional and testable independently (MVP).

---

## Phase 4: User Story 2 - Automatic brand recognition (Priority: P2)

**Goal**: Known services resolve to real brand color, logo, and default category — offline, Turkish-tolerant.

**Independent Test**: Run `test/unit/brand_resolver_test.dart` — all 12 services present; "exxen"/"BLUTV"/"İcloud"/aliases resolve; unknown → null.

### Implementation for User Story 2

- [X] T014 [P] [US2] Create `BrandCatalogEntry` in `lib/features/subscriptions/domain/brand_catalog_entry.dart` (serviceKey, displayName, brandColor int, logoAsset, defaultCategory, aliases) (uses T003)
- [X] T015 [US2] Create const catalog of the 12 mandatory services in `lib/features/subscriptions/domain/brand_catalog.dart` (`kBrandCatalog`, values per data-model.md table) (depends on T014)
- [X] T016 [US2] Implement `BrandResolver` in `lib/features/subscriptions/domain/brand_resolver.dart` — trim + Turkish-aware lowercase (İ/I→i) + alias match → `BrandCatalogEntry?` (depends on T015)
- [X] T017 [US2] Add `brandResolverProvider` to `lib/features/subscriptions/application/subscription_providers.dart` (depends on T016; same file as T012 → sequential)
- [X] T018 [P] [US2] Add 12 brand SVG logos to `assets/logos/<serviceKey>.svg` (one per catalog entry; already registered in pubspec)
- [X] T019 [P] [US2] Brand resolver unit tests in `test/unit/brand_resolver_test.dart` — 12 present, ≥3 TR/casing/alias variants, unknown → null (depends on T016) — maps SC-003

**Checkpoint**: US2 independently functional and testable.

---

## Phase 5: User Story 3 - Free-tier limit enforcement (Priority: P2)

**Goal**: Non-premium capped at 5 via a single un-bypassable use-case funnel; premium unbounded; edits never blocked.

**Independent Test**: Run `test/unit/add_subscription_limit_test.dart` — with a fake repo + premium toggle: 5 add OK, 6th → `LimitReachedError`, delete frees a slot, premium unbounded, update not blocked.

### Implementation for User Story 3

- [X] T020 [P] [US3] Define `PremiumStatus` interface + free stub (`isPremium=false`) in `lib/features/subscriptions/domain/premium_status.dart`
- [X] T021 [P] [US3] Create `SubscriptionDraft` input type in `lib/features/subscriptions/domain/subscription_draft.dart` (uses T003)
- [X] T022 [US3] Implement `SubscriptionValidator` in `lib/features/subscriptions/domain/subscription_validator.dart` — value rules from data-model.md, returns `Result`, Turkish messages (depends on T021, T004)
- [X] T023 [US3] Implement `AddSubscription` use case in `lib/features/subscriptions/domain/usecases/add_subscription.dart` — validate → brand-enrich via `BrandResolver` (serviceKey + default category) → free-tier limit check → `repo.add` (depends on T007, T016, T020, T022, T005)
- [X] T024 [P] [US3] Implement `UpdateSubscription` (no limit check), `DeleteSubscription`, `WatchSubscriptions` use cases in `lib/features/subscriptions/domain/usecases/` (depends on T007, T022)
- [X] T025 [US3] Wire `premiumStatusProvider` (stub), use-case providers, and `subscriptionsProvider` (StreamProvider<List<Subscription>>) in `lib/features/subscriptions/application/subscription_providers.dart` (depends on T023, T024; same file as T012/T017 → sequential)
- [X] T026 [P] [US3] Validator unit tests in `test/unit/subscription_validator_test.dart` (depends on T022) — maps SC-005
- [X] T027 [P] [US3] Limit use-case tests with fake repository + premium toggle in `test/unit/add_subscription_limit_test.dart` (depends on T023) — maps SC-004

**Checkpoint**: All three stories independently functional.

---

## Phase 6: Polish & Cross-Cutting Concerns

- [X] T028 [P] Run `flutter analyze` and resolve any issues across the feature
- [X] T029 Run `flutter test` (unit + integration) green; confirm each Success Criterion (SC-001..006) is covered per quickstart.md
- [X] T030 [P] Note any Isar test-setup gotchas in `.docs/dev-gotchas.md` (e.g. `initializeIsarCore(download: true)`, temp-dir cleanup)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (P1)**: no dependencies.
- **Foundational (P2)**: after Setup — BLOCKS all stories.
- **User Stories (P3–P5)**: after Foundational. US1/US2 are fully independent. US3 reuses US1's repo (at runtime) and US2's resolver (for enrichment), but its **limit logic is independently testable** with a fake repo + empty resolver.
- **Polish (P6)**: after the stories you intend to ship.

### Within Each Story

- US1: T008 → T009 (codegen) → T010 → T011 → T012; T013 after T011.
- US2: T014 → T015 → T016 → {T017, T019}; T018 independent.
- US3: {T020, T021} → T022 → T023; T024 after T022; T025 after T023+T024; T026 after T022; T027 after T023.

### Parallel Opportunities

- Setup: T002 ∥ T001.
- Foundational: T003 ∥ T004 ∥ T005 (then T006 → T007).
- Across stories after Foundational: US1, US2 can proceed in parallel; US3 can start its pure parts (T020/T021/T022 + tests) in parallel, integrating T023 once US2's resolver (T016) exists.
- Tests T013, T019, T026, T027 run in parallel (different files).

---

## Parallel Example: Foundational

```bash
# After Setup, launch the three independent domain files together:
Task: "T003 enums.dart"
Task: "T004 app_error.dart ValidationError"
Task: "T005 limits.dart"
```

## Parallel Example: After Foundational (cross-story)

```bash
# US1 and US2 cores in parallel:
Task: "T008 SubscriptionEntity (data)"          # US1 track
Task: "T014 BrandCatalogEntry + T015 catalog"   # US2 track
Task: "T020 PremiumStatus + T021 SubscriptionDraft"  # US3 pure track
```

---

## Implementation Strategy

### MVP First (User Story 1 only)

1. Phase 1 Setup → 2. Phase 2 Foundational → 3. Phase 3 US1 → **STOP & VALIDATE** (`flutter test test/integration`). US1 alone proves the core promise: durable, offline, on-device storage.

### Incremental Delivery

1. Setup + Foundational → foundation ready.
2. US1 → persistence works (MVP).
3. US2 → brands light up (premium feel).
4. US3 → freemium boundary enforced.
5. Polish → analyze clean, full suite green.

---

## Notes

- [P] = different files, no incomplete dependency. Provider-file tasks (T012/T017/T025) share one file → kept sequential.
- Generated `*.g.dart` are git-ignored; re-run build_runner after model/provider changes (T009 and again if annotations change).
- `domain/` files must NOT import Isar or Flutter plugins (swappability gate from plan.md).
- Commit after each story checkpoint (English messages).
- Pure unit tests (T026/T027/T019) can be written before their impl (TDD) and watched to fail first; Isar integration test (T013) needs the entity to compile.
