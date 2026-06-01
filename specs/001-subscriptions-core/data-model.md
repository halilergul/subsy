# Phase 1 Data Model: Subscriptions Core

Derived from the spec's Key Entities and Functional Requirements. Field names are the canonical (English) names used in code.

---

## Enums

### `BillingPeriod`
`weekly` · `monthly` · `yearly`
- Persisted by name. Drives later renewal-date math (out of scope here).

### `Currency`
`tryl` (TRY) · `usd` (USD) · `eur` (EUR)
- Only these three are accepted (FR-008). `code` getter returns the ISO string ("TRY"/"USD"/"EUR"). Persisted by name.
- Note: `try` is a Dart reserved word, so the enum constant is `tryl` with `code == 'TRY'`.

### `SubscriptionCategory`
`streaming` · `music` · `cloud` · `ai` · `productivity` · `shopping` · `other`
- Default is `other` when no catalog match (FR-014 / Assumptions). Used by the later statistics feature.

---

## Entity: `Subscription` (domain)

Pure-Dart immutable value object. No Isar/Flutter imports. `copyWith` for updates.

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| `id` | `int?` | no | Null until persisted. Assigned by storage; stable across updates (FR-003). |
| `name` | `String` | yes | 1–60 chars after trim (FR-006, long-name edge case). |
| `serviceKey` | `String?` | no | Catalog link; null if no brand match (FR-013). |
| `amount` | `double` | yes | Finite, > 0 (FR-007). |
| `currency` | `Currency` | yes | One of TRY/USD/EUR (FR-008). |
| `billingPeriod` | `BillingPeriod` | yes | weekly/monthly/yearly (FR-004). |
| `nextRenewalDate` | `DateTime` | yes | Any date; past allowed (edge case). Stored as UTC. |
| `category` | `SubscriptionCategory` | yes | Defaults from catalog, else `other`. |
| `startDate` | `DateTime?` | no | Optional. |
| `notes` | `String?` | no | Optional, ≤ 280 chars (long-notes edge case). |
| `createdAt` | `DateTime` | yes | Set on create, immutable (FR-005). |
| `updatedAt` | `DateTime` | yes | Set on every write (FR-005). |

**Relationships**: optional soft link to a `BrandCatalogEntry` via `serviceKey` (not a DB foreign key — the catalog is in-app constant data).

---

## Input: `SubscriptionDraft`

The validated input for create/update (UI → use case). Same fields as `Subscription` minus `id`, `createdAt`, `updatedAt` (those are managed by the system). The validator turns a `SubscriptionDraft` into either a `Success<Subscription>` or a `Failure<ValidationError>`.

---

## Validation rules (`SubscriptionValidator`)

Returns `Result<…>`; never throws (FR-009). All messages are Turkish.

| Rule | Trigger | Error |
|------|---------|-------|
| Name required | empty/whitespace name | "Servis adı boş olamaz." |
| Name length | trimmed length > 60 | "Servis adı çok uzun." |
| Amount positive | amount ≤ 0 or not finite | "Tutar sıfırdan büyük olmalı." |
| Currency supported | currency not in {TRY,USD,EUR} | "Desteklenmeyen para birimi." |
| Period present | null billing period | "Yenileme dönemi seçilmeli." |
| Renewal date present | null date | "Yenileme tarihi gerekli." |
| Notes length | notes length > 280 | "Not çok uzun." |

> Required-field presence is also enforced by the type system (non-nullable fields on `SubscriptionDraft`); the validator covers value-range rules and produces user-facing messages.

---

## Persistence model: `SubscriptionEntity` (Isar `@collection`)

Mirror of `Subscription` with Isar annotations. Mapper functions: `SubscriptionEntity.fromDomain(Subscription)` and `.toDomain()`.

| Isar field | Type | Annotation |
|------------|------|------------|
| `id` | `Id` | auto-increment (`Isar.autoIncrement`) |
| `name` | `String` | `@Index(type: IndexType.value)` (future search) |
| `serviceKey` | `String?` | — |
| `amount` | `double` | — |
| `currency` | `Currency` | `@Enumerated(EnumType.name)` |
| `billingPeriod` | `BillingPeriod` | `@Enumerated(EnumType.name)` |
| `nextRenewalDate` | `DateTime` | stored UTC |
| `category` | `SubscriptionCategory` | `@Enumerated(EnumType.name)` |
| `startDate` | `DateTime?` | — |
| `notes` | `String?` | — |
| `createdAt` | `DateTime` | — |
| `updatedAt` | `DateTime` | — |

Generated: `subscription_entity.g.dart` (via `isar_community_generator`).

---

## Entity: `BrandCatalogEntry` (const, in-app)

Read-only, bundled. Not persisted in Isar.

| Field | Type | Notes |
|-------|------|-------|
| `serviceKey` | `String` | stable key, e.g. `"netflix"`, `"youtube_premium"` |
| `displayName` | `String` | canonical name, e.g. "Netflix" |
| `brandColor` | `int` | ARGB, e.g. `0xFFE50914` |
| `logoAsset` | `String` | `assets/logos/<key>.svg` |
| `defaultCategory` | `SubscriptionCategory` | |
| `aliases` | `List<String>` | extra matchable names |

### Mandatory launch catalog (12)

| serviceKey | displayName | defaultCategory | brandColor (ARGB) |
|------------|-------------|-----------------|-------------------|
| `spotify` | Spotify | music | `0xFF1DB954` |
| `netflix` | Netflix | streaming | `0xFFE50914` |
| `youtube_premium` | YouTube Premium | streaming | `0xFFFF0000` |
| `apple_tv_plus` | Apple TV+ | streaming | `0xFF000000` |
| `icloud_plus` | iCloud+ | cloud | `0xFF3693F3` |
| `chatgpt_plus` | ChatGPT Plus | ai | `0xFF10A37F` |
| `claude_pro` | Claude Pro | ai | `0xFFD97757` |
| `exxen` | Exxen | streaming | `0xFFF9D616` |
| `gain` | Gain | streaming | `0xFFE6007E` |
| `blutv` | BluTV | streaming | `0xFF00A0E3` |
| `trendyol_premium` | Trendyol Premium | shopping | `0xFFF27A1A` |
| `amazon_prime` | Amazon Prime | streaming | `0xFF00A8E1` |

> Brand colors above are the implementation starting point; final exact values verified against each brand's official palette during implementation. Catalog may be extended beyond 12 (popular global services) but these 12 are mandatory (FR-011).

---

## Resolution normalization (`BrandResolver`)

`resolve(String input) → BrandCatalogEntry?`

1. `trim()`
2. Turkish-aware lowercase: replace `İ→i`, `I→ı`→`i`, then `toLowerCase()`; strip extra whitespace.
3. Compare normalized input against the normalized `displayName` and each `alias` of every entry.
4. First exact normalized match wins (deterministic; catalog ordered so no ambiguous overlap). Null if none.

Example aliases: `youtube_premium` → ["youtube", "yt premium", "youtube music"]; `chatgpt_plus` → ["chatgpt", "openai", "gpt plus"]; `icloud_plus` → ["icloud", "icloud+"].
