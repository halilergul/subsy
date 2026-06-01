# Quickstart: Subscriptions Core

How to build, generate, and verify this feature. No UI — everything is exercised through tests.

## Prerequisites

- Flutter 3.41+ / Dart 3.11+ (`flutter --version`)
- Dependencies installed: `flutter pub get`

## Code generation

This feature uses `isar_community_generator` (Isar schema) and `riverpod_generator`. After writing/annotating the model and providers:

```bash
dart run build_runner build --delete-conflicting-outputs
# or while iterating:
dart run build_runner watch --delete-conflicting-outputs
```

Generated files: `subscription_entity.g.dart`, `*.g.dart` for annotated providers. (These are git-ignored and re-generated locally.)

## Run the checks

```bash
flutter analyze          # must be clean
flutter test             # unit + integration
flutter test test/unit               # fast pure-Dart tests only
flutter test test/integration        # real-Isar persistence tests
```

## What "done" looks like (maps to spec Success Criteria)

| Check | How verified | Spec |
|-------|--------------|------|
| Persists across restart | integration test closes + reopens Isar, re-reads identical record | SC-001 |
| Fully offline | no `http`/network import in this feature; tests run with no connectivity | SC-002 |
| 12 brands resolve (incl. TR/casing/alias variants) | `brand_resolver_test` parameterized over variants | SC-003 |
| Free user blocked at 6th, premium never | `add_subscription_limit_test` with fake repo + premium toggle | SC-004 |
| Invalid input rejected pre-write | validator tests assert `Failure` and zero writes | SC-005 |
| Storage failure → typed error, no crash | repository test simulates a closed instance → `Failure(StorageError)` | SC-006 |

## Manual smoke (optional, via a throwaway `main`)

```dart
final container = ProviderContainer();
final add = container.read(addSubscriptionProvider);
final res = await add(SubscriptionDraft(
  name: 'Netflix', amount: 149.99, currency: Currency.tryl,
  billingPeriod: BillingPeriod.monthly, nextRenewalDate: DateTime(2026, 6, 15),
));
res.when(
  success: (s) => print('saved id=${s.id} brand=${s.serviceKey} cat=${s.category}'),
  failure: (e) => print('error: ${e.message}'),
);
```
Expected: `saved id=1 brand=netflix cat=streaming` (brand auto-resolved, category defaulted from catalog).

## Integration points for later features

- **dashboard / statistics**: consume `subscriptionsProvider` (stream of `List<Subscription>`).
- **paywall**: override `premiumStatusProvider` with the RevenueCat-backed `PremiumStatus`.
- **logo fallback feature**: handles `serviceKey == null` (unknown service) with online fetch + initial fallback.
- **notifications**: read `nextRenewalDate` + `billingPeriod` to schedule reminders.
