# Quickstart: Currency Conversion

## Prerequisites

- `subscriptions-core` + `dashboard` + `statistics` on `master`.
- `http` already in pubspec (no new package). Isar codegen for the two new entities.

## Build & checks

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # ExchangeRatesEntity + TargetCurrencyEntity schemas
flutter analyze
flutter test test/unit/currency_converter_test.dart
flutter test test/unit/http_exchange_rate_service_test.dart
flutter test test/widget/currency_conversion_test.dart
flutter run    # dashboard unified total (premium); toggle target; go offline → cached rates
```

## Verifying behavior (maps to Success Criteria)

| Check | How | Spec |
|-------|-----|------|
| Unified total correct | seed TRY+USD+EUR, known rates → hand-check sum | SC-001 |
| target==source ×1 | all-target set → unified == per-currency total, 0 drift | SC-002 |
| Offline from cache | seed cache, no network → total still shown + "last updated" | SC-003 |
| Target persists | change target, restart → same target, figures re-expressed | SC-004 |
| Free gated | free user → locked teaser, never a real number | SC-005 |
| No rates honest | premium, empty cache, offline → "unavailable", no wrong total | SC-006 |
| Period scaling | yearly → unified ×12, percentages unchanged | SC-007 |
| Privacy | only outbound request is the public rate fetch (no sub data) | SC-008 |

## Test patterns

**Converter (pure):**
```dart
final rates = ExchangeRates(
  base: Currency.eur,
  ratesPerBase: {Currency.eur: 1.0, Currency.usd: 1.10, Currency.tryl: 45.0},
  fetchedAt: DateTime(2026, 6, 1),
);
// 10 USD -> EUR
expect(convertAmount(10, Currency.usd, Currency.eur, rates), closeTo(10 * 1.0 / 1.10, 1e-9));
// target == source
expect(convertAmount(10, Currency.tryl, Currency.tryl, rates), 10);
// unified total (monthly)
final u = unifiedMonthlyTotal(subs, Currency.tryl, rates)!;
expect(u.partial, isFalse);
// missing-rate currency
final partial = unifiedMonthlyTotal(subsWithGbp, Currency.tryl, rates)!;
expect(partial.partial, isTrue);
expect(partial.missing, contains(Currency.gbp)); // example
```

**Service parse (MockClient):**
```dart
final client = MockClient((req) async => http.Response(
  '{"amount":1.0,"base":"EUR","date":"2026-06-01","rates":{"USD":1.10,"TRY":45.0}}', 200));
final res = await HttpExchangeRateService(client).fetchLatest();
final rates = (res as Success).value;
expect(rates.ratesPerBase[Currency.eur], 1.0); // base injected
expect(rates.ratesPerBase[Currency.tryl], 45.0);
```

**Screen (widget) — gated/unlocked/no-rates:**
```dart
ProviderScope(overrides: [
  subscriptionsProvider.overrideWith((ref) => Stream.value(subs)),
  premiumStatusProvider.overrideWithValue(FakePremium(true)),   // or false → teaser
  exchangeRatesProvider.overrideWith((ref) => Stream.value(rates)), // or null → unavailable
], child: const MaterialApp(home: DashboardScreen()));
```

## Integration points

- `startExchangeRateSync(ref)` in `SubsyApp` (next to `startReminderSync`) — opportunistic fetch on app open.
- `IsarDatabase` registers the two new schemas.
- Dashboard `MonthlySummaryCard` hosts the unified line/teaser; statistics screen gains a unified section; the form gains an inline preview.
- The per-currency `currencySummary` / `statistics_calculator` outputs are **unchanged** — conversion is additive only.
- `frankfurter.app` 301-redirects to `frankfurter.dev`; call `.dev` directly. The base currency is **omitted** from the API `rates` map — inject `base → 1.0`.
```
