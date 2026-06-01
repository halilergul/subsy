# Quickstart: Subscription Form

## Prerequisites

- `subscriptions-core` + `dashboard` present (on `master`). No new packages.
- `flutter pub get`.

## Build & checks

```bash
flutter analyze
flutter test test/unit/subscription_form_controller_test.dart
flutter test test/widget/subscription_form_screen_test.dart
flutter run            # full flow: dashboard → add → see it appear → edit → delete
```

## Verifying behavior (maps to Success Criteria)

| Check | How | Spec |
|-------|-----|------|
| Add saves & appears | fill valid fields → Kaydet → back on dashboard, item present | SC-001/SC-003 |
| Validation blocks | empty name / amount 0 → Kaydet → Turkish message, nothing saved | SC-002 |
| Free limit | with 5 existing (free) → add 6th → "limit reached" message, not saved | SC-004 |
| Edit not blocked | edit any of the 5 → Kaydet → succeeds | SC-004 |
| Brand preview | type "Netflix"/"Spotify" → logo+color preview appears | SC-005 |
| Delete confirms | edit → Sil → dialog → confirm → removed | SC-006 |

## Controller test pattern (no widgets)

```dart
ProviderScope(overrides: [
  // reuse the in-memory fake repo from the core limit test
  subscriptionRepositoryProvider.overrideWithValue(FakeSubscriptionRepository()),
  premiumStatusProvider.overrideWithValue(FakePremium(false)),
]);
// read subscriptionFormControllerProvider(null) → setName/setAmountText/... → submit()
// assert state.saved or state.errorMessage
```

## Widget test pattern

```dart
ProviderScope(
  overrides: [ subscriptionRepositoryProvider.overrideWithValue(fakeRepo) ],
  child: const MaterialApp(home: SubscriptionFormScreen()),  // add mode
);
// enter text, tap Kaydet, expect pop / error text; for edit pass subscription:.
```

## Integration points

- This closes the dashboard's add/edit loop (replaces the placeholder SnackBar).
- `paywall` feature will turn the limit message into a real upgrade flow.
- `notifications` feature will later schedule reminders from the saved renewal date.
