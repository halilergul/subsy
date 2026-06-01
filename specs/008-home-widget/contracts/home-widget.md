# Contracts: Home Screen Widget

---

## 1. Consumed (existing)

```dart
final subscriptionsProvider;              // StreamProvider<List<Subscription>>
final premiumStatusProvider;              // Provider<PremiumStatus>
final targetCurrencyProvider;             // StreamProvider<Currency>   (currency feature)
final exchangeRatesProvider;              // StreamProvider<ExchangeRates?> (currency feature)
class UpcomingPayment { ... }             // dashboard (effective renewal)
String relativeDateLabel(DateTime, DateTime);
List<CurrencyTotal> currencySummary(List<Subscription>);
UnifiedTotal? unifiedMonthlyTotal(List<Subscription>, Currency, ExchangeRates);
String formatMoney(double, Currency);
```

---

## 2. Pure builder (this feature)

```dart
WidgetPayload buildWidgetPayload({
  required List<Subscription> subs,
  required DateTime now,
  required bool isPremium,
  required Currency target,
  ExchangeRates? rates,
});
```

**Contract**
- `!isPremium` → `state == locked`, all figures empty (FR-008/SC-004).
- empty subs → `state == empty` (FR-004).
- ready → `nextTitle/when/amount` from the soonest effective renewal (= dashboard top, SC-001); `totalLine` = dashboard monthly summary (SC-002); `unifiedLine` only when premium + rates yield a total, else empty (FR-003).
- Pure, deterministic (`now` injected); no Flutter/plugin imports.

---

## 3. Service (this feature)

```dart
abstract interface class HomeWidgetService {
  Future<void> publish(WidgetPayload payload);  // saveWidgetData(keys) + updateWidget(...)
  Future<void> clear();                          // optional: blank the widget
}

class PluginHomeWidgetService implements HomeWidgetService {
  // HomeWidget.saveWidgetData(<key>, <value>) for each payload key, then
  // HomeWidget.updateWidget(androidName: kAndroidWidgetProvider, iOSName: kIosWidgetName);
  // best-effort; never throws.
}
```

**Widget data keys** (primitive): `state`, `next_title`, `next_when`, `next_amount`, `next_service_key`, `total_line`, `unified_line`.

**Named consts**: `kAndroidWidgetProvider = 'SubsyWidgetProvider'`, `kIosWidgetName = 'SubsyWidget'`, `kWidgetAppGroupId = 'group.com.halilergul.subsy'`.

---

## 4. Application wiring

```dart
final homeWidgetServiceProvider = Provider<HomeWidgetService>((ref) {
  throw UnimplementedError('overridden in main()');   // plugin impl injected at boot
});

void startHomeWidgetSync(WidgetRef ref);   // watch subs/target/rates/premium → publish (best-effort)
```
- In `main`: `HomeWidget.setAppGroupId(kWidgetAppGroupId)` (iOS), override `homeWidgetServiceProvider` with `PluginHomeWidgetService`.
- In `SubsyApp.build`: `startHomeWidgetSync(ref)` beside the other syncs.

---

## 5. Native (device-verified)

**Android** — `SubsyWidgetProvider : HomeWidgetProvider`, `res/layout/subsy_widget.xml` (dark compact: title / when / amount / total TextViews), `res/xml/subsy_widget_info.xml`, Manifest `<receiver>` with `APPWIDGET_UPDATE`. Reads keys via the widget `SharedPreferences`; root view → launch `MainActivity`.

**iOS** — `SubsyWidget` WidgetKit extension (SwiftUI), reads the App Group `UserDefaults(suiteName: kWidgetAppGroupId)`, renders the same fields; `.widgetURL` opens the app. App Group entitlement on Runner + extension.

**UI contract**: dark + Turkish; `state` selects layout (ready / empty / locked); tap opens app (FR-010/011/012). Logo rendering is a follow-up — v1 shows the service name (+ optional brand-color accent).
