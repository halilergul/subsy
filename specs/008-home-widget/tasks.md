---

description: "Task list for Home Screen Widget (Premium) implementation"
---

# Tasks: Home Screen Widget (Premium)

**Input**: Design documents from `/specs/008-home-widget/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/home-widget.md, quickstart.md

**Tests**: Included — the spec's Success Criteria (SC-001..006) require unit coverage of the pure payload builder and the reactive sync. Native rendering is device-verified (manual), not unit-testable here.

**Organization**: Grouped by user story (P1→P2). The payload value type, service interface, plugin impl, and providers are Foundational (shared by every story). The native widget UI is built incrementally within the stories and verified on a device.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: US1..US4 (maps to spec.md user stories)
- Exact file paths included. **[device]** marks tasks whose result is verified on a real device (not buildable in this environment).

## Path Conventions

Flutter feature-first: `lib/features/home_widget/{domain,data,application}`. Native: `android/app/src/main/{kotlin,res}` + Manifest, `ios/SubsyWidget` + entitlements. Tests under `test/unit/`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Named constants for the widget data keys and native target names (no magic strings).

- [X] T001 [P] Create `lib/features/home_widget/domain/widget_keys.dart` with named consts: data keys (`state`, `next_title`, `next_when`, `next_amount`, `next_service_key`, `total_line`, `unified_line`), `kAndroidWidgetProvider = 'SubsyWidgetProvider'`, `kIosWidgetName = 'SubsyWidget'`, `kWidgetAppGroupId = 'group.com.halilergul.subsy'`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The payload value type, the service seam, and providers — shared by all stories. No story UI/logic until these exist.

- [X] T002 [P] Create `lib/features/home_widget/domain/widget_payload.dart` — `enum WidgetState { ready, empty, locked }` + `WidgetPayload` value (state + nextTitle/nextWhen/nextAmount/nextServiceKey/totalLine/unifiedLine) + `Map<String,String> toMap()` keyed by `widget_keys.dart`
- [X] T003 [P] Create `lib/features/home_widget/domain/home_widget_service.dart` — `abstract interface class HomeWidgetService { Future<void> publish(WidgetPayload); Future<void> clear(); }` (never throws)
- [X] T004 Create `lib/features/home_widget/data/plugin_home_widget_service.dart` — `PluginHomeWidgetService`: for each `toMap()` entry `HomeWidget.saveWidgetData(key, value)`, then `HomeWidget.updateWidget(androidName: kAndroidWidgetProvider, iOSName: kIosWidgetName)`; wrap in try/catch (best-effort, offline-safe)
- [X] T005 Create `lib/features/home_widget/application/home_widget_providers.dart` — `homeWidgetServiceProvider` (Provider<HomeWidgetService> throwing UnimplementedError; overridden in main)
- [X] T006 [P] Extend `test/support/fakes.dart` — `FakeHomeWidgetService` recording `lastPayload` / publish count

**Checkpoint**: Payload + service seam compile; fake available. No builder logic yet.

---

## Phase 3: User Story 1 — Glance at the next payment (Priority: P1) 🎯 MVP

**Goal**: A premium user sees the soonest upcoming renewal (brand name + "N gün sonra" + amount) on the home screen; tapping opens the app.

**Independent Test**: Seed subscriptions → payload's next = dashboard's soonest item (name, relative-day label, amount).

- [X] T007 [US1] Create `lib/features/home_widget/domain/widget_payload_builder.dart` — pure `buildWidgetPayload({subs, now, isPremium, target, rates})`; for the **ready** path select the soonest `effectiveNextRenewal` (tie-break by name), set `nextTitle`/`nextWhen` (`relativeDateLabel`)/`nextAmount` (`formatMoney`)/`nextServiceKey`; empty/locked branches stubbed for now (filled in US4)
- [X] T008 [P] [US1] Create `test/unit/widget_payload_builder_test.dart` — next-payment selection uses effective (rolled-forward) renewal, correct relative-day label + amount, matches dashboard top (SC-001)
- [X] T009 [US1] [device] Android widget: `android/app/src/main/kotlin/com/halilergul/subsy/SubsyWidgetProvider.kt` (extends `HomeWidgetProvider`, reads keys, binds title/when/amount), `res/layout/subsy_widget.xml` (dark compact), `res/xml/subsy_widget_info.xml`, and a `<receiver>` with `APPWIDGET_UPDATE` in `AndroidManifest.xml`; root view PendingIntent → `MainActivity` (tap-to-open, FR-010)
- [X] T010 [US1] [device] iOS widget: `ios/SubsyWidget/` WidgetKit extension (SwiftUI timeline reading App Group `UserDefaults(suiteName: kWidgetAppGroupId)`, shows next payment) + `Info.plist`; add the App Group entitlement to `ios/Runner/Runner.entitlements` and `SubsyWidget.entitlements`; `.widgetURL` opens the app

**Checkpoint**: MVP — the next payment is visible on the home screen (device-verified) for premium users.

---

## Phase 4: User Story 2 — See the monthly total (Priority: P1)

**Goal**: Below the next payment, the monthly total (per currency) + the premium unified ≈ total when rates exist.

**Independent Test**: Mixed-currency subs → payload `totalLine` == dashboard summary; `unifiedLine` only when premium + rates.

- [X] T011 [US2] Extend `buildWidgetPayload` in `widget_payload_builder.dart` — `totalLine` from `currencySummary(subs)` (`formatMoney` joined, " / ay"); `unifiedLine` = `'≈ ' + formatMoney(unifiedMonthlyTotal(subs, target, rates).amount, target) + ' / ay'` only when `isPremium && rates != null` and the total is non-null, else `''`
- [X] T012 [P] [US2] Extend `test/unit/widget_payload_builder_test.dart` — `totalLine` equals per-currency summary; `unifiedLine` present only with rates, empty otherwise (SC-002)
- [X] T013 [US2] [device] Add the total + unified rows to `res/layout/subsy_widget.xml` (+ bind in `SubsyWidgetProvider.kt`) and to the iOS `SubsyWidget` SwiftUI view

**Checkpoint**: Widget shows next payment + monthly total (+ unified) — full ready content.

---

## Phase 5: User Story 3 — Stay in sync automatically (Priority: P2)

**Goal**: The widget republishes whenever subscriptions, rates, target currency, or premium status change.

**Independent Test**: Emit a subscription/premium change → the published payload updates within the session.

- [X] T014 [US3] Create `lib/features/home_widget/application/home_widget_sync.dart` — `startHomeWidgetSync(WidgetRef)`: `ref.listen` on `subscriptionsProvider`, `targetCurrencyProvider`, `exchangeRatesProvider`, `premiumStatusProvider`; on change build the payload (`now = DateTime.now()`) and `service.publish(...)`. Read the service via `ref.read` **inside** a guarded async helper (try/catch) so the provider never throws at build (boot-safe, like `exchange_rate_sync`)
- [X] T015 [US3] Wire `lib/main.dart` — `await HomeWidget.setAppGroupId(kWidgetAppGroupId)` at boot, override `homeWidgetServiceProvider` with `PluginHomeWidgetService()`, and call `startHomeWidgetSync(ref)` in `SubsyApp.build` beside `startReminderSync`/`startExchangeRateSync`
- [X] T016 [P] [US3] Create sync unit test (ProviderContainer + `FakeHomeWidgetService` + overridden sources) — changing subscriptions/premium republishes a matching payload (SC-003)

**Checkpoint**: Widget data stays current automatically.

---

## Phase 6: User Story 4 — Premium gating (Priority: P2)

**Goal**: Free users see a locked teaser (never real figures); no subscriptions → empty state.

**Independent Test**: Toggle premium / empty subs → `locked` / `empty` states; figures empty when not ready.

- [X] T017 [US4] Finalize the gating branches in `buildWidgetPayload` — `!isPremium` → `WidgetState.locked` with all figure fields empty (checked first); `subs.isEmpty` → `WidgetState.empty`; else `ready` (FR-004/008/009)
- [X] T018 [P] [US4] Extend `test/unit/widget_payload_builder_test.dart` — free → `locked` + no figures (SC-004); empty subs → `empty`; downgrade flips ready→locked
- [X] T019 [US4] [device] Render the `locked` (upsell) and `empty` ("Abonelik ekle") branches by the `state` key in `subsy_widget.xml`/`SubsyWidgetProvider.kt` and the iOS SwiftUI view (FR-008)

**Checkpoint**: All user stories complete; gating + states honest.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [X] T020 [P] Run `flutter analyze` and resolve warnings in new Dart files
- [X] T021 [P] Run `flutter test` (new builder/sync tests + full suite green; confirm boot smoke test unaffected — sync is guarded)
- [ ] T022 [device] Manual device/simulator verification per quickstart.md (Android + iOS: add widget → next payment + total render; tap opens app; add/delete subscription refreshes; free → locked) — defer if no device available and note it

---

## Dependencies & Execution Order

- **Setup (T001)** → all.
- **Foundational (T002–T006)**: T002/T003 → T004 (impl needs both) ; T005 needs T003; T006 needs T003. Before any story.
- **US1 (T007–T010)**: T007 → T008; T009/T010 (native) consume the published keys — buildable after T007 but verified on device.
- **US2 (T011–T013)**: T011 extends T007's builder → T012; T013 extends the US1 native layout (same files → sequence after T009/T010).
- **US3 (T014–T016)**: needs the service (T004/T005) + builder (T007/T011); T015 wires main; T016 tests with fake.
- **US4 (T017–T019)**: T017 edits the same builder (after T007/T011); T019 edits the same native files (after T009/T010/T013).
- **Polish (T020–T022)**: after all implementation.

> Note: the builder file (T007/T011/T017) and the native widget files (T009/T013/T019) are edited by multiple stories — sequence those edits; don't parallelize across stories.

## Parallel Opportunities

- Foundational: **T002 ∥ T003**; **T006** alongside.
- Per story, the unit test is [P]: **T008, T012, T016, T018**.
- Polish: **T020 ∥ T021**.
- Android (T009) and iOS (T010) native scaffolds are different file trees → can be done in parallel within US1.

## Implementation Strategy

**MVP = Setup + Foundational + User Story 1** (T001–T010): the payload pipeline + the home-screen widget showing the next payment (device-verified). Then layer US2 (monthly total), US3 (reactive sync), US4 (gating). The pure `buildWidgetPayload` is unit-tested to the spec's measurable criteria before/as the native UI consumes it; dashboard + currency logic are reused unchanged (the widget is an additive read-only mirror). Native rendering is verified on a device — the only part not automatable in this environment.
