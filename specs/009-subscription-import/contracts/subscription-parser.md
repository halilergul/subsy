# Contract: SubscriptionParser (pure — the heart)

Pure Dart. Turns `OcrText` into `List<RecognizedDraft>`. No Flutter/plugin/network imports. Exhaustively unit-tested with text fixtures (no images).

## Signature

```dart
class SubscriptionParser {
  const SubscriptionParser({
    BrandTextMatcher brandMatcher,
    AmountParser amountParser,
    DateParser dateParser,
  });

  /// Extract zero or more draft subscriptions from recognized text.
  /// Never throws; unreadable input → empty list.
  List<RecognizedDraft> parse(OcrText text);
}
```

## Behavior (maps to FRs)

1. **Brand anchors** (`BrandTextMatcher`, D4): scan `text` for `kBrandCatalog` display names/aliases using `BrandResolver`'s Turkish-tolerant normalization. Each hit anchors a draft with `serviceKey` + `brandMatched=true`. (FR-004, FR-008)
2. **Amount + currency** (`AmountParser`, D5): nearest currency-marked number to an anchor → `amount` + `currency`. Handles `₺/TL/TRY/$/USD/€/EUR` and both `1.234,56` and `1,234.56`. (FR-010)
3. **Date** (`DateParser`, D5): nearest parseable date → `nextRenewalDate`; `dd.MM.yyyy`, `dd/MM/yyyy`, ISO, `12 Şubat 2026`, `Feb 12`. Past/day-only dates roll forward (app's effective-renewal rule), flagged `dateRecognized=false`.
4. **Period** (`DateParser`, D5): keyword scan → `billingPeriod`; absent → `null` (defaults monthly at confirm), `periodRecognized=false`.
5. **No-brand fallback**: a strong amount+date line group with no catalog brand → a draft with `serviceKey=null`, `name=` best nearby text line, `brandMatched=false`. (FR-004)
6. **Confidence**: set each `RecognitionConfidence` flag from what was found (FR-007).
7. **Empty/garbage**: no anchors and no amount+date group → `[]` (controller → `noResult`, FR-011).

## Representative test cases (fixtures)

| Fixture | Expected |
|--------|----------|
| Single receipt: `"Spotify Premium\n₺59,99 / ay\nSonraki ödeme: 12.06.2026"` | 1 draft: serviceKey=spotify, amount=59.99, TRY, monthly, date=2026-06-12, all flags true |
| US format: `"Netflix $15.99 monthly next 2026-07-01"` | amount=15.99, USD, monthly, date=2026-07-01 |
| EU/TR grouping: `"1.234,56 TL"` | amount=1234.56, TRY |
| App Store list (3 services, repeating brand+price rows) | 3 independent drafts (FR-008) |
| Partial: `"YouTube Premium ₺79,99"` (no date) | 1 draft, amount set, `nextRenewalDate=null`, `dateRecognized=false` |
| Unknown brand: `"Acme Cloud €4,99/ay 01.08.2026"` | serviceKey=null, name="Acme Cloud", amount=4.99 EUR, brandMatched=false |
| Multi-currency in one source | each draft keeps its own currency |
| Garbage / no subscription | `[]` |
| Turkish month name `"5 Ağustos 2026"` | date=2026-08-05 |
| Turkish-char brand normalization (`"İCLOUD+"`) | serviceKey=icloud_plus |

## Helper contracts

- **AmountParser**: `({double amount, Currency currency})? parse(String line)` — null when no amount/currency; handles both decimal conventions; never throws.
- **DateParser**: `DateTime? parseDate(String, {DateTime now})` + `BillingPeriod? parsePeriod(String)` — `now` injected (no `DateTime.now()` inside, for deterministic tests); roll-forward uses the app's effective rule.
- **BrandTextMatcher**: `List<BrandMatch> findIn(String text)` where `BrandMatch{ serviceKey, start, end }` — longest/alias-aware, normalized, reuses `kBrandCatalog`; `[]` for none.
- **DuplicateDetector**: `String? findDuplicate(RecognizedDraft, List<Subscription> existing)` — matches normalized brand/name (+ close amount) → existing id/name, else null (FR-014).
