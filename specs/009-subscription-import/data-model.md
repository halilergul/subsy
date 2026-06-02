# Data Model: Automatic Subscription Recognition (OCR Import)

No new persisted storage. The only stored output is the existing `Subscription` (written via `AddSubscription`). The types below are **in-memory, transient** values that live for the duration of an import.

## OcrText (value — `OcrService` output)

Plain recognized text from one source. Deliberately minimal so the parser stays pure and the OCR impl stays swappable.

| Field | Type | Notes |
|-------|------|-------|
| `lines` | `List<String>` | Recognized text lines in reading order (already trimmed). |
| `raw` | `String` | Full recognized text (lines joined by `\n`) for whole-blob scans. |

- Produced by `OcrService.recognizeImage(...)` / `recognizePdf(...)`.
- No bounding boxes in v1 (line-region heuristics suffice — research.md D6); a richer block model can be added later behind the same interface.

## RecognizedDraft (value — parser output, reviewed in UI)

A candidate subscription extracted from `OcrText`. **Nullable fields by design** — recognition is best-effort; unknown fields are `null` and flagged for the user (FR-007). Exists only in the review screen until confirmed or discarded.

| Field | Type | Rule / Notes |
|-------|------|--------------|
| `serviceKey` | `String?` | Matched brand key from `kBrandCatalog`, or `null` if no confident match (FR-004). |
| `name` | `String` | Recognized service name (raw text when no brand). Never null — falls back to best text line; user can edit. |
| `amount` | `double?` | Parsed amount (`> 0`). `null` when not recognized. |
| `currency` | `Currency?` | From currency marker. `null` when ambiguous/absent → user picks. |
| `billingPeriod` | `BillingPeriod?` | From period keywords; `null` → defaults to monthly at confirm, flagged. |
| `nextRenewalDate` | `DateTime?` | Parsed/rolled-forward date; `null` when no date found. |
| `category` | `SubscriptionCategory?` | Usually `null` — derived from brand at confirm (same as manual add). |
| `confidence` | `RecognitionConfidence` | Per-field presence/uncertainty (see below). Drives the "needs your attention" UI. |
| `duplicateOf` | `String?` | Id/name of an existing subscription this likely duplicates, or `null` (FR-014). |

### RecognitionConfidence (value)

Per-field flags so the UI can mark what to check. Booleans (recognized vs. uncertain/missing) keep it simple and testable.

| Field | Type | Meaning |
|-------|------|---------|
| `nameRecognized` | `bool` | A plausible service name was found. |
| `amountRecognized` | `bool` | An amount+currency was parsed. |
| `dateRecognized` | `bool` | A concrete date was parsed (vs. defaulted/rolled-forward). |
| `periodRecognized` | `bool` | A period keyword was found (vs. defaulted monthly). |
| `brandMatched` | `bool` | `serviceKey` was resolved from the catalog. |

A draft is **confirmable** only when, after user edits, `name`, `amount`, `currency`, `billingPeriod`, and `nextRenewalDate` are all non-null and pass `SubscriptionValidator` — enforced at confirm by converting to `SubscriptionDraft` and calling `AddSubscription`.

## Conversion → SubscriptionDraft (existing)

On confirm, each kept `RecognizedDraft` maps to the existing `SubscriptionDraft` (no new save path):

```text
SubscriptionDraft(
  name:            draft.name.trim(),
  amount:          draft.amount!,            // guaranteed by confirm gate
  currency:        draft.currency!,
  billingPeriod:   draft.billingPeriod ?? BillingPeriod.monthly,
  nextRenewalDate: draft.nextRenewalDate!,
  category:        draft.category,           // null → AddSubscription derives from brand
  notes:           null,
)
```

`AddSubscription` then applies validation, brand enrichment (`serviceKey`/category from `BrandResolver`), and the premium-aware funnel. Import is premium-only, so the free-tier cap is never reached.

## Import session state (transient — `ImportController`)

Not persisted; held by the controller while the review screen is open.

| Field | Type | Notes |
|-------|------|-------|
| `status` | `ImportStatus` | `idle` / `locked` (free user) / `recognizing` / `review` / `noResult` / `error` / `saving` / `done`. |
| `drafts` | `List<RecognizedDraft>` | Recognized candidates; user edits/discards in place. |
| `error` | `AppError?` | Typed, Turkish-messaged failure (permission denied, unreadable, etc.). |
| `savedCount` | `int` | Set after a bulk save for the success summary. |

## Reused entities (unchanged)

- **Subscription** (`subscriptions-core`): the persisted result; created via `AddSubscription`.
- **SubscriptionDraft / SubscriptionValidator / AddSubscription**: the create funnel, reused as-is.
- **BrandCatalogEntry / kBrandCatalog / BrandResolver**: brand knowledge + normalization; `BrandTextMatcher` reuses the catalog and the normalization for in-text scanning.
- **Currency / BillingPeriod / SubscriptionCategory** (`enums.dart`): the recognized values map onto these.
- **PremiumStatus / premiumStatusProvider**: gates the whole flow.
- **Result<T> / AppError**: error handling.

## Validation rules (recap)

- Nothing is saved without explicit per-source confirmation (FR-005).
- A draft cannot be confirmed until required fields are present and valid (reuses `SubscriptionValidator`).
- Unknown brand → raw name kept, no false `serviceKey` (FR-004).
- Possible duplicates flagged; user chooses skip or add (FR-014).
- Free user → `locked` status, no drafts ever produced (FR-017).
- Source bytes are transient — never written to storage (FR-016).
