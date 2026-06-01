# Phase 0 Research: Currency Conversion

Framework + offline/network exception fixed by CONSTITUTION.md (frankfurter.app decision, anonymous rate fetch, cache-on-failure). Resolves conversion-specific design + UI/UX (no Figma). No `NEEDS CLARIFICATION` remain.

---

## D1 — Rate source & endpoint (verified live)

**Decision**: Fetch from **frankfurter** (free, keyless, ECB-sourced). The legacy host `api.frankfurter.app` now **301-redirects to `api.frankfurter.dev/v1/...`** — use the `.dev` host directly to avoid an extra redirect hop. Endpoint: `https://api.frankfurter.dev/v1/latest?base=EUR&symbols=USD,TRY`.

Verified response (2026-06-01): `{"amount":1.0,"base":"USD","date":"2026-06-01","rates":{"EUR":0.85866,"TRY":45.894}}` — top-level keys `amount`, `base`, `date`, `rates`. **TRY and EUR are supported.**

**Rationale**: CONSTITUTION Decisions row already fixes frankfurter.app (keyless, ECB, TRY). It's anonymous (no key, no personal data) — fits the offline/privacy promise. ECB base is EUR, so `base=EUR` is the most native (no double-rounding through a pivot).

**Key gotcha**: the `rates` object does **not** include the base currency itself (a `base=USD` call omits USD from `rates`). The client MUST inject `base → 1.0` into the rate map before use.

**Alternatives**: exchangerate.host / openexchangerates — require keys or have unstable free tiers; rejected (constitution already chose frankfurter).

---

## D2 — Rate model & conversion math (pure)

**Decision**: Store rates as `ExchangeRates(base, Map<Currency,double> ratesPerBase, fetchedAt)` where `ratesPerBase[c]` = units of `c` per 1 `base` (and `ratesPerBase[base] = 1.0`). Convert A→B:

```
amount_B = amount_A * ratesPerBase[B] / ratesPerBase[A]
```

`convertAmount(amount, from, to, rates)` returns `null` if either `from` or `to` is absent from the map (→ feeds the "partial total" path). When `from == to` the formula yields exactly `amount` (factor 1.0, FR-004/SC-002), so no special-case rounding.

**Rationale**: Cross-rate via the base is currency-agnostic and exact for the all-target case. Pure, deterministic, no Flutter/http/Isar imports → fully unit-testable to SC-001/002.

---

## D3 — Unified totals & partial handling

**Decision**: `unifiedMonthlyTotal(subs, target, rates) → UnifiedTotal?` sums `monthlyAmount(sub)` converted to `target` **before rounding** (FR-005). Subscriptions whose currency is missing from `rates` are excluded and their currencies collected into `UnifiedTotal.missing`; `partial = missing.isNotEmpty` (FR-007). Returns `null` only when no subscription could be converted at all (no usable rates) → drives the "unavailable" state. Statistics reuse the same per-subscription conversion, then group by category and apply the `StatPeriod.factor` (×1/×12) — identical scaling to the per-currency path (SC-007); percentages computed from the unified total (same largest-remainder rule as `statistics_calculator`).

**Rationale**: Sum-before-round avoids per-item drift; explicit `partial`/`missing` keeps the app honest instead of silently dropping money.

---

## D4 — Caching & fetch lifecycle

**Decision**: `ExchangeRatesRepository` (Isar single-row `ExchangeRatesEntity`, id=0) `load/save/watch`, mirroring the `NotificationSettings` pattern. `ExchangeRateService` (in `core/exchange/`) wraps `http.Client` and returns `Result<ExchangeRates>`. **Cache-first**: `exchangeRatesProvider` streams the cached value; `startExchangeRateSync(ref)` (called once in `SubsyApp`, like `startReminderSync`) fires `service.fetchLatest()` opportunistically on app open; on success it saves to the repo (the stream then re-emits), on failure it silently keeps the existing cache (FR-003, CONSTITUTION §Hata yönetimi). No scheduled/background sync (out of scope).

**Rationale**: Offline-first preserved — the UI always reads the cache; the network is a best-effort refresher that never blocks rendering. Service behind an interface → faked in tests; `http.Client` injected → parsing tested with `MockClient`.

**Alternatives**: fetch synchronously on each screen open — blocks UI, fails offline; rejected. `connectivity_plus` to gate fetches — extra package; a failed fetch already degrades gracefully to cache, so not needed.

---

## D5 — Target currency persistence

**Decision**: `TargetCurrencyRepository` (Isar single-row `TargetCurrencyEntity`, id=0, stores the ISO `code`) `load/save/watch`; default **TRY** when unset (FR-008/009). `targetCurrencyProvider` streams it; the UI selector writes through it (FR-010). Stored as the ISO code string (reuses `Currency.fromCode`), `@enumerated`-free to keep the entity trivial.

**Rationale**: Same proven single-row Isar pattern; reactive `watch` re-expresses every unified figure on change (SC-004).

---

## D6 — Premium gating

**Decision**: A derived `conversionEnabledProvider = ref.watch(premiumStatusProvider).isPremium`. Every unified surface checks it: premium → render the real `UnifiedTotal`; free → render `ConversionLockedTeaser` (upsell) in the same slot, **never** the real number (FR-014/015/SC-005). The per-currency widgets are rendered unconditionally and untouched (FR-018). On downgrade the provider flips and the teaser returns automatically.

**Rationale**: Reuses the existing `premiumStatusProvider` seam the paywall feature will override; no new gating mechanism.

---

## D7 — UI/UX decisions (no Figma)

- **Dashboard**: under the per-currency `MonthlySummaryCard` rows, a unified line: "Toplam ≈ ₺X.XXX,XX / ay" + a small caption "Kurlar: G AĞU (en son güncelleme)". A compact target-currency selector (TRY/USD/EUR `DropdownButton` or chips) sits on the card — changing it re-expresses instantly. Free user: the line is replaced by a locked teaser ("Premium ile tüm aboneliklerini tek para biriminde gör" + kilit ikonu + CTA).
- **Statistics**: a "Birleşik" section above/below the per-currency sections — the ≈ total in the target currency plus a unified category breakdown (reusing the donut+legend widgets fed by converted, period-scaled category sums). Free user: locked teaser. Honors the existing aylık/yıllık toggle.
- **Form**: under the amount field, when the chosen currency ≠ target and rates exist, an inline caption "≈ ₺338,40" updating live; hidden otherwise. Free user: no preview (premium-only convenience).
- **Partial**: when `partial`, append a subtle note "(bazı para birimleri güncel kur olmadan hariç tutuldu)".
- **No rates (premium)**: "Birleşik toplam için kurlar henüz alınamadı — çevrimiçi olunca güncellenecek." Per-currency view unaffected.
- **Approximate marker**: every converted figure prefixed with "≈".

> Recorded as the `UIUX-006` equivalent.

---

## D8 — Money formatting

**Decision**: Reuse `formatMoney`/`currencySymbol`; prefix converted values with "≈ ". The "last updated" caption formats `ExchangeRates.fetchedAt` as a short local date (reuse existing date-label helpers where possible, else a minimal `intl`-free formatter — `intl` is already a dependency).

---

## Summary

| ID | Topic | Decision |
|----|-------|----------|
| D1 | Rate source | frankfurter `.dev/v1/latest?base=EUR&symbols=USD,TRY`; inject base→1.0; `.app` 301→`.dev` |
| D2 | Rate model/math | `ratesPerBase` map; A→B = amt·rate[B]/rate[A]; null if missing; from==to → ×1 |
| D3 | Unified totals | sum-before-round; `partial`+`missing`; statistics reuse + ×factor; % largest-remainder |
| D4 | Cache/fetch | Isar single-row cache + `core/exchange` http service; cache-first; opportunistic sync; fail→keep cache |
| D5 | Target currency | Isar single-row (ISO code), default TRY, reactive watch |
| D6 | Premium gate | `conversionEnabledProvider` off `premiumStatusProvider`; free → locked teaser |
| D7 | UI | dashboard unified line + selector; statistics unified section; form live preview; honest partial/no-rates |
| D8 | Formatting | reuse `formatMoney` with "≈ " prefix; short-date "last updated" |
