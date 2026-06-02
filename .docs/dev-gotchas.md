# Teknik Gotcha'lar ve Bilinen Sorunlar

## Nasıl kullanılır

Geliştirme sırasında keşfedilen, sonraki oturumda bilmen gereken
teknik tuzaklar, sürprizler ve dikkat edilmesi gereken noktalar buraya kaydedilir.

Agent'lar bu dosyayı şu durumlarda günceller:
- Beklenmedik bir davranış keşfedildiğinde
- Bir hatanın kök nedeni bulunduğunda
- Belirli bir kütüphane veya altyapıyla ilgili kritik bilgi öğrenildiğinde
- "Bunu daha önce bilseydim saatlerimi kurtarırdım" niteliğinde bilgi

## Format

```
### [Kısa başlık]
- **Tarih:** YYYY-MM-DD
- **Konu:** Frontend / Backend / Mobil / Veritabanı / Altyapı / Tooling
- **Detay:** Ne oluyor ve neden oluyor?
- **Çözüm/Önlem:** Nasıl ele alınmalı?
```

---

## Kayıtlar

### Isar paketi: `isar_community` kullanılıyor (orijinal değil)
- **Tarih:** 2026-06-01
- **Konu:** Veritabanı / Tooling
- **Detay:** Orijinal `isar` paketi 2023'te 3.1.0+1'de donmuş. Aktif fork `isar_community` (3.3.2, Mart 2026). Import yolu `package:isar_community/isar.dart`, generator `isar_community_generator`, flutter libs `isar_community_flutter_libs`.
- **Çözüm/Önlem:** Yeni model eklerken `package:isar_community/...` kullan. `riverpod_lint` + `custom_lint`, isar_community_generator ile analyzer sürüm çakışması yaptığı için pubspec'e EKLENMEDİ — eklemeye çalışma, version solving patlar.

### Isar testleri: `initializeIsarCore(download: true)` + temp dir
- **Tarih:** 2026-06-01
- **Konu:** Veritabanı / Test
- **Detay:** `flutter test` host VM'de Isar native binary'sine ihtiyaç duyar. `setUpAll`'da `await Isar.initializeIsarCore(download: true)` çağrılmazsa repository integration testleri çalışmaz (ilk seferde binary indirir, ağ gerekir).
- **Çözüm/Önlem:** Integration testlerde: `Directory.systemTemp.createTempSync` ile izole klasör, her test için benzersiz instance adı, `tearDown`'da `close(deleteFromDisk: true)`. "Restart sonrası kalıcılık" testi için aynı dir+name ile kapat-yeniden-aç. Bkz. `test/integration/isar_subscription_repository_test.dart`.

### Enum'lar Isar'da isimle saklanıyor (`EnumType.name`)
- **Tarih:** 2026-06-01
- **Konu:** Veritabanı
- **Detay:** `@Enumerated(EnumType.name)` kullanıldı. Ordinal (default) olsaydı enum sırası değişince eski kayıtlar bozulurdu.
- **Çözüm/Önlem:** Enum'a yeni değer eklemek güvenli; mevcut sabitlerin **adını değiştirme** (saklanan string kırılır).

### `Currency.tryl` — `try` rezerve kelime
- **Tarih:** 2026-06-01
- **Konu:** Mobil / Dart
- **Detay:** TRY için enum sabiti `try` olamaz (Dart anahtar kelimesi). `tryl` kullanıldı; ISO kodu `.code` getter'ından (`'TRY'`) gelir.
- **Çözüm/Önlem:** Para birimi kodu gerekince `currency.code`, eşleme için `Currency.fromCode('TRY')`.

### Riverpod 3.2.1: AsyncValue getter'ı + family Notifier API
- **Tarih:** 2026-06-01
- **Konu:** Mobil / State
- **Detay:** (1) `AsyncValue.valueOrNull` bu sürümde yok — veri/null için `asData?.value` kullan. (2) Codegen'siz `NotifierProvider.family` base-class API'si (3.x'te `AutoDispose*` sınıfları kaldırıldı, birleşik `Notifier`) belirsiz/karışık; form controller'ı bu yüzden plain `ChangeNotifier` yapıldı (use case'ler constructor'dan enjekte, ekran provider'lardan `ref.read` ile kurar). Daha kolay test edilebilir bonus.
- **Çözüm/Önlem:** Form/ekran controller'ları için `ChangeNotifier` + DI deseni tercih et; AsyncValue'dan veri çekerken `asData?.value`. Provider'lar (use case wiring) manuel `Provider`/`StreamProvider` olarak yazılıyor (riverpod_generator yalnızca gerektiğinde).

### flutter_local_notifications 22.0-dev API farkları
- **Tarih:** 2026-06-01
- **Konu:** Mobil / Bildirim
- **Detay:** 22.0.0-dev.3 sürümünde imzalar stable'dan farklı: `initialize(settings: const InitializationSettings(...))` (named, positional değil); `zonedSchedule` `title`/`body`'yi NAMED parametre olarak alır (NotificationDetails içinde değil) ve `androidScheduleMode` zorunlu; `AndroidInitializationSettings('@mipmap/ic_launcher')` positional; iOS sınıfı `IOSFlutterLocalNotificationsPlugin.requestPermissions(alert/badge/sound)`, Android `requestNotificationsPermission()`.
- **Çözüm/Önlem:** Paket güncellenince imzaları tekrar doğrula. Zamanlama `AndroidScheduleMode.inexactAllowWhileIdle` (exact-alarm izni gerekmez). `flutter_timezone` 5.x `getLocalTimezone()` → `TimezoneInfo`, IANA adı `.identifier`. Bkz. `lib/features/notifications/data/local_notification_service.dart`.

### Widget testinde ListView'de alt buton "bulunamıyor"
- **Tarih:** 2026-06-01
- **Konu:** Test
- **Detay:** Form `ListView` içinde; varsayılan 800x600 test yüzeyinde alttaki "Kaydet" butonu lazy-build nedeniyle ağaçta olmadığından `find.text` 0 bulur, `tap` patlar.
- **Çözüm/Önlem:** Testte `tester.view.physicalSize = Size(1080, 2600)` + `devicePixelRatio = 1.0` ile uzun yüzey kur (tearDown'da reset), ya da `scrollUntilVisible` kullan. Bkz. `test/widget/subscription_form_screen_test.dart`.

### Riverpod 3.x: `StateProvider` legacy export'ta
- **Tarih:** 2026-06-01
- **Konu:** Mobil / Tooling
- **Detay:** `flutter_riverpod` 3.x'te `StateProvider` ana export'tan çıkarıldı; sadece `flutter_riverpod.dart` import edince "The function 'StateProvider' isn't defined" hatası verir.
- **Çözüm/Önlem:** `StateProvider` kullanan dosyalarda ek olarak `import 'package:flutter_riverpod/legacy.dart';` ekle. Sadece provider tanımının olduğu dosyada gerekir — `.notifier`/`.state` erişimi (örn. `ref.read(p.notifier).state = x`) ana export ile çalışır, tüketici widget'ta legacy import gerekmez. (statistics_providers.dart örneği.)

### frankfurter API: host taşındı + base `rates`'te yok
- **Tarih:** 2026-06-01
- **Konu:** Mobil / Altyapı
- **Detay:** `api.frankfurter.app` artık `api.frankfurter.dev`'e **301 redirect** ediyor — `.app` çağrılırsa fazladan hop olur. Ayrıca API yanıtındaki `rates` objesi **base para birimini içermez** (örn. `base=EUR` çağrısında EUR `rates`'te yoktur). Çevrim için base'i `1.0` olarak haritaya elle eklemek gerekir.
- **Çözüm/Önlem:** Doğrudan `https://api.frankfurter.dev/v1/latest?base=EUR&symbols=USD,TRY` çağır; parse'ta `map[base] = 1.0` enjekte et. (HttpExchangeRateService.) TRY ECB üzerinden destekleniyor.

### App-root sync provider'ları guard'lı olmalı
- **Tarih:** 2026-06-01
- **Konu:** Mobil / Tooling
- **Detay:** `SubsyApp.build` içinde `ref.watch`'lanan bir Provider'ın build gövdesinde, override gerektiren (UnimplementedError fırlatan) veya henüz hazır olmayan (`isarDatabaseProvider.requireValue`) bir provider'ı doğrudan `ref.watch` etmek, boot smoke testini (ve override edilmemiş ortamları) çökertir.
- **Çözüm/Önlem:** Best-effort sync'lerde okumaları async gövde içine al + `try/catch` ile sar; DB gerekiyorsa `await ref.read(isarDatabaseProvider.future)`. (exchange_rate_sync.dart deseni; reminder_sync de asData?.value ile null-safe.)

### home_widget: native iskele + iOS Xcode manuel adımı
- **Tarih:** 2026-06-01
- **Konu:** Mobil / Native
- **Detay:** Widget UI native'dir. Android tarafı tamamen dosya-tabanlı (receiver Manifest'te, `SubsyWidgetProvider` + `res/layout` + `res/xml`). iOS tarafı bir **WidgetKit extension target'ı** gerektirir — `project.pbxproj` güvenilir şekilde script'lenemez, bu yüzden target + App Group capability **Xcode'da elle** eklenir (bkz. `ios/SubsyWidget/README.md`). App Group: `group.com.halilergul.subsy` hem Runner hem extension'da olmalı; `HomeWidget.setAppGroupId(...)` main'de çağrılır.
- **Çözüm/Önlem:** Dart payload hattı (saf `buildWidgetPayload` + `publishWidget`) test edilir; native render cihazda doğrulanır. Logic native'e taşınmaz — native yalnızca `state` key'ine göre hazır Türkçe string'leri render eder. v1'de marka logosu native'de yok (Flutter SVG asset'i native widget'a taşınmıyor) → servis adı gösterilir.

### ref.listen tabanlı sync'i ProviderContainer'da test etmek kırılgan
- **Tarih:** 2026-06-01
- **Konu:** Mobil / Tooling
- **Detay:** `Provider<void>` içinde `ref.listen` + stream emisyonu, bare `ProviderContainer` testinde zamanlama nedeniyle güvenilir tetiklenmiyor (publish hiç çalışmadı). reminder_sync deseni de bunu yapmaz.
- **Çözüm/Önlem:** Orkestrasyon mantığını top-level saf bir fonksiyona çıkar (`publishWidget(service, {...})`) ve onu doğrudan fake ile test et; provider yalnızca ince bir `ref.listen` sarmalayıcı olsun (reminder_sync'in `rescheduleAll`'ı gibi).

### OCR import (009): ML Kit iOS 16 tabanı, parser determinizmi, OcrService swap
- **Tarih:** 2026-06-02
- **Konu:** Mobil / OCR import
- **Detay:**
  - `google_mlkit_text_recognition` iOS 16 ister → `ios/Podfile` + `project.pbxproj` (3× `IPHONEOS_DEPLOYMENT_TARGET`) 13.0'dan 16.0'a çıkarıldı. iPhone 7 ve öncesi (2016-) düşer; premium feature olduğu için pratik kayıp ~yok ama **tüm uygulamanın** tabanı yükselir. ML Kit pod'u koşullu yapılamaz (hep-ya-hiç).
  - `syncfusion_flutter_pdf` eski sürümleri `intl <0.20` pinler → projedeki `intl ^0.20.2` ile çakışır. `^33.2.8` (güncel major) ile çözülür.
  - **Tüm tanıma mantığı saf Dart** (`SubscriptionParser` + amount/date/brand/duplicate helper'ları); `OcrService` tek impure dikiş. Parser'a `now` enjekte edilir (`DateTime.now()` içeride yok) → deterministik fixture testleri.
  - **`OcrService` arayüzü** sayesinde iOS'u native Apple Vision'a (iOS 13, sıfır boyut) çevirmek lokal bir değişiklik — kullanıcı düşüşü sorun olursa buradan dönülür.
  - **Cihaz doğrulaması ertelendi:** ML Kit native render, foto/kamera izinleri ve **taranmış PDF rasterizasyonu** bu ortamda derlenemez. Metin-tabanlı PDF (syncfusion, saf Dart) çalışır ve test edilir; taranmış PDF → boş metin → "tanınamadı" durumu (rasterizasyon fallback cihazda eklenecek).
  - **App Store/Play okunamaz** (platform kısıtı): sistem abonelik ekranının ekran görüntüsü OCR ile okunur; ayrı bir teknoloji değil, görsel import akışına katlanır.
