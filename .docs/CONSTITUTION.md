# Subsy — Constitution
_Oluşturulma: 2026-06-01 | Son güncelleme: 2026-06-01_
_Profil: mobile-flutter (mobile-expo overlay'i override edildi)_

## Proje özeti
- **Proje:** Subsy
- **Bundle ID:** `com.halilergul.subsy`
- **Amaç:** Kullanıcıların dijital aboneliklerini (Netflix, Spotify, iCloud+, YouTube Premium, Exxen, Gain vb.) tek yerde takip ettiği; her aboneliğin ne zaman yenileneceğini ve toplam ne kadar harcandığını gösteren, minimalist ama görsel olarak güçlü bir mobil uygulama. Temel felsefe: **%100 offline, sıfır backend** — veriler asla cihazdan çıkmaz. Bu hem güvenlik avantajı hem ana satış argümanıdır.
- **Hedef kullanıcı:** Birden çok dijital aboneliği olan, harcamasını kontrol altında tutmak isteyen son kullanıcı (Türkiye odaklı; çoklu para birimi olanlar dahil).
- **Başarı kriteri:** Kullanıcı aboneliklerini 30 saniyede ekleyebiliyor, ana ekranda yaklaşan ödemeleri ve aylık toplamı net görebiliyor, ödeme öncesi zamanında hatırlatılıyor. Görsel kalite referansı: https://subsday.appps.od.ua

## Teknik stack (mobile-flutter)

> **NOT:** Bu proje `mobile-expo` profiliyle oluşturuldu ancak stack **Flutter** olarak override edildi. Expo/React Native overlay'i ve Supabase backend'i bu projede **kullanılmaz**. `mobile-agent` (Expo) ve `backend-agent` (Supabase) bu projede devre dışıdır.

### Genel kararlar
- **Framework:** Flutter 3.41+ (stable), Dart 3.11+
- **Platform:** iOS + Android
- **Dil:** Dart (strict analyzer, `flutter_lints`)
- **Backend:** **YOK.** Tamamen offline, sunucu/account/cloud sync yok (v1 anti-goal).
- **State / DI:** Riverpod 2 (`flutter_riverpod` + `riverpod_annotation`/codegen)
- **Local storage:** Isar (community / v4) — `RepositoryInterface` arkasına soyutlanır, sonradan değiştirilebilir
- **Bildirim:** `flutter_local_notifications` + `timezone`
- **In-app purchase:** RevenueCat (`purchases_flutter`)
- **Widget:** `home_widget` (premium özelliği)
- **Lint:** `flutter_lints` (+ gerekirse `very_good_analysis`)
- **CI:** TBD (GitHub Actions — ileride)

### Mimari (yeniden kullanılabilir altyapı hedefi)
**Feature-first + katmanlı (data / domain / presentation).** Servis katmanları soyutlanır; ileride başka uygulamalara taşınabilecek `core/` altyapısı hedeflenir.

```
lib/
  main.dart
  app/                      # uygulama seviyesi
    theme/                  # dark mode zorunlu, marka renk sistemi
    router/                 # go_router
    l10n/                   # Türkçe arayüz
  core/                     # APP-AGNOSTIC, yeniden kullanılabilir altyapı
    storage/                # Isar bootstrap + base repository
    notifications/          # NotificationService (soyut arayüz + impl)
    purchases/              # PurchaseService (RevenueCat sarmalayıcı)
    exchange/               # ExchangeRateService (döviz API sarmalayıcı)
    result/  errors/        # Result tipi, hata modelleri
  features/
    subscriptions/
      data/                 # Isar model + repository impl
      domain/               # entity, repository interface, usecase
      presentation/         # ekranlar, widget'lar, Riverpod provider'lar
    dashboard/              # ana ekran: yaklaşan ödemeler + aylık özet
    statistics/             # kategori bazlı harcama, aylık/yıllık
    paywall/                # RevenueCat / premium gate
  shared/
    widgets/                # tekrar kullanılabilir UI primitive'leri
    constants/              # marka kataloğu (hardcoded servis renk+logo)
    utils/
assets/
  logos/                    # hardcoded servis logoları
test/
```

### Kod standartları
- Naming: snake_case (dosya), PascalCase (class/tip), camelCase (değişken/fonksiyon)
- Magic number/string yasak — `const` / enum kullan
- Business logic UI'dan ayrı (domain/usecase + service katmanı)
- UI veriyi Riverpod provider üzerinden alır, doğrudan storage/API'ye dokunmaz
- API/servis çağrıları sadece `core/` servis katmanından
- Yorumlar "why" için; kod kendini açıklamalı
- **Kod İngilizce, arayüz Türkçe** (i18n string'leri `l10n/`)

### Güvenlik
- API key / secret kaynak kodda olmaz (RevenueCat public SDK key `--dart-define` / env)
- Tüm kullanıcı verisi cihazda kalır; ağ trafiği yalnızca opsiyonel döviz kuru çekme (anonim, kişisel veri içermez)
- Input validation her formda (abonelik ekleme)
- Hassas veri gerekirse `flutter_secure_storage`

### Hata yönetimi
- Domain katmanında `Result<T>` / sealed error tipleri (exception fırlatmak yerine)
- Global error boundary (`runZonedGuarded` + Flutter `ErrorWidget`)
- Kullanıcıya teknik detay gösterilmez; Türkçe anlaşılır mesaj
- Döviz API çevrimdışı/başarısızsa son bilinen kur cache'ten kullanılır

## Ürün kapsamı

### MVP (v1)
1. **Abonelik ekleme/düzenleme/silme:** isim, tutar, para birimi, yenileme tarihi, dönem (haftalık/aylık/yıllık)
2. **Marka logosu/renk:** her aboneliğe **gerçek marka logosu** (premium his). Ana yöntem: uygulamayla bundle'lanmış SVG logo kataloğu (offline, garantili). Katalogda yoksa: online logo çekme → cihazda cache; çevrimdışı/bulunamazsa baş-harf + marka rengi son çare.
3. **Ana ekran:** yaklaşan ödemeler listesi + aylık toplam özet (marka renkli kartlar)
4. **Bildirim:** ödeme gününden X gün önce hatırlatma (X kullanıcı ayarı)
5. **İstatistik ekranı:** kategori bazlı harcama, aylık/yıllık toplam
6. **Döviz desteği:** USD/EUR abonelikleri güncel kurla TL'ye çevirme (ücretsiz exchange rate API)

### Freemium yapısı
- **Ücretsiz:** maksimum **5 abonelik**, temel bildirimler
- **Premium (tek seferlik satın alma — RevenueCat):** sınırsız abonelik, ana ekran widget'ı, döviz çevirisi, CSV export, takvim sync

### Hardcoded servis kataloğu (TR odaklı — marka renk + logo hazır)
Spotify, Netflix, YouTube Premium, Apple TV+, iCloud+, ChatGPT Plus, Claude Pro, Exxen, Gain, BluTV, Trendyol Premium, Amazon Prime

### Anti-goal'ler (v1'de YOK)
- ❌ Backend / sunucu / kullanıcı hesabı / login
- ❌ Cloud sync / cihazlar arası senkronizasyon
- ❌ Multi-tenant / paylaşım / sosyal özellik
- ❌ Banka entegrasyonu / otomatik abonelik tespiti
- ❌ Web sürümü (sadece iOS + Android)

## Görsel kimlik
- **Dark mode zorunlu** (ışık modu opsiyonel/sonra)
- Her abonelik kartı servisin **marka rengiyle** renklendirilir
- Belirgin ikonlar, temiz ve hiyerarşik layout
- Kalite referansı: subsday seviyesinde
- Tasarım kararları feature başına `.docs/UIUX-NNN.md` ile (Figma yok → ui-ux-agent karar verir, sonra uyum kontrolü)

## i18n / Dil
- **Arayüz dili:** Türkçe (birincil)
- **Kod dili:** İngilizce
- **Türkçe karakter desteği:** Etkin — `ı, İ, ş, Ş, ç, Ç, ğ, Ğ, ö, Ö, ü, Ü` her yerde test edilir (sıralama, arama, görüntüleme)
- Para/tarih biçimlendirme: `intl` (tr_TR locale)

## Mimari kararlar
| Tarih | Karar | Gerekçe |
|-------|-------|---------|
| 2026-06-01 | Proje başlatıldı | — |
| 2026-06-01 | Stack: mobile-expo → **Flutter** override | Kullanıcı talebi; tek dilde native iOS+Android |
| 2026-06-01 | Backend YOK, %100 offline | Sıfır sunucu maliyeti + "veriler cihazdan çıkmaz" satış/güvenlik argümanı |
| 2026-06-01 | State/DI: **Riverpod 2** | Compile-safe DI, soyutlanmış/test edilebilir servis katmanı |
| 2026-06-01 | Local storage: **Isar** (repository soyutlamasıyla) | Tip-güvenli, istatistik query'leri güçlü; soyutlama ile değiştirilebilir |
| 2026-06-01 | Akış: **tam spec-kit** (specify→plan→tasks→implement) | Kullanıcı tercihi |
| 2026-06-01 | Logo: **bundled SVG marka logosu** katalog + online fallback (cache) | Gerçek marka logosu = premium his; bundle ile offline garanti |
| 2026-06-01 | Döviz API: **frankfurter.app** (key'siz, ECB, TRY) | Ücretsiz, kayıt gerektirmez |

## Kısıtlar ve özel durumlar
- Isar orijinal repo bakımı yavaşladı → community/v4 sürümü kullanılır; tüm erişim `SubscriptionRepository` arayüzü arkasından yapılır (gerekirse Drift/Hive'a geçilebilir)
- Döviz kuru çevrimdışı senaryoda son cache'lenen değerle çalışır
- `home_widget` ve takvim sync platform-spesifik native kod gerektirir (premium, en son)

## Açık sorular
- [x] ~~Döviz kuru API~~ → **frankfurter.app** (key'siz, ECB, TRY destekli)
- [x] ~~Logo stratejisi~~ → **bundled SVG marka logosu kataloğu** + online fallback (cache) + baş-harf son çare
- [ ] Takvim sync mekanizması (device_calendar plugin vs ICS export) — premium, en son
- [ ] Bundle'lanacak logo kataloğunun tam listesi (~40-50 servis; 12 TR servisi + popüler global servisler)
- [ ] Analytics: offline felsefeye uygun olarak v1'de izleme yok (teyit bekliyor)

## Figma Tasarım Referansı
Figma yok. UI/UX kararları feature başına ui-ux-agent tarafından `.docs/UIUX-NNN.md` olarak verilir; görsel kalite referansı subsday (https://subsday.appps.od.ua).

## Toplantı/iletişim geçmişi
| Tarih | Konu | Dosya |
|-------|------|-------|
| 2026-06-01 | İlk ürün brief'i (sohbet) | — (CONSTITUTION'a işlendi) |
