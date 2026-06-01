# Quickstart: Home Screen Widget

## Prerequisites

- `subscriptions-core` + `dashboard` + `currency-conversion` on `master`.
- `home_widget` already in pubspec (no new package). iOS needs an App Group; both need native widget targets.

## Build & checks

```bash
flutter pub get
flutter analyze
flutter test test/unit/widget_payload_builder_test.dart
# Device/simulator (native render — cannot run in CI/headless):
flutter run                 # add the Subsy widget to the home screen; verify content + tap
```

## Verifying behavior (maps to Success Criteria)

| Check | How | Spec |
|-------|-----|------|
| Next payment correct | seed subs → widget's next = dashboard's soonest item | SC-001 |
| Monthly total correct | mixed currencies → total_line == dashboard summary; unified only when rates exist | SC-002 |
| Reactive | add/edit/delete or rate refresh → widget updates same session | SC-003 |
| Gated | free user → locked teaser, no real figures | SC-004 |
| Offline | airplane mode → widget still shows last content | SC-005 |
| Tap | tap widget → app opens | SC-006 |

## Test patterns

**Builder (pure):**
```dart
final p = buildWidgetPayload(
  subs: [sub('Netflix', daysFromNow: 3, amount: 149.99, Currency.tryl)],
  now: now, isPremium: true, target: Currency.tryl, rates: null,
);
expect(p.state, WidgetState.ready);
expect(p.nextTitle, 'Netflix');
expect(p.nextWhen, '3 gün sonra');
expect(p.nextAmount, '₺149.99');
expect(p.totalLine, contains('/ ay'));
expect(p.unifiedLine, isEmpty);          // no rates

// free → locked
expect(buildWidgetPayload(subs: subs, now: now, isPremium: false,
    target: Currency.tryl, rates: null).state, WidgetState.locked);
// empty → empty
expect(buildWidgetPayload(subs: const [], now: now, isPremium: true,
    target: Currency.tryl, rates: null).state, WidgetState.empty);
```

**Sync (fake service):**
```dart
final fake = FakeHomeWidgetService();
// override homeWidgetServiceProvider with fake; pump a container; emit subs;
// expect fake.lastPayload reflects the new state.
```

## Native verification (device only)

- **Android**: long-press home screen → Widgets → Subsy → place. Confirm dark compact layout shows next payment + monthly total; tap opens the app. Add/delete a subscription in-app → widget refreshes.
- **iOS**: long-press → add Subsy widget. Confirm App Group sharing (widget shows data); tap opens the app.
- These steps are **manual** — the native render is not buildable in this environment; defer + note if no device available (as with prior features' device checks).

## Integration points

- `startHomeWidgetSync(ref)` in `SubsyApp` (next to `startReminderSync` / `startExchangeRateSync`).
- `main`: `HomeWidget.setAppGroupId(kWidgetAppGroupId)` + override `homeWidgetServiceProvider` with `PluginHomeWidgetService`.
- Reuses dashboard + currency logic unchanged; the widget is an additive read-only mirror.
- Native logo rendering deferred (v1 shows service name); see research.md D8.
