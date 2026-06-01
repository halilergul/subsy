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

### Widget testinde ListView'de alt buton "bulunamıyor"
- **Tarih:** 2026-06-01
- **Konu:** Test
- **Detay:** Form `ListView` içinde; varsayılan 800x600 test yüzeyinde alttaki "Kaydet" butonu lazy-build nedeniyle ağaçta olmadığından `find.text` 0 bulur, `tap` patlar.
- **Çözüm/Önlem:** Testte `tester.view.physicalSize = Size(1080, 2600)` + `devicePixelRatio = 1.0` ile uzun yüzey kur (tearDown'da reset), ya da `scrollUntilVisible` kullan. Bkz. `test/widget/subscription_form_screen_test.dart`.
