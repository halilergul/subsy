# Contracts: Subscriptions Core

For a Flutter app the "interface contracts" are the Dart abstractions the rest of the app (UI/use cases) depends on. These are the stable seams; implementations may change.

---

## 1. `SubscriptionRepository` (domain interface)

Pure CRUD over storage. **Policy-free** (no limit/validation logic). Never throws — returns `Result`. Lives in `domain/`; implemented by `data/IsarSubscriptionRepository`.

```dart
abstract interface class SubscriptionRepository {
  /// Reactive list of all subscriptions, newest renewal first is NOT assumed —
  /// ordering is the caller's concern. Emits on every change.
  Stream<List<Subscription>> watchAll();

  /// One-shot read of all subscriptions.
  Future<Result<List<Subscription>>> getAll();

  /// Current stored count (used by the free-tier use case).
  Future<Result<int>> count();

  Future<Result<Subscription?>> getById(int id);

  /// Persists a new subscription. Returns the stored entity with its assigned id.
  /// Does NOT enforce the free-tier limit (that is the use case's job).
  Future<Result<Subscription>> add(Subscription subscription);

  /// Updates an existing subscription (same id). Fails with NotFoundError if absent.
  Future<Result<Subscription>> update(Subscription subscription);

  Future<Result<void>> delete(int id);
}
```

**Contract guarantees**
- All methods complete without throwing; failures arrive as `Failure(AppError)`.
- `add` returns a `Subscription` whose `id` is non-null and stable.
- `update` preserves `id` and `createdAt`; bumps `updatedAt`.
- Storage open/IO failures → `Failure(StorageError)`.
- Fully offline; no method performs network IO.

---

## 2. `PremiumStatus` (domain abstraction)

```dart
abstract interface class PremiumStatus {
  /// True if the user has unlocked premium (no subscription cap).
  bool get isPremium;
}
```
- This feature ships a stub returning `false`. The `paywall` feature overrides the Riverpod provider with a RevenueCat-backed implementation.

---

## 3. Use cases (domain — the public funnel UI uses)

```dart
class AddSubscription {
  AddSubscription(this._repo, this._premium, this._validator);

  /// 1) validate draft → 2) if not premium and count >= kFreeSubscriptionLimit
  ///    → Failure(LimitReachedError) → 3) repo.add()
  Future<Result<Subscription>> call(SubscriptionDraft draft);
}

class UpdateSubscription {
  /// Validates then repo.update(). No limit check (FR-018).
  Future<Result<Subscription>> call(int id, SubscriptionDraft draft);
}

class DeleteSubscription {
  Future<Result<void>> call(int id);
}

class WatchSubscriptions {
  Stream<List<Subscription>> call();
}
```

**Behavioral contract (maps to spec)**
| Scenario | Expected result |
|----------|-----------------|
| Valid draft, free user, count < 5 | `Success(Subscription)` with id (US1/US3) |
| Valid draft, free user, count == 5 | `Failure(LimitReachedError)`, store unchanged (FR-016) |
| Valid draft, premium user, count ≥ 5 | `Success` (FR-017) |
| Invalid draft (any rule) | `Failure(ValidationError)` before any write (FR-006/007/008/009) |
| Update existing (any count) | not limited (FR-018) |
| Delete then add at limit | add succeeds (FR-018) |

---

## 4. `BrandResolver` (domain service)

```dart
class BrandResolver {
  const BrandResolver([List<BrandCatalogEntry> catalog = kBrandCatalog]);

  /// Returns the matching entry or null (no error) for unknown names.
  BrandCatalogEntry? resolve(String serviceName);
}
```

**Contract**
- Case-insensitive, Turkish-character tolerant, alias-aware (FR-012).
- Deterministic single best match (edge case: collision).
- `null` for unknown (FR-013) — never throws.
- All 12 mandatory entries resolvable by `displayName` (FR-011/SC-003).

---

## 5. Riverpod providers (application — what UI imports)

```dart
final isarProvider              // FutureProvider<Isar>            (core/storage)
final subscriptionRepositoryProvider  // Provider<SubscriptionRepository>
final premiumStatusProvider     // Provider<PremiumStatus>  (stub: isPremium=false)
final brandResolverProvider     // Provider<BrandResolver>
final addSubscriptionProvider   // Provider<AddSubscription>
final updateSubscriptionProvider
final deleteSubscriptionProvider
final subscriptionsProvider     // StreamProvider<List<Subscription>>  (watchAll)
```
- UI/features depend on these, **not** on `IsarSubscriptionRepository` or `Isar` directly.
- `premiumStatusProvider` is the documented override seam for the paywall feature.
