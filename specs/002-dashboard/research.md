# Phase 0 Research: Dashboard

Framework choices are fixed in CONSTITUTION.md. This resolves dashboard-specific design decisions **and** the UI/UX decisions (no Figma → decided here, per CONSTITUTION.md). No `NEEDS CLARIFICATION` remain.

---

## D1 — Effective next renewal (rolling past dates forward)

**Decision**: A pure `effectiveNextRenewal(Subscription, DateTime now)` that, if `nextRenewalDate` is on/after `now`'s date, returns it; otherwise advances by the billing period until it is today or future. Weekly → +7 days repeatedly; monthly → +1 month (calendar-aware, clamping end-of-month); yearly → +1 year. Compared at date granularity (ignore time-of-day).

**Rationale**: Subscriptions auto-renew; a stale stored date should display as the next real charge (FR-002). Pure + `now` injected → deterministic tests. Display-only — never writes back (read-only feature).

**Alternatives considered**: Mutating the stored date on view (rejected — read-only, and writes belong to a renewal/notifications feature); showing the raw past date (rejected — misleading).

---

## D2 — Monthly normalization

**Decision**: `monthlyAmount(Subscription)` = weekly → `amount × (52 / 12)`; yearly → `amount / 12`; monthly → `amount`. Constants `kWeeksPerYear = 52`, `kMonthsPerYear = 12` (no magic numbers).

**Rationale**: 52/12 (≈4.333) is the standard weeks-per-month factor; matches spec FR-007/SC-002. Kept as a double; display rounding via `intl`.

**Alternatives considered**: weekly × 4 (simpler but understates by ~8%; rejected). Average-days-per-month (30.44) — equivalent precision, less intuitive; rejected.

---

## D3 — Per-currency grouping

**Decision**: `currencySummary(List<Subscription>)` groups by `Currency`, sums `monthlyAmount` within each group, returns a list of `(Currency, monthlyTotal)` ordered TRY → USD → EUR, omitting empty currencies. Never sums across currencies (FR-008/SC-004).

**Rationale**: No conversion exists yet; honest separate totals. Stable currency order for predictable UI.

**Alternatives**: single blended total (wrong without rates; rejected). Hide foreign currencies (loses info; rejected — grouping chosen by product decision).

---

## D4 — Relative-time label (Turkish)

**Decision**: `relativeDateLabel(DateTime renewal, DateTime now)` → diff in whole days: 0 = "Bugün", 1 = "Yarın", 2..`kRelativeDayThreshold`(=30) = "N gün sonra", beyond = absolute date `d MMM yyyy` (tr_TR via `intl`). Negative diffs cannot occur (input is the effective future date).

**Rationale**: Matches FR-003; threshold keeps far-off dates readable. Pure + `now` injected → testable.

**Alternatives**: always relative ("412 gün sonra" — noisy; rejected). Always absolute (less glanceable for near dates; rejected).

---

## D5 — Deriving view state from the core stream

**Decision**: `subscriptionsProvider` (core, `StreamProvider<List<Subscription>>` → `AsyncValue`) is the single source. Two derived providers:
- `upcomingPaymentsProvider` → `AsyncValue<List<UpcomingPayment>>`: map → attach effective renewal → sort by it (tie-break by name) (FR-001/005).
- `monthlySummaryProvider` → `AsyncValue<List<CurrencyTotal>>`: group + normalize (FR-007/008).
The screen renders `AsyncValue.when(loading/error/data)` (FR-013); `data` empty → empty state (FR-011); reactivity is automatic because providers re-derive on stream emit (FR-010/SC-005).

**Rationale**: Keeps derivation declarative and cached by Riverpod; UI only renders states. No manual refresh logic.

**Alternatives**: compute inside the widget `build` (re-derives every rebuild, not just on data change; harder to test; rejected).

---

## D6 — List rendering & performance

**Decision**: `ListView.builder` (lazy/virtualized by default in Flutter) for the payments list. `flutter_svg` renders brand logos; cache-friendly. No FlashList (that is a React-Native concept; Flutter's builder is already windowed).

**Rationale**: Meets SC-006 (100+ smooth) without extra deps. Clarifies the CONSTITUTION's "FlashList" note, which referenced the earlier RN profile.

---

## D7 — Brand visuals & fallback

**Decision**: A reusable `BrandAvatar(serviceKey, fallbackName)` widget: if `serviceKey` resolves in the brand catalog → render its SVG logo on its brand color; else → a neutral tile with the service's first letter and a default color. Card accent (left border / background tint) uses the brand color (FR-004).

**Rationale**: Real brand color/logo for known services = premium feel; graceful neutral for unknown (the online-fetch fallback is a later feature). Reusable across statistics/detail.

---

## UI/UX Decisions (no Figma — decided here)

Quality bar: subsday-level. Dark, minimal, hierarchical.

- **Color**: dark surfaces from the existing theme (`scaffold #0E0E12`, elevated cards a step lighter, e.g. `#17171D`). Per-card **brand color** as the visual accent (logo tile + subtle left edge / tint). Text: high-contrast primary `#F5F5F7`, secondary muted grey. Seed `#6C5CE7` for neutral interactive accents (FAB/CTA).
- **Typography**: system/Material 3 type scale. Summary total = large, bold (display/headline). Card: service name `titleMedium` (semibold), amount `titleSmall` (medium), relative-time `bodySmall` (muted).
- **Spacing**: 4-pt base. Screen padding 16; card padding 16; card radius 16–20; gap between cards 12; summary card margin-bottom 24.
- **Summary card**: top of screen, one row per currency: large amount + "/ay" suffix + small currency label; if multiple currencies, stacked rows.
- **Payment card**: leading `BrandAvatar` (48), name + (optional category chip) on the left, amount + relative-time right-aligned. Brand color accent left.
- **Empty state**: centered illustration/icon (e.g. cards/receipt glyph), short Turkish line ("Henüz abonelik yok"), primary CTA button ("Abonelik ekle").
- **Add CTA**: a `FloatingActionButton` (+) always present when list non-empty; the empty state shows a primary button instead.
- **States**: loading = centered spinner / subtle skeleton; error = centered icon + Turkish `AppError.message` + retry affordance.

> These are recorded as `UIUX-002`-equivalent decisions inside this research file since the user proceeded straight to `/speckit-plan`. A post-implementation visual review against them is optional.

---

## Summary

| ID | Topic | Decision |
|----|-------|----------|
| D1 | Renewal rollover | Pure `effectiveNextRenewal`, display-only, calendar-aware |
| D2 | Monthly normalize | weekly×52/12, yearly/12, monthly×1 |
| D3 | Grouping | per-currency totals, TRY→USD→EUR, no cross-sum |
| D4 | Relative label | Bugün/Yarın/N gün sonra/date, 30-day threshold |
| D5 | View state | two derived AsyncValue providers off core stream |
| D6 | List | `ListView.builder` + `flutter_svg`, no extra deps |
| D7 | Brand visuals | reusable `BrandAvatar`, logo-or-initial fallback |
| UI | Look & feel | dark, brand-accented cards, 4-pt spacing, M3 type |
