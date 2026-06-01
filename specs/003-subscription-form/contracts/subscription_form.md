# Contracts: Subscription Form

---

## 1. Consumed (from `subscriptions-core`)

```dart
final addSubscriptionProvider;    // Provider<AddSubscription>
final updateSubscriptionProvider; // Provider<UpdateSubscription>
final deleteSubscriptionProvider; // Provider<DeleteSubscription>
final brandResolverProvider;      // Provider<BrandResolver>
```
The form depends only on these; it never touches the repository or Isar directly. All business rules stay in the use cases.

---

## 2. Form controller (this feature)

```dart
/// Holds form state and orchestrates submit/delete. autoDispose + family on the
/// optional editing subscription (null = add mode).
final subscriptionFormControllerProvider =
    NotifierProvider.autoDispose.family<SubscriptionFormController, SubscriptionFormState, Subscription?>(...);

class SubscriptionFormController extends ... {
  // field setters
  void setName(String v);
  void setAmountText(String v);
  void setCurrency(Currency v);
  void setBillingPeriod(BillingPeriod v);
  void setNextRenewalDate(DateTime v);
  void setCategory(SubscriptionCategory? v);
  void setStartDate(DateTime? v);
  void setNotes(String? v);

  Future<void> submit();   // add or update; sets saved / errorMessage
  Future<void> delete();   // edit only; sets saved / errorMessage
}
```

**Contract**
- `submit()` builds a `SubscriptionDraft` and calls add (mode=add) or update (mode=edit); maps `Result` per data-model.md. Never throws.
- The free-tier limit applies only in add mode (update never blocks) — guaranteed by calling the respective core use case.
- `delete()` only valid in edit mode; the screen calls it only after confirmation.
- `saved == true` is the signal for the screen to pop.

---

## 3. Routes (central router)

```dart
abstract final class Routes {
  static const String dashboard = '/';
  static const String addSubscription = '/subscription/add';
  static const String editSubscription = '/subscription/edit'; // extra: Subscription
}
```
- `addSubscription` → `SubscriptionFormScreen()` (add).
- `editSubscription` → `SubscriptionFormScreen(subscription: state.extra as Subscription)` (edit).

---

## 4. Widgets

```dart
class SubscriptionFormScreen extends ConsumerWidget {
  const SubscriptionFormScreen({this.subscription});   // null = add
  final Subscription? subscription;
}

class CurrencySelector extends StatelessWidget {        // SegmentedButton<Currency>
  const CurrencySelector({required this.value, required this.onChanged});
}
class PeriodSelector extends StatelessWidget {          // SegmentedButton<BillingPeriod>
  const PeriodSelector({required this.value, required this.onChanged});
}
class BrandPreview extends StatelessWidget {            // resolves name → BrandAvatar
  const BrandPreview({required this.name});
}
```

**UI contract**
- Renders all fields (FR-001), constrained pickers (FR-002), date picker (FR-003), live brand preview (FR-004), optional category (FR-005), dark mode + Turkish (FR-016).
- Save is disabled while `isSubmitting`; on `saved` the screen pops (FR-013).
- Delete shown only when `subscription != null`, behind a confirm dialog (FR-012).
- Dismiss/cancel pops without saving (FR-015).

---

## 5. Dashboard wiring (updated)

- `DashboardScreen`: FAB + empty-state CTA push `Routes.addSubscription` (replaces placeholder SnackBar).
- `PaymentListItem.onTap`: pushes `Routes.editSubscription` with its `Subscription` as `extra`.
