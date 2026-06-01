# Contracts: Dashboard

The stable seams the dashboard exposes/consumes. UI depends on these; internals may change.

---

## 1. Consumed (from `subscriptions-core`)

```dart
final subscriptionsProvider; // StreamProvider<List<Subscription>>  — existing
final brandResolverProvider; // Provider<BrandResolver>             — existing
```
Dashboard reads only these; it never imports the repository or Isar.

---

## 2. Derived providers (this feature)

```dart
/// Subscriptions as sorted upcoming payments (soonest effective renewal first).
final upcomingPaymentsProvider = Provider<AsyncValue<List<UpcomingPayment>>>(...);

/// Per-currency monthly totals (TRY→USD→EUR, no cross-currency sum).
final monthlySummaryProvider = Provider<AsyncValue<List<CurrencyTotal>>>(...);
```

**Contract**
- Both mirror the loading/error/data state of `subscriptionsProvider` (FR-013).
- `upcomingPaymentsProvider` data is sorted by `effectiveRenewal` asc, tie-break by name; every item's `effectiveRenewal` is ≥ today (FR-001/002/005).
- `monthlySummaryProvider` data sums `monthlyAmount` per currency; never across currencies; omits empty currencies (FR-007/008/009).
- Both re-emit automatically when the underlying stream changes (FR-010).
- A `now` source is injectable (provider override) so date-dependent output is testable.

---

## 3. Pure functions (domain — unit-tested)

```dart
DateTime effectiveNextRenewal(Subscription s, DateTime now);
double   monthlyAmount(Subscription s);
List<CurrencyTotal> currencySummary(List<Subscription> subs);
String   relativeDateLabel(DateTime renewal, DateTime now);
```
Behavior per data-model.md. No Flutter imports; deterministic given inputs.

---

## 4. Widgets (presentation)

```dart
class DashboardScreen extends ConsumerWidget { ... }      // route '/'
class MonthlySummaryCard extends StatelessWidget {        // List<CurrencyTotal>
  const MonthlySummaryCard({required this.totals});
}
class PaymentListItem extends StatelessWidget {           // one UpcomingPayment
  const PaymentListItem({required this.payment, this.onTap});
}
class DashboardEmptyState extends StatelessWidget {       // add CTA
  const DashboardEmptyState({required this.onAdd});
}
```

### Reusable (shared)
```dart
class BrandAvatar extends StatelessWidget {
  /// Renders the catalog SVG logo on the brand color when [serviceKey] resolves;
  /// otherwise a neutral tile with [fallbackName]'s initial.
  const BrandAvatar({this.serviceKey, required this.fallbackName, this.size = 48});
}
```

**UI contract**
- `DashboardScreen` renders the four states (loading/error/empty/data) (FR-011/013), dark mode (FR-015), read-only (FR-014), and an add-navigation CTA (FAB when populated, button in empty state) routing toward the add flow — destination out of scope (FR-012).
- `PaymentListItem` shows name (truncated), amount+currency, relative-time label, and `BrandAvatar`; brand color accent (FR-003/004/006).
