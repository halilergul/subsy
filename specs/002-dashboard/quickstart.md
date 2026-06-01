# Quickstart: Dashboard

## Prerequisites

- `subscriptions-core` present (it is, on `master`).
- `flutter pub get` done. No new packages.

## Build & checks

```bash
flutter analyze            # clean
flutter test test/unit     # pure calculators (fast)
flutter test test/widget   # dashboard states via ProviderScope overrides
flutter run                # see it on a device/simulator
```

## Verifying behavior (maps to Success Criteria)

| Check | How | Spec |
|-------|-----|------|
| Soonest payment on top | seed mixed dates → list sorted asc by effective renewal | SC-001/FR-001 |
| Past dates roll forward | seed a past renewal → card shows next future occurrence | SC-003/FR-002 |
| Per-currency totals correct | seed weekly/monthly/yearly in TRY+USD → two summary lines, hand-checked | SC-002/FR-007 |
| No cross-currency sum | mixed currencies → never one blended number | SC-004/FR-008 |
| Reactive update | add/delete via core use case → dashboard updates, no refresh | SC-005/FR-010 |
| Empty state | zero subscriptions → empty state + CTA, not blank | SC-007/FR-011 |
| Smooth at scale | 100+ seeded → lazy list scrolls without jank | SC-006 |

## Manual seed (throwaway)

Use core's `addSubscriptionProvider` to insert a few subscriptions (Netflix monthly TRY, Spotify monthly TRY, ChatGPT Plus monthly USD with a past date), then open the dashboard:
- Expect a "₺.../ay" line and a "$.../ay" line in the summary.
- The past-dated ChatGPT card shows a future "N gün sonra".

## Widget-test pattern

```dart
ProviderScope(
  overrides: [
    subscriptionsProvider.overrideWith((ref) => Stream.value([/* fakes */])),
  ],
  child: const MaterialApp(home: DashboardScreen()),
);
```
Override the stream with empty / one / many lists to assert empty / data / sorted rendering.

## Integration points

- Add-flow feature: wire the FAB/empty CTA `onAdd` to the real route once that screen exists (here it navigates to a placeholder).
- Currency-conversion feature: will add a unified TRY total alongside the per-currency lines.
- Statistics feature: reuses `monthlyAmount` / `BrandAvatar`.
