# Implementation Plan: Subscriptions Core (Data Foundation)

**Branch**: `001-subscriptions-core` | **Date**: 2026-06-01 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-subscriptions-core/spec.md`

## Summary

Build the on-device data foundation for Subsy: a `Subscription` domain model, a swappable local-storage repository (Isar implementation behind a domain interface), an offline brand catalog with a Turkish-tolerant resolver, and the free-tier limit rule (max 5 for non-premium) enforced in a single use-case funnel. No UI; acceptance is verified by unit + integration tests at the data/domain layer. All technical choices are already fixed in `.docs/CONSTITUTION.md`, so there are no open clarifications.

## Technical Context

**Language/Version**: Dart 3.11 / Flutter 3.41 (stable)

**Primary Dependencies**: `flutter_riverpod` 3.x + `riverpod_annotation` (state/DI), `isar_community` 3.3.2 + `isar_community_flutter_libs` (local DB), `path_provider` (db location), `intl` (formatting — used by later features). Codegen: `build_runner`, `riverpod_generator`, `isar_community_generator`.

**Storage**: Isar (NoSQL, on-device), accessed only through the `SubscriptionRepository` domain interface so it can be swapped (Drift/Hive) without touching domain or UI.

**Testing**: `flutter_test` for unit tests (validator, brand resolver, free-tier use case with a fake repository); Isar integration tests run against a real Isar instance in a temp directory via `Isar.initializeIsarCore(download: true)`.

**Target Platform**: iOS 13+ / Android (API 23+), offline-only.

**Project Type**: Mobile app (Flutter), feature-first layered architecture.

**Performance Goals**: Instant local reads/writes for a personal-scale dataset (tens of records). No frame-budget concern in this layer (no UI).

**Constraints**: 100% offline — zero network calls in this feature. Typed `Result`/`AppError` everywhere (no uncaught exceptions). Turkish-tolerant name matching (ı/İ/ş/ç/ğ/ö/ü).

**Scale/Scope**: Single user, single device. Free tier ≤ 5 subscriptions; premium unbounded (realistically < a few hundred). 12 mandatory catalog entries at launch.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Evaluated against `.docs/CONSTITUTION.md`:

| Principle | Status | Notes |
|-----------|--------|-------|
| Business logic separated from UI (domain/service layer) | ✅ | Domain entity + use cases; data layer isolated; no UI here |
| Service/storage access only via abstraction | ✅ | `SubscriptionRepository` interface; Isar hidden behind it |
| Components get data via provider, not direct fetch | ✅ | Riverpod providers expose use cases; raw repo not public |
| Every feature tested; critical path mandatory | ✅ | Unit + integration tests are the deliverable of this feature |
| No magic numbers/strings | ✅ | Free limit, supported currencies, catalog keys are named consts/enums |
| Typed error handling, no leaked technical detail | ✅ | `Result<T>` + sealed `AppError` with Turkish messages (already in `core/`) |
| No secrets in source | ✅ | No keys/secrets in this feature |
| Offline / no backend (anti-goal: server) | ✅ | Zero network; Isar local only |
| Turkish character support | ✅ | Resolver folds TR characters; tests cover variants |
| English code / Turkish UI | ✅ | Code English; no UI strings here (user messages live in `AppError`) |

**Initial gate: PASS.** No violations → Complexity Tracking left empty.

## Project Structure

### Documentation (this feature)

```text
specs/001-subscriptions-core/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (Dart interface contracts)
│   └── subscription_repository.md
├── checklists/
│   └── requirements.md  # from /speckit-specify
└── tasks.md             # /speckit-tasks output (NOT created here)
```

### Source Code (repository root)

```text
lib/
├── core/
│   ├── result/result.dart            # Result<T> (exists)
│   ├── errors/app_error.dart         # AppError (exists; extend if needed)
│   └── storage/
│       └── isar_database.dart        # Opens Isar with schemas; provides instance
├── features/subscriptions/
│   ├── domain/
│   │   ├── subscription.dart         # Immutable domain entity + copyWith
│   │   ├── enums.dart                # BillingPeriod, Currency, SubscriptionCategory
│   │   ├── subscription_draft.dart   # Validated input for create/update
│   │   ├── subscription_validator.dart
│   │   ├── subscription_repository.dart   # Abstract interface (the contract)
│   │   ├── brand_catalog_entry.dart
│   │   ├── brand_catalog.dart        # const list of 12+ entries
│   │   ├── brand_resolver.dart       # name → entry (TR-tolerant, aliases)
│   │   └── usecases/
│   │       ├── add_subscription.dart # enforces validation + free-tier limit
│   │       ├── update_subscription.dart
│   │       ├── delete_subscription.dart
│   │       └── watch_subscriptions.dart
│   ├── data/
│   │   ├── subscription_entity.dart  # @collection Isar model + mapper
│   │   └── isar_subscription_repository.dart  # implements interface
│   └── application/
│       └── subscription_providers.dart  # Riverpod wiring (isar, repo, usecases, premium stub)
└── shared/
    └── constants/limits.dart         # kFreeSubscriptionLimit = 5, supported currencies

assets/logos/                          # 12 bundled SVG brand logos (added in implementation)

test/
├── unit/
│   ├── subscription_validator_test.dart
│   ├── brand_resolver_test.dart
│   └── add_subscription_limit_test.dart   # uses fake repository
└── integration/
    └── isar_subscription_repository_test.dart  # real Isar in temp dir
```

**Structure Decision**: Feature-first layering inside `lib/features/subscriptions/` with three layers — `domain` (pure Dart: entity, enums, interface, use cases, catalog/resolver), `data` (Isar model + repository impl + mapper), `application` (Riverpod providers). The repository interface lives in `domain`; the Isar implementation in `data`. UI consumes only `application` providers. This honors the constitution's "swappable, reusable, app-agnostic" goal: `domain` has zero Isar/Flutter-plugin imports, so the storage engine can be replaced by writing a new `data` implementation.

## Complexity Tracking

> No constitution violations. Section intentionally empty.

The domain↔data separation (entity + Isar model + mapper) is deliberate, not accidental complexity: it is the mechanism that makes storage swappable, which is an explicit constitution requirement, not a speculative abstraction.
