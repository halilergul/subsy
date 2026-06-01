# Phase 0 Research: Subscriptions Core

All framework-level choices (Flutter, Riverpod, Isar community) are already decided in `.docs/CONSTITUTION.md`. This document resolves the **design-level** decisions specific to this feature. No `NEEDS CLARIFICATION` markers remain.

---

## D1 — Money representation: `double` vs minor-units int

**Decision**: Store amount as **`double`** in both domain and Isar, with display rounding handled later via `intl`.

**Rationale**: The dataset is tiny (tens of records) and the only aggregation is summing a handful of monthly amounts for the dashboard/statistics. Float error at this scale is far below one kuruş after rounding for display. `double` keeps the model and user input (`149.99`) trivial. Validation rejects non-positive / non-finite values.

**Alternatives considered**:
- *Minor-units `int` (kuruş/cents)*: numerically exact, but adds parse/format mapping everywhere for a precision need this app does not have. Revisit only if multi-currency exact accounting is ever required.
- *`Decimal` package*: correct but heavyweight; unjustified at this scale.

---

## D2 — Stable identifier

**Decision**: Use Isar's auto-increment `Id id` as the stable identifier, surfaced on the domain `Subscription` as `int? id` (null = not yet persisted). Updates re-`put()` with the same id, so the id never changes (satisfies FR-003).

**Rationale**: Isar ids are stable across updates and unique per collection; no need for a separate UUID. A UUID would only matter for cross-device sync, which is an explicit anti-goal.

**Alternatives considered**: String UUID (`uuid` pkg) — unnecessary without sync; rejected.

---

## D3 — Enum persistence (currency / period / category)

**Decision**: Persist enums by **name** using `@Enumerated(EnumType.name)` (Isar). Domain uses plain Dart enums (`BillingPeriod`, `Currency`, `SubscriptionCategory`).

**Rationale**: Name-based storage is stable if enum order changes; index-based storage silently corrupts data on reorder. Currency is also restricted to the supported set (TRY/USD/EUR) at validation time (FR-008).

**Alternatives considered**: Index-based (`EnumType.ordinal`) — smaller but reorder-fragile; rejected.

---

## D4 — Domain entity separate from Isar model

**Decision**: Keep a pure-Dart immutable `Subscription` domain entity, an Isar `SubscriptionEntity` `@collection`, and a thin mapper between them. `domain/` imports no Isar/Flutter-plugin code.

**Rationale**: The constitution explicitly requires storage to be swappable and the service layer reusable across apps. A leak-free `domain` boundary is what makes that real: swapping Isar→Drift means writing a new `data/` impl only. Cost is one mapper file — acceptable.

**Alternatives considered**: Use the Isar model directly as the domain type — less boilerplate but couples the whole app to Isar annotations, violating the swappability requirement; rejected.

---

## D5 — Where the free-tier limit is enforced

**Decision**: Enforce the 5-subscription limit in the **`AddSubscription` use case** (domain), which is the single funnel for creation. The use case reads the current count from the repository and the premium flag from an injected `PremiumStatus`. The raw repository stays pure CRUD and is **not** exposed to UI (only `application` providers for use cases are public).

**Rationale**: Spec FR-016 requires the limit to be un-bypassable from any UI path. Making the use case the only public creation entry point achieves that without putting business policy inside the storage adapter (which should remain swappable and policy-free). `update()` deliberately skips the limit check (FR-018).

**Alternatives considered**:
- *Enforce inside the repository impl*: pollutes the storage adapter with business policy and would have to be re-implemented for every storage backend; rejected.
- *Enforce in UI only*: bypassable; violates FR-016; rejected.

---

## D6 — Premium status injection

**Decision**: Define a `PremiumStatus` abstraction (a provider returning `bool isPremium`). In this feature it is a **stub provider returning `false`** (free tier). The `paywall` feature later overrides this provider with the RevenueCat-backed implementation.

**Rationale**: Lets this feature be built and fully tested now without RevenueCat, while keeping a clean seam (FR note + Assumptions). Riverpod provider override is the natural injection point.

**Alternatives considered**: Hard-code non-premium — untestable for the premium path (SC-004 needs both); rejected.

---

## D7 — Brand catalog & Turkish-tolerant resolution

**Decision**: A `const` list of `BrandCatalogEntry` (serviceKey, displayName, brandColor as ARGB int, logoAsset path, defaultCategory, aliases). `BrandResolver.resolve(name)` normalizes input by: trim → Turkish-aware lower-casing (İ→i, I→ı handled explicitly) → diacritic/space fold, then matches against each entry's normalized displayName + aliases. Returns `BrandCatalogEntry?` (null = no match, FR-013).

**Rationale**: Dart's default `toLowerCase()` mishandles Turkish `I/İ`. A small explicit fold (replace `İ`→`i`, `I`→`i`, then `toLowerCase('tr')` semantics approximated) makes "İcloud", "BLUTV", "exxen" all resolve (FR-012, SC-003). A const catalog is fully offline (FR-010) and zero-cost.

**Logo assets**: 12 brand SVGs bundled under `assets/logos/` (already registered in `pubspec.yaml`). Implementation sources recognizable brand marks; brand colors are hardcoded ARGB. Unknown services → no match here; the online-fetch + initial fallback is a later feature.

**Alternatives considered**:
- *Fuzzy match (Levenshtein)*: overkill and risks wrong matches; aliases + normalization are deterministic and predictable. Rejected for v1.
- *Remote catalog*: violates offline principle; rejected.

---

## D8 — Isar lifecycle & testing strategy

**Decision**:
- Production: `IsarDatabase` opens a single Isar instance in the app documents dir (`path_provider`), with `SubscriptionEntitySchema`. Exposed via an async Riverpod provider.
- Unit tests (validator, resolver, limit use case): pure Dart, no Isar — the limit use case runs against an in-memory **fake repository**.
- Integration tests (repository impl): open a **real Isar** in a unique temp directory using `Isar.initializeIsarCore(download: true)` in `setUpAll`, and clean up in `tearDown`. This exercises real persistence and the "survives restart" scenario (close + reopen the instance).

**Rationale**: Splitting fast pure-Dart unit tests from slower real-Isar integration tests keeps the suite quick while still proving persistence (SC-001). `initializeIsarCore(download: true)` is the documented way to run Isar on the test VM.

**Alternatives considered**: Mock Isar entirely — would not prove real persistence (the central product promise); rejected for the repository tests (still used for the limit use case).

---

## Summary of resolved decisions

| ID | Topic | Decision |
|----|-------|----------|
| D1 | Money | `double` amount, display-rounded later |
| D2 | Identity | Isar auto-increment `Id`, surfaced as `int?` |
| D3 | Enums | Persist by name (`EnumType.name`) |
| D4 | Layering | Pure domain entity + Isar model + mapper |
| D5 | Limit | Enforced in `AddSubscription` use case (single funnel) |
| D6 | Premium | `PremiumStatus` abstraction, stub `false`, overridden by paywall |
| D7 | Catalog | Const catalog + Turkish-aware deterministic resolver |
| D8 | Testing | Pure-Dart unit + real-Isar temp-dir integration |
