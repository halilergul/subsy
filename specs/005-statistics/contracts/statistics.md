# Contracts: Statistics

---

## 1. Consumed (existing)

```dart
final subscriptionsProvider;            // StreamProvider<List<Subscription>>  (core)
double monthlyAmount(Subscription s);   // dashboard domain
String formatMoney(double, Currency);   // shared util
class BrandAvatar ...                    // shared widget
```

---

## 2. Pure aggregator (this feature)

```dart
double periodAmount(Subscription s, StatPeriod p);
List<CategoryBreakdown> categoryBreakdowns(List<Subscription> subs, StatPeriod p);
Map<Currency, List<RankedSubscription>> topSubscriptions(
    List<Subscription> subs, StatPeriod p, {int? limit});
StatisticsView buildStatistics(List<Subscription> subs, StatPeriod p);
```

**Contract**
- Per-currency only; never sums/ranks across currencies (FR-005).
- Category percentages within a currency sum to 100 (display-rounded) (FR-004).
- Yearly amounts = monthly × 12; percentages identical across periods (FR-006/007).
- Empty input → `StatisticsView.isEmpty == true`, empty breakdowns.
- Deterministic given inputs; no Flutter imports.

---

## 3. Application wiring

```dart
final statPeriodProvider = StateProvider<StatPeriod>((_) => StatPeriod.monthly);
final statisticsProvider = Provider<AsyncValue<StatisticsView>>((ref) {
  final period = ref.watch(statPeriodProvider);
  return ref.watch(subscriptionsProvider).whenData((subs) => buildStatistics(subs, period));
});
```
- Re-derives on subscription change (FR-010) and on period toggle.

---

## 4. UI + routing

```dart
class StatisticsScreen extends ConsumerWidget { ... }   // route '/statistics'
// Routes.statistics = '/statistics'; dashboard AppBar gains an insights IconButton.

class CategoryDonut extends StatelessWidget {           // fl_chart PieChart for one breakdown
  const CategoryDonut({required this.breakdown});
}
class CategoryLegend extends StatelessWidget {          // color dot + label + amount + %
  const CategoryLegend({required this.breakdown});
}
class TopSubscriptions extends StatelessWidget {        // ranked list (BrandAvatar)
  const TopSubscriptions({required this.items});
}
```

**UI contract**
- Aylık/Yıllık `SegmentedButton` bound to `statPeriodProvider` (FR-006/007).
- One section per currency: total + donut + legend; below, the top list (FR-002/008/009).
- Loading/error/empty per states; dark mode + Turkish (FR-011/012/013); read-only (FR-014).

---

## 5. Shared addition

```dart
// lib/shared/constants/category_style.dart
Color categoryColor(SubscriptionCategory c);
String categoryLabel(SubscriptionCategory c);   // Turkish
```
Reused by donut, legend, and future screens.
