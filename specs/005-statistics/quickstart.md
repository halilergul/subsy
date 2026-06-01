# Quickstart: Statistics

## Prerequisites

- `subscriptions-core` + `dashboard` on `master`.
- Add `fl_chart`. `flutter pub get`.

## Build & checks

```bash
flutter pub add fl_chart
flutter analyze
flutter test test/unit/statistics_calculator_test.dart
flutter test test/widget/statistics_screen_test.dart
flutter run    # dashboard → statistics; toggle monthly/yearly
```

## Verifying behavior (maps to Success Criteria)

| Check | How | Spec |
|-------|-----|------|
| Category totals + % | seed mixed categories → hand-check amounts/percentages | SC-001 |
| % sum to 100 | any set → each currency's slices sum to 100 (±1) | SC-002 |
| Period scaling | toggle yearly → every amount ×12, % unchanged | SC-003 |
| No blending | mixed currencies → separate breakdowns/rankings | SC-004 |
| Reactive | add/delete via core → statistics update | SC-005 |
| Empty | zero subscriptions → empty state, no chart | SC-006 |

## Test patterns

**Aggregator (pure):**
```dart
final view = buildStatistics([
  sub(cat: streaming, amount: 100, monthly),
  sub(cat: music, amount: 100, monthly),
], StatPeriod.monthly);
final try_ = view.breakdowns.firstWhere((b) => b.currency == Currency.tryl);
expect(try_.total, 200);
expect(try_.slices.map((s) => s.percentage), everyElement(50));
// yearly
final y = buildStatistics(sameSubs, StatPeriod.yearly);
expect(y.breakdowns.first.total, 2400);
```

**Screen (widget):**
```dart
ProviderScope(overrides: [
  subscriptionsProvider.overrideWith((ref) => Stream.value(subs)),
], child: const MaterialApp(home: StatisticsScreen()));
// empty list → empty state; non-empty → donut + legend present
```

## Integration points

- Reuses `monthlyAmount`, `subscriptionsProvider`, `formatMoney`, `BrandAvatar`.
- The later currency-conversion feature can add a unified-TRY total alongside the per-currency breakdowns.
- `category_style.dart` (color+label) is reusable by future detail/insight screens.
